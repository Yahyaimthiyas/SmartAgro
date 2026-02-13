import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import '../../notifications/models/app_notification.dart';
import '../../notifications/repositories/notification_repository.dart';

class FarmerAlertsScreen extends StatefulWidget {
  const FarmerAlertsScreen({super.key});

  @override
  State<FarmerAlertsScreen> createState() => _FarmerAlertsScreenState();
}

class _FarmerAlertsScreenState extends State<FarmerAlertsScreen> {
  final _repository = NotificationRepository();
  String _filter = 'all'; // all, order, advisory, promotional

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          "Notifications",
          style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(
            child: StreamBuilder<List<AppNotification>>(
              stream: _repository.getUserNotifications(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final notifications = snapshot.data ?? [];
                final filtered = notifications.where((n) {
                  if (_filter == 'all') return true;
                  if (_filter == 'order') return n.type == NotificationType.orderUpdate;
                  if (_filter == 'advisory') return n.type == NotificationType.advisory;
                  if (_filter == 'offer') return n.type == NotificationType.promotional;
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _NotificationCard(
                      notification: filtered[index],
                      onTap: () => _handleNotificationTap(filtered[index]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: "All",
              selected: _filter == 'all',
              onTap: () => setState(() => _filter = 'all'),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: "Orders",
              selected: _filter == 'order',
              onTap: () => setState(() => _filter = 'order'),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: "Advisory",
              selected: _filter == 'advisory',
              onTap: () => setState(() => _filter = 'advisory'),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: "Offers",
              selected: _filter == 'offer',
              onTap: () => setState(() => _filter = 'offer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "No notifications found",
            style: GoogleFonts.poppins(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(AppNotification notification) {
    if (!notification.isRead) {
      _repository.markAsRead(notification.id);
    }
    // Handle navigation based on type or actionUrl
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isTamil = LocalizationService.localeNotifier.value.languageCode == 'ta';
    final title = isTamil ? notification.titleTa : notification.titleEn;
    final body = isTamil ? notification.bodyTa : notification.bodyEn;
    final time = DateFormat('MMM d, h:mm a').format(notification.sentAt);

    IconData icon;
    Color color;

    switch (notification.type) {
      case NotificationType.orderUpdate:
        icon = Icons.local_shipping_outlined;
        color = Colors.blue;
        break;
      case NotificationType.advisory:
        icon = Icons.eco_outlined;
        color = Colors.green;
        break;
      case NotificationType.promotional:
        icon = Icons.local_offer_outlined;
        color = Colors.orange;
        break;
      case NotificationType.payment:
        icon = Icons.warning_amber_rounded;
        color = Colors.red;
        break;
      default:
        icon = Icons.notifications_outlined;
        color = Colors.grey;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead ? Colors.transparent : color.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
             BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2)
             )
          ]
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.notoSansTamil(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        time,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: GoogleFonts.notoSansTamil(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                margin: const EdgeInsets.only(left: 8, top: 20),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

