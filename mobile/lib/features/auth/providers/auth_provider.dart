import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile/core/services/notification_service.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Set this to true to use OneSignal Custom OTP via SMS instead of Firebase Auth SMS.
// (Bypasses Firebase Auth SMS limits and SafetyNet errors on emulators).
const bool kUseOneSignalCustomOtp = false;

// Store phone numbers in E.164 format (with +91 prefix).
const Set<String> kDevOwnerPhones = {
  '+918637617441', // main owner test number
  '+919842237543', // updated owner number
  '+911122334455', // new owner number requested
  '+910000000000', // easy test number
  '+919999999999', // easy test number 2
  '+919999900000', // new farmer test bypass
};

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  String? _verificationId;
  String? _mockOneSignalOtp;
  bool _isMockDevFlow = false; // Flag to track if we are using the dev bypass
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

  // Step 1: Request OTP
  Future<void> verifyPhone(
    String phone,
    Function(String) codeSent,
    Function(String) onError,
  ) async {
    _lastPhone = phone;
    _isMockDevFlow = false;

    if (_auth == null) {
      onError('Firebase is not initialized. Please try again later.');
      return;
    }

    // NEW: Dev Bypass Logic for 1122334455 and other test numbers
    final fullPhone = '+91$phone';
    if (kDevOwnerPhones.contains(fullPhone)) {
      print("======== DEV OWNER BYPASS ========");
      print("Using mock flow for $fullPhone");
      _isMockDevFlow = true;
      _verificationId = "mock_dev_id";
      _mockOneSignalOtp = "123456"; // Fixed OTP for testing
      
      // Artificial delay to mimic network
      await Future.delayed(const Duration(milliseconds: 500));
      codeSent(_verificationId!);
      return;
    }

    try {
      if (kUseOneSignalCustomOtp) {
        // Generate 6-digit OTP
        final otp = (100000 + Random().nextInt(900000)).toString();
        _mockOneSignalOtp = otp;
        _verificationId = "onesignal_custom_id";

        // Try to trigger a OneSignal SMS (requires OneSignal Twilio SMS setup in dashboard)
        // Also log to console so developers can see it even if SMS isn't configured yet.
        print("======== ONE SIGNAL OTP SENDER ========");
        print("Sending OTP $otp to $phone via OneSignal");

        const String oneSignalAppId = "675d523a-e2d2-4662-8d59-17b41ac937e2";
        const String oneSignalRestApiKey =
            "os_v2_app_m5oveoxc2jdgfdkzc62bvsjx4l7gisz3xekuawmyzk2jebapagew67rwgvmgiwgqomfhpbdj6kiocko3aysw2swo3n5agdn7l3andwq";

        http
            .post(
              Uri.parse('https://onesignal.com/api/v1/notifications'),
              headers: {
                'Content-Type': 'application/json; charset=utf-8',
                'Authorization': 'Basic $oneSignalRestApiKey',
              },
              body: jsonEncode({
                'app_id': oneSignalAppId,
                'name': 'AgroShop OTP SMS',
                'sms_from':
                    '+11234567890', // Must match your OneSignal phone number
                'include_phone_numbers': ['+91$phone'],
                'contents': {'en': 'Your AgroShop login OTP is: $otp'},
              }),
            )
            .then((resp) => print("OneSignal SMS response: ${resp.body}"))
            .catchError((e) => print("OneSignal SMS request error: $e"));

        // Continue UI flow safely
        codeSent(_verificationId!);
        return;
      }

      await _auth!.verifyPhoneNumber(
        phoneNumber: '+91$phone',
        timeout: const Duration(seconds: 60), // Increased timeout to prevent premature 'internet error'
        verificationCompleted: (PhoneAuthCredential credential) async {
          print("Verification Completed Automatically");
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          print("Phone Auth Error [${e.code}]: ${e.message}");
          String userFriendlyError = e.message ?? 'Verification Failed';
          
          if (e.code == 'network-request-failed') {
            userFriendlyError = 'Internet error or Timeout. Please check connection and ensure Phone Date/Time is Automatic.';
          } else if (e.code == 'too-many-requests') {
            userFriendlyError = 'Daily SMS limit reached. Please use a Test Number or try tomorrow.';
          } else if (e.code == 'invalid-app-credential') {
            userFriendlyError = 'App verification failed (SHA-1 conflict). Please use Test Number for now.';
          }
          
          onError("$userFriendlyError (${e.code})");
        },
        codeSent: (String verificationId, int? resendToken) {
          print("OTP Code Sent to $phone");
          _verificationId = verificationId;
          codeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          print("Auto-retrieval timeout for ID: $verificationId");
        },
      );
    } catch (e) {
      print("Auth Error: $e");
      onError(e.toString());
    }
  }

  /// Step 2: Verify OTP
  /// Now throws exceptions for specific failures to provide better feedback to the UI.
  Future<bool> verifyOtp(String otp) async {
    try {
      if (_auth == null || _verificationId == null) {
        throw 'Authentication session expired. Please request a new OTP.';
      }

      // Handle Dev Bypass
      if (_isMockDevFlow && _verificationId == "mock_dev_id") {
        if (otp == _mockOneSignalOtp) {
          final userCredential = await _auth!.signInAnonymously();
          if (userCredential.user != null) {
            final role = await _ensureUserDocument(userCredential.user!);
            await _saveLocalAuth(userCredential.user!.uid, role);
            return true;
          }
           throw 'Identification failed after mock login.';
        }
        return false;
      }

      if (kUseOneSignalCustomOtp && _verificationId == "onesignal_custom_id") {
        if (otp == _mockOneSignalOtp || otp == "123456") {
          try {
            final userCredential = await _auth!.signInAnonymously();
            if (userCredential.user != null) {
              final role = await _ensureUserDocument(userCredential.user!);
              await _saveLocalAuth(userCredential.user!.uid, role);
              return true;
            }
            throw 'Identity creation failed.';
          } on FirebaseAuthException catch (e) {
            if (e.code == 'admin-restricted-operation') {
              throw 'Anonymous Login is DISABLED in Firebase Console. Please enable it under Authentication -> Sign-in method.';
            }
            throw 'Firebase Error: ${e.message}';
          }
        }
        print("OTP DISCREPANCY: Entered $otp, expected 123456 or $_mockOneSignalOtp");
        return false;
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      return await _signInWithCredential(credential);
    } catch (e) {
      print("OTP Verification Error: $e");
      rethrow; // Re-throw so the UI can catch and show the specific error
    }
  }

  Future<void> resendOtp(
    Function(String) codeSent,
    Function(String) onError,
  ) async {
    if (_lastPhone == null) {
      onError(
        'Phone number not available for resend. Please go back and enter again.',
      );
      return;
    }
    await verifyPhone(_lastPhone!, codeSent, onError);
  }

  Future<String> _ensureUserDocument(User user) async {
    try {
      final phone =
          user.phoneNumber ?? (_lastPhone != null ? '+91$_lastPhone' : null);

      // Prioritize owner test number check if custom OTP flow is active or testing
      if (phone != null && kDevOwnerPhones.contains(phone)) {
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);
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

      if (phone == null) {
        return snapshot.data()?['role']?.toString() ?? 'farmer';
      }

      // ALWAYS search for potential merges/duplicates by phone number
      final duplicateUsers = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone)
          .get();

      String role = snapshot.data()?['role']?.toString() ?? 'farmer';
      Map<String, dynamic> userData = snapshot.exists ? snapshot.data()! : {
        'phone': phone,
        'role': 'farmer',
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (duplicateUsers.docs.isNotEmpty) {
        for (var doc in duplicateUsers.docs) {
          if (doc.id == user.uid) continue;
          
          final data = doc.data();
          // Merge data from duplicates into current record
          bool thisDocHasBetterData = false;
          if (data['name'] != null && userData['name'] == null) {
            thisDocHasBetterData = true;
          } else if (data['isProfileBasicComplete'] == true && userData['isProfileBasicComplete'] != true) {
            thisDocHasBetterData = true;
          } else if (data['isPreRegistered'] == true) {
            thisDocHasBetterData = true;
          }
          
          if (thisDocHasBetterData || data['role'] == 'owner') {
             userData.addAll(data);
             role = data['role']?.toString() ?? role;
          }

          // [FIX] Run migration in the background to avoid blocking login UI.
          // The data will eventually follow the user.
          _migrateFarmerData(doc.id, user.uid).catchError((e) => print("Background migration failed: $e"));
          
          // Delete old doc only after scheduling migration
          doc.reference.delete().catchError((e) => print("Failed to delete duplicate doc: $e"));
        }
      } 
      
      // If no role/name found in duplicates, check approved_owners collection
      if (role != 'owner') {
        final approvedDoc = await FirebaseFirestore.instance
            .collection('approved_owners')
            .doc(phone)
            .get();
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

  /// Migrates all orders, credit ledger entries, and feedbacks from an old UID to a new UID.
  /// This ensures that even if a farmer's UID changes (standard in anonymous dev/mock flows),
  /// their historical data remains intact and follows them to their new identity.
  Future<void> _migrateFarmerData(String oldUid, String newUid) async {
    print("MIGRATING DATA FROM $oldUid TO $newUid");
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      // 1. Migrate Orders
      final orders = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: oldUid)
          .get();
      for (var doc in orders.docs) {
        batch.update(doc.reference, {'userId': newUid});
      }

      // 2. Migrate Credit Ledger
      final ledger = await FirebaseFirestore.instance
          .collection('creditLedger')
          .where('userId', isEqualTo: oldUid)
          .get();
      for (var doc in ledger.docs) {
        batch.update(doc.reference, {'userId': newUid});
      }

      // 3. Migrate Feedbacks
      final feedbacks = await FirebaseFirestore.instance
          .collection('feedbacks')
          .where('userId', isEqualTo: oldUid)
          .get();
      for (var doc in feedbacks.docs) {
        batch.update(doc.reference, {'userId': newUid});
      }

      // 4. Migrate Aadhar Limits
      final aadhar = await FirebaseFirestore.instance
          .collection('aadhar_limits')
          .where('userId', isEqualTo: oldUid)
          .get();
      for (var doc in aadhar.docs) {
        batch.update(doc.reference, {'userId': newUid});
      }

      // 5. Migrate Subcollections (Cart, Notifications, Advisory Reads)
      // NOTE: We wrap these in individual try-catches because security rules 
      // might prevent reading private subcollections of a different UID (even if same phone).
      final subcollections = ['cart', 'notifications', 'advisory_reads'];
      for (final sub in subcollections) {
        try {
          final subDocs = await FirebaseFirestore.instance
              .collection('users')
              .doc(oldUid)
              .collection(sub)
              .get();
          for (final doc in subDocs.docs) {
            final newDocRef = FirebaseFirestore.instance
                .collection('users')
                .doc(newUid)
                .collection(sub)
                .doc(doc.id);
            batch.set(newDocRef, doc.data());
          }
        } catch (e) {
          print("Skipping migration for private subcollection $sub: $e");
        }
      }

      await batch.commit();
      print("MIGRATION COMPLETE for $newUid");
    } catch (e) {
      print("MIGRATION ERROR: $e");
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
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
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
