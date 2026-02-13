import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  orderUpdate,
  advisory,
  promotional,
  system,
  payment,
  unknown
}

enum NotificationPriority {
  critical,
  important,
  normal,
  low
}

class AppNotification {
  final String id;
  final NotificationType type;
  final NotificationPriority priority;
  final String titleTa;
  final String titleEn;
  final String bodyTa;
  final String bodyEn;
  final Map<String, dynamic> data;
  final DateTime sentAt;
  final bool isRead;
  final String? actionUrl;

  AppNotification({
    required this.id,
    required this.type,
    required this.priority,
    required this.titleTa,
    required this.titleEn,
    required this.bodyTa,
    required this.bodyEn,
    required this.data,
    required this.sentAt,
    this.isRead = false,
    this.actionUrl,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return AppNotification(
      id: doc.id,
      type: _parseType(data['type']),
      priority: _parsePriority(data['priority']),
      titleTa: data['title_ta'] ?? '',
      titleEn: data['title_en'] ?? '',
      bodyTa: data['body_ta'] ?? '',
      bodyEn: data['body_en'] ?? '',
      data: data['data'] ?? {},
      sentAt: (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false, // Ideally this is a subcollection or separate status
      actionUrl: data['actionUrl'],
    );
  }

  static NotificationType _parseType(String? type) {
    switch (type) {
      case 'ORDER_UPDATE': return NotificationType.orderUpdate;
      case 'ADVISORY': return NotificationType.advisory;
      case 'PROMOTIONAL': return NotificationType.promotional;
      case 'SYSTEM': return NotificationType.system;
      case 'PAYMENT': return NotificationType.payment;
      default: return NotificationType.unknown;
    }
  }

  static NotificationPriority _parsePriority(String? priority) {
    switch (priority) {
      case 'critical': return NotificationPriority.critical;
      case 'important': return NotificationPriority.important;
      case 'normal': return NotificationPriority.normal;
      default: return NotificationPriority.low;
    }
  }
}
