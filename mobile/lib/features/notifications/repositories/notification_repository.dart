import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_notification.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
}
