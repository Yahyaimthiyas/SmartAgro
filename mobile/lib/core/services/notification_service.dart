import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../main.dart';
import 'localization_service.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Replace with your actual OneSignal App ID
  static const String _oneSignalAppId = "675d523a-e2d2-4662-8d59-17b41ac937e2";

  // Set to false to pause OneSignal (saves API limits)
  static const bool useOneSignal = true;

  static Future<void> init() async {
    if (!useOneSignal) {
      print('DEBUG: OneSignal is currently PAUSED to save credits.');
      // Still start Firestore listener for in-app banners
      _startFirestoreListener();
      return;
    }

    // 1. OneSignal Initialization
    print('DEBUG: Initializing OneSignal with ID: $_oneSignalAppId');
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(_oneSignalAppId);

    final granted = await OneSignal.Notifications.requestPermission(true);
    print('DEBUG: OneSignal Notification Permission: $granted');

    // 2. Auth State Handling & Token Refresh
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        print('DEBUG: Logging into OneSignal with UID: ${user.uid}');
        OneSignal.login(user.uid);

        // Let's verify our registration
        final onesignalId = OneSignal.User.pushSubscription.id;
        final externalId = user.uid;
        print('DEBUG: OneSignal Device ID: $onesignalId');
        print('DEBUG: OneSignal External ID (Target): $externalId');

        await _updateUserFcmToken(user.uid);
        _startFirestoreListener();
      } else {
        print('DEBUG: OneSignal Logout');
        OneSignal.logout();
        _notificationSub?.cancel();
        _notificationSub = null;
      }
    });

    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      await _saveToken(currentUser.uid, token);
    });

    // 3. Foreground FCM Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        print('FCM Notification: ${notification.title}');
      }
    });

    // 4. Live Firestore Notification Listener
    _startFirestoreListener();
  }

  static StreamSubscription<QuerySnapshot>? _notificationSub;
  static DateTime? _sessionStartTime;

  static void _startFirestoreListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _sessionStartTime = DateTime.now();
    _notificationSub?.cancel();

    print('DEBUG: Notification Listener started at $_sessionStartTime');

    _notificationSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            // Sort: Server timestamps first, then descending
            final docs = snapshot.docs.toList()
              ..sort((a, b) {
                final t1 = (a.data() as Map)['sentAt'] as Timestamp?;
                final t2 = (b.data() as Map)['sentAt'] as Timestamp?;
                if (t1 == null) return -1; // Newest incoming
                if (t2 == null) return 1;
                return t2.compareTo(t1);
              });

            final data = docs.first.data() as Map<String, dynamic>;
            final sentAt = data['sentAt'] as Timestamp?;

            // Only show if it matches this session (prevents old unread spam at startup)
            // If sentAt is null, it's a brand new local-first event, show it.
            if (sentAt == null ||
                sentAt.toDate().isAfter(
                  _sessionStartTime!.subtract(const Duration(seconds: 10)),
                )) {
              _showLocalAlert(data);
            }
          }
        }, onError: (e) => print('NOTIFICATION_LISTENER_ERROR: $e'));
  }

  static final AudioPlayer _audioPlayer = AudioPlayer();

  static void _showLocalAlert(Map<String, dynamic> data) async {
    final type = data['type'] as String?;

    // High-priority Alert (Vibrate 4s + Sound)
    if (type == 'dosageReminder') {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 4000);
      }
      try {
        await _audioPlayer.play(AssetSource('sounds/alert.mp3'));
      } catch (e) {
        print('Audio play error: $e');
      }
    }

    final isTa = LocalizationService.isTamil;
    final title = isTa ? data['title_ta'] : data['title_en'];
    final body = isTa ? data['body_ta'] : data['body_en'];

    MyApp.scaffoldMessengerKey.currentState?.removeCurrentSnackBar();
    MyApp.scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title ?? 'Notification',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(body ?? '', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: Colors.green.shade700,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }
}
