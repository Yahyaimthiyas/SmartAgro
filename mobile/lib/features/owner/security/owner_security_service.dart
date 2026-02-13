import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class OwnerSecurityService {
  static const _pinKey = 'owner_pin';
  static const _lastAuthKey = 'owner_last_auth';
  static const _sessionHours = 8;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> isOwnerApproved() async {
    final user = FirebaseAuth.instance.currentUser;
    final phone = user?.phoneNumber;
    if (phone == null) {
      return false;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('approved_owners')
          .doc(phone)
          .get();
      if (!doc.exists) {
        return false;
      }
      final data = doc.data();
      if (data == null) {
        return false;
      }
      final status = data['status'];
      if (status is String && status == 'active') {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasPinSetup() async {
    final stored = await _storage.read(key: _pinKey);
    return stored != null && stored.isNotEmpty;
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> savePin(String pin) async {
    final hash = _hashPin(pin);
    await _storage.write(key: _pinKey, value: hash);
    await markAuthenticatedNow();
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _pinKey);
    if (stored == null || stored.isEmpty) {
      return false;
    }
    final hash = _hashPin(pin);
    if (hash == stored) {
      await markAuthenticatedNow();
      return true;
    }
    return false;
  }

  Future<bool> isSessionValid() async {
    final stored = await _storage.read(key: _lastAuthKey);
    if (stored == null || stored.isEmpty) {
      return false;
    }
    final millis = int.tryParse(stored);
    if (millis == null) {
      return false;
    }
    final last = DateTime.fromMillisecondsSinceEpoch(millis);
    final diff = DateTime.now().difference(last);
    return diff.inHours < _sessionHours;
  }

  Future<void> markAuthenticatedNow() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _storage.write(key: _lastAuthKey, value: now.toString());
  }

  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics(String reason) async {
    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (didAuthenticate) {
        await markAuthenticatedNow();
      }
      return didAuthenticate;
    } catch (_) {
      return false;
    }
  }
}
