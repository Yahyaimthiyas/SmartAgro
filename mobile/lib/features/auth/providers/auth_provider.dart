import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile/core/services/notification_service.dart';

// Dev-only helper: mark specific phone numbers with roles.
// For production, you can set this to false or remove the mapping.
const bool kUseDevTestNumberRoles = true;

// Store phone numbers in E.164 format (with +91 prefix).
const Set<String> kDevOwnerPhones = {
  '+918637617441', // main owner test number
  '+919842237543', // updated owner number
};

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;
  
  String? _verificationId;
  FirebaseAuth? _auth;
  String? _lastPhone;

  AuthProvider() {
    _initAuth();
  }

  void _initAuth() {
    try {
      _auth = FirebaseAuth.instance;
    } catch (e) {
      print("FirebaseAuth not available (likely missing google-services.json)");
    }
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    
    notifyListeners();
  }

  // Step 1: Request OTP (real Firebase flow only)
  Future<void> verifyPhone(
    String phone,
    Function(String) codeSent,
    Function(String) onError,
  ) async {
    _lastPhone = phone;
    if (_auth == null) {
      onError('Firebase is not initialized. Please try again later.');
      return;
    }

    try {
      // [DEV BYPASS] If it's a dev number, bypass real Firebase SMS to avoid billing/quota errors
      if (kUseDevTestNumberRoles && kDevOwnerPhones.contains('+91$phone')) {
        _verificationId = "dev_bypass_id";
        codeSent(_verificationId!);
        return;
      }

      await _auth!.verifyPhoneNumber(
        phoneNumber: '+91$phone',
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-sign in (Android only usually)
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'Verification Failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          codeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      print("Auth Error: $e");
      onError(e.toString());
    }
  }

  // Step 2: Verify OTP (real Firebase flow only)
  Future<bool> verifyOtp(String otp) async {
    try {
      if (_auth == null || _verificationId == null) {
        return false;
      }
      
      // [DEV BYPASS] check for mock OTP
      if (_verificationId == "dev_bypass_id" && otp == "123456") {
         if (_auth != null) {
           final userCredential = await _auth!.signInAnonymously();
           if (userCredential.user != null) {
              final role = await _ensureUserDocument(userCredential.user!);
              await _saveLocalAuth(userCredential.user!.uid, role);
              return true;
           }
         }
         return false;
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      
      return await _signInWithCredential(credential);
    } catch (e) {
      print("OTP Verification Error: $e");
      return false;
    }
  }

  Future<void> resendOtp(
    Function(String) codeSent,
    Function(String) onError,
  ) async {
    if (_lastPhone == null) {
      onError('Phone number not available for resend. Please go back and enter again.');
      return;
    }
    await verifyPhone(_lastPhone!, codeSent, onError);
  }

  Future<String> _ensureUserDocument(User user) async {
    try {
      final phone = user.phoneNumber ?? (_lastPhone != null ? '+91$_lastPhone' : null);
      
      // [DEV BYPASS] Prioritize dev number check
      if (kUseDevTestNumberRoles && phone != null && kDevOwnerPhones.contains(phone)) {
         final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
         await docRef.set({
           'phone': phone,
           'role': 'owner',
           'shopId': 'shop_123',
           'updatedAt': FieldValue.serverTimestamp(),
         }, SetOptions(merge: true));
         return 'owner';
      }

      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final snapshot = await docRef.get();
      
      if (snapshot.exists) {
        final data = snapshot.data();
        return data?['role']?.toString() ?? 'farmer';
      }

      if (phone == null) return 'farmer';
      final preRegQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      String role = 'farmer';
      Map<String, dynamic> userData = {
        'phone': phone,
        'role': 'farmer',
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (preRegQuery.docs.isNotEmpty) {
        final preRegDoc = preRegQuery.docs.first;
        // If the document is already our current UID, we are handled above.
        // If it's a different document (e.g. created by owner with random ID), we adopt its fields.
        if (preRegDoc.id != user.uid) {
           final data = preRegDoc.data();
           role = data['role']?.toString() ?? 'farmer';
           userData.addAll(data);
           userData['role'] = role; // Ensure role is preserved
           // Delete the pre-registered document to avoid duplicates
           await preRegDoc.reference.delete();
        } else {
           role = preRegDoc.data()['role']?.toString() ?? 'farmer';
           return role;
        }
      } else {
        // 2. Check if this phone number is in the blessed list for owners
        final approvedDoc = await FirebaseFirestore.instance.collection('approved_owners').doc(phone).get();
        if (approvedDoc.exists && approvedDoc.data()?['status'] == 'active') {
          role = 'owner';
          userData['role'] = 'owner';
          userData['shopId'] = approvedDoc.data()?['shopId'] ?? 'default_shop';
        }
      }

      // 3. Create/Set user document with final data
      await docRef.set(userData, SetOptions(merge: true));

      return role;
    } catch (e) {
      print('Error ensuring user document: $e');
      return 'farmer'; // Default fall back
    }
  }

  Future<bool> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      if (_auth == null) return false;
      final userCredential = await _auth!.signInWithCredential(credential);
      if (userCredential.user != null) {
        final role = await _ensureUserDocument(userCredential.user!);
        await _saveLocalAuth(userCredential.user!.uid, role);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }



  Future<void> _saveLocalAuth(String uid, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('uid', uid);
    await prefs.setString('role', role); // Cache the role
    await NotificationService.refreshFcmTokenForUser(uid);

    _isLoggedIn = true;
    notifyListeners();
  }

  Future<String?> getUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Try local cache first
      final cachedRole = prefs.getString('role');
      if (cachedRole != null && cachedRole.isNotEmpty) {
        return cachedRole;
      }

      final uid = prefs.getString('uid');
      if (uid == null) return null;

      // Fallback to Firestore if not cached
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      final role = data['role'];
      
      if (role is String) {
        // Cache it for next time
        await prefs.setString('role', role);
        return role;
      }
      return null;
    } catch (e) {
      print('Error fetching user role: $e');
      return null;
    }
  }

  Future<void> login(String phone) async {
    // Legacy method support if needed, but verifyPhone is preferred
    await _saveLocalAuth("mock_user", "farmer");
  }

  Future<void> logout() async {
    if (_auth != null) {
      await _auth!.signOut();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _isLoggedIn = false;
    notifyListeners();
  }
}

