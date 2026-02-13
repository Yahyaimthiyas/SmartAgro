import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/services/localization_service.dart';
import '../../notifications/models/app_notification.dart';
import '../../notifications/repositories/notification_repository.dart';
import '../../farmer/orders/farmer_orders_screen.dart';
import '../../farmer/advisory/farmer_advisory_messages_screen.dart';

class FarmerNotificationScreen extends StatelessWidget {
  const FarmerNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = NotificationRepository();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          LocalizationService.tr('title_notifications'),
          style: GoogleFonts.notoSansTamil(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: repo.getUserNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                         color: Colors.grey.shade100,
                         shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey.shade400),
                   ),
                   const SizedBox(height: 16),
                   Text(
                      LocalizationService.tr('msg_no_notifications'),
                      style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textSecondary),
                   ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationCard(
                notification: notification,
                onTap: () {
                   repo.markAsRead(notification.id);
                   
                   // Navigation Logic
                   if (notification.type == NotificationType.orderUpdate && notification.data.containsKey('orderId')) {
                      // Navigate to Order Details (requires implemented screen or list)
                      // For now, go to Order List which is safe
                      Navigator.of(context).push(
                         MaterialPageRoute(builder: (_) => const FarmerOrdersScreen())
                      );
                   } else if (notification.type == NotificationType.advisory) {
                      Navigator.of(context).push(
                         MaterialPageRoute(builder: (_) => const FarmerAdvisoryMessagesScreen())
                      );
                   }
                },
                onDismiss: () {
                   repo.deleteNotification(notification.id);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isTa = LocalizationService.isTamil;
    final title = isTa ? notification.titleTa : notification.titleEn;
    final body = isTa ? notification.bodyTa : notification.bodyEn;
    
    // Theme based on priority/type
    Color iconColor;
    IconData iconData;
    Color bgColor;

    switch (notification.type) {
      case NotificationType.orderUpdate:
        iconColor = Colors.blue;
        iconData = Icons.local_shipping_outlined;
        bgColor = Colors.blue.shade50;
        break;
      case NotificationType.advisory:
        iconColor = Colors.green;
        iconData = Icons.spa_outlined;
        bgColor = Colors.green.shade50;
        break;
      case NotificationType.payment:
        iconColor = Colors.orange;
        iconData = Icons.currency_rupee;
        bgColor = Colors.orange.shade50;
        break;
      default:
        iconColor = Colors.grey;
        iconData = Icons.notifications_none_rounded;
        bgColor = Colors.grey.shade100;
    }

    if (notification.priority == NotificationPriority.critical) {
       bgColor = Colors.red.shade50;
       iconColor = Colors.red;
    }

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
         alignment: Alignment.centerRight,
         padding: const EdgeInsets.only(right: 20),
         decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(16),
         ),
         child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      onDismissed: (_) => onDismiss(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.white : const Color(0xFFF0F7FF), // Highlight unread
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
               color: notification.isRead ? Colors.transparent : AppColors.primary.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                     color: bgColor,
                     shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: iconColor, size: 24),
               ),
               const SizedBox(width: 16),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                               title,
                               style: GoogleFonts.notoSansTamil(
                                  fontSize: 16,
                                  fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold,
                                  color: AppColors.textPrimary,
                               ),
                            ),
                          ),
                          Text(
                             _formatDate(notification.sentAt),
                             style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                         body,
                         style: GoogleFonts.notoSansTamil(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.4,
                         ),
                      ),
                   ],
                 ),
               ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 60) {
       return "${diff.inMinutes}m ago";
    } else if (diff.inHours < 24) {
       return "${diff.inHours}h ago";
    } else {
       return DateFormat('MMM d').format(date);
    }
  }
}
