import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    // 1. Request Permissions
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // 2. Token Handling
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _updateUserFcmToken(user.uid);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      await _saveToken(currentUser.uid, token);
    });

    // 3. Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Show in-app overlay or snackbar
      final notification = message.notification;
      if (notification != null) {
        print('Foreground Notification: ${notification.title}');
        // TODO: Use a global key or proper state management to show UI
      }
    });
  }

  // --- Topic Management ---
  
  static Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  static Future<void> refreshFcmTokenForUser(String uid) async {
    await _updateUserFcmToken(uid);
  }

  static Future<void> _updateUserFcmToken(String uid) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      await _saveToken(uid, token);
    } catch (_) {}
  }

  static Future<void> _saveToken(String uid, String token) async {
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      await userRef.set(
        {
          'fcmTokens': FieldValue.arrayUnion([token]),
        },
        SetOptions(merge: true),
      );
    } catch (
      _) {}
  }
}
