import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/app_notification.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Replace these with your actual OneSignal credentials
  static const String _oneSignalAppId = "xxxxxxxxxxxxx";
  static const String _oneSignalRestApiKey =
      "xxxxxxxxxxxxxxxxxxxxxxxxx";

  // Set to false to pause OneSignal (saves API limits)
  static const bool useOneSignal = true;

  Stream<List<AppNotification>> getUserNotifications() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    // Strategy:
    // 1. Fetch personal notifications (target.type = 'individual' && target.id = uid)
    // 2. Fetch topic notifications (target.type = 'topic' && user subscribed topics)
    // For MVP, we'll assume the backend fans out notifications to a 'users/{uid}/notifications' subcollection
    // OR we query a root 'notifications' collection where 'targetUsers' array-contains uid.

    // Approach A: Root collection query (Better for shared alerts like Weather)
    // Constraint: Firestore limitations on OR queries.

    // Approach B: Subcollection 'users/{uid}/notifications' (Best for individual read status)
    // Let's go with Approach B as it handles "READ" status easiest.

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('sentAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AppNotification.fromFirestore(doc))
              .toList();
        });
  }

  Future<void> markAsRead(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> deleteNotification(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  Future<void> sendNotification({
    required String recipientUid,
    required String titleTa,
    required String titleEn,
    required String bodyTa,
    required String bodyEn,
    NotificationType type = NotificationType.system,
    NotificationPriority priority = NotificationPriority.normal,
    Map<String, dynamic>? data,
  }) async {
    await _firestore
        .collection('users')
        .doc(recipientUid)
        .collection('notifications')
        .add({
          'title_ta': titleTa,
          'title_en': titleEn,
          'body_ta': bodyTa,
          'body_en': bodyEn,
          'type': type
              .toString()
              .split('.')
              .last
              .toUpperCase(), // e.g. ORDER_UPDATE
          'priority': priority.toString().split('.').last,
          'sentAt': FieldValue.serverTimestamp(),
          'isRead': false,
          'data': data ?? {},
        });

    // --- Trigger OneSignal Push ---
    await _sendOneSignalNotification(
      recipientUid: recipientUid,
      title:
          titleEn, // Use English for background if needed, or handle localized content
      body: bodyEn,
      data: data,
    );
  }

  Future<void> _sendOneSignalNotification({
    required String recipientUid,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (!useOneSignal) return; // Skip push if paused

    try {
      final response = await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Basic $_oneSignalRestApiKey',
        },
        body: jsonEncode({
          'app_id': _oneSignalAppId,
          'include_aliases': {
            'external_id': [recipientUid],
          },
          'target_channel': 'push',
          'headings': {'en': title},
          'contents': {'en': body},
          'data': data ?? {},
          'android_sound': 'notification',
        }),
      );

      if (response.statusCode != 200) {
        print('OneSignal Error: ${response.body}');
      }
    } catch (e) {
      print('Failed to send OneSignal push: $e');
    }
  }

  Future<void> notifyOwner({
    required String titleTa,
    required String titleEn,
    required String bodyTa,
    required String bodyEn,
    Map<String, dynamic>? data,
  }) async {
    // Find all owners
    final ownerSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'owner')
        .get();

    for (var doc in ownerSnapshot.docs) {
      await sendNotification(
        recipientUid: doc.id,
        titleTa: titleTa,
        titleEn: titleEn,
        bodyTa: bodyTa,
        bodyEn: bodyEn,
        data: data,
      );
    }
  }
}
