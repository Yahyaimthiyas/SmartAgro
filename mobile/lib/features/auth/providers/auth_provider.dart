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
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final snapshot = await docRef.get();
      
      if (snapshot.exists) {
        final data = snapshot.data();
        return data?['role']?.toString() ?? 'farmer';
      }

      final phone = user.phoneNumber ?? (_lastPhone != null ? '+91$_lastPhone' : null);
      if (phone == null) return 'farmer';

      // 1. Check if this phone number is in the blessed list
      final approvedDoc = await FirebaseFirestore.instance.collection('approved_owners').doc(phone).get();
      final isApproved = approvedDoc.exists && approvedDoc.data()?['status'] == 'active';

      // 2. Assign role based on approval
      final role = isApproved ? 'owner' : 'farmer';

      // 3. Create user document
      await docRef.set({
        'phone': phone,
        'role': role,
        'shopId': isApproved ? (approvedDoc.data()?['shopId'] ?? 'default_shop') : null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. (Dev Helper) If it's the specific dev number and it wasn't there, add it for next time.
      if (kUseDevTestNumberRoles && kDevOwnerPhones.contains(phone) && !isApproved) {
         // Auto-approve the dev number for testing ease
         await FirebaseFirestore.instance.collection('approved_owners').doc(phone).set({
           'status': 'active',
           'shopId': 'shop_123',
           'permissions': ['full_access'],
           'createdAt': FieldValue.serverTimestamp(),
         });
         // Update user to owner immediately
         await docRef.update({'role': 'owner', 'shopId': 'shop_123'});
         return 'owner';
      }

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

