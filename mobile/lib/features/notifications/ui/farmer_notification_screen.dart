import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/services/localization_service.dart';
import '../../notifications/models/app_notification.dart';
import '../../notifications/repositories/notification_repository.dart';
import '../../farmer/orders/farmer_orders_screen.dart';
import '../../farmer/orders/farmer_order_tracking_screen.dart';
import '../../farmer/advisory/farmer_ai_plant_doctor_screen.dart';
import '../../owner/orders/owner_order_details_screen.dart';
import '../../owner/orders/owner_orders_screen.dart';
import '../../auth/providers/auth_provider.dart';

class FarmerNotificationScreen extends StatefulWidget {
  const FarmerNotificationScreen({super.key});

  @override
  State<FarmerNotificationScreen> createState() => _FarmerNotificationScreenState();
}

class _FarmerNotificationScreenState extends State<FarmerNotificationScreen> {
  final _repo = NotificationRepository();
  String _selectedFilter = 'all'; // all, orders, offers, system

  @override
  Widget build(BuildContext context) {
    final isTa = LocalizationService.isTamil;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(isTa),
          SliverToBoxAdapter(child: _buildFilterBar(isTa)),
          StreamBuilder<List<AppNotification>>(
            stream: _repo.getUserNotifications(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              }

              final allNotifications = snapshot.data ?? [];
              List<AppNotification> filteredList = _applyFilter(allNotifications);

              if (filteredList.isEmpty) {
                return SliverFillRemaining(child: _buildEmptyState(isTa));
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                sliver: SliverList(
                  delegate: SliverChildSeparatedBuilderDelegate(
                    (context, index) {
                      final notification = filteredList[index];
                      return FadeInUp(
                        duration: Duration(milliseconds: 300 + (index * 50)),
                        child: _NotificationTile(
                          notification: notification,
                          onTap: () => _handleNotificationTap(notification),
                          onDismiss: () => _repo.deleteNotification(notification.id),
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemCount: filteredList.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isTa) {
    return SliverAppBar(
      backgroundColor: Colors.white,
      expandedHeight: 120,
      pinned: true,
      elevation: 0,
      stretch: true,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1C1E), size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        TextButton(
          onPressed: () => _markAllAsRead(),
          child: Text(
            isTa ? 'அனைத்தையும் படிக்கவும்' : 'Mark all read',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
        title: Text(
          isTa ? 'அறிவிப்புகள்' : 'Notifications',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1C1E),
            fontSize: 20,
          ),
        ),
        background: Container(color: Colors.white),
      ),
    );
  }

  Widget _buildFilterBar(bool isTa) {
    final filters = [
      {'id': 'all', 'label': isTa ? 'அனைத்தும்' : 'All', 'icon': Icons.tune_rounded},
      {'id': 'orders', 'label': isTa ? 'ஆர்டர்கள்' : 'Orders', 'icon': Icons.shopping_bag_outlined},
      {'id': 'offers', 'label': isTa ? 'சலுகைகள்' : 'Offers', 'icon': Icons.local_offer_outlined},
      {'id': 'system', 'label': isTa ? 'அமைப்பு' : 'System', 'icon': Icons.settings_outlined},
    ];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final f = filters[index];
          final isSelected = _selectedFilter == f['id'];
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: FilterChip(
              label: Text(f['label'] as String),
              avatar: Icon(f['icon'] as IconData, size: 16, color: isSelected ? Colors.white : Colors.grey.shade600),
              selected: isSelected,
              onSelected: (val) => setState(() => _selectedFilter = f['id'] as String),
              backgroundColor: Colors.white,
              selectedColor: AppColors.primary,
              checkmarkColor: Colors.white,
              showCheckmark: false,
              labelStyle: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.shade200),
              ),
            ),
          );
        },
      ),
    );
  }

  List<AppNotification> _applyFilter(List<AppNotification> list) {
    if (_selectedFilter == 'all') return list;
    if (_selectedFilter == 'orders') {
      return list.where((n) => n.type == NotificationType.orderUpdate || n.type == NotificationType.payment).toList();
    }
    if (_selectedFilter == 'offers') {
      return list.where((n) => n.type == NotificationType.promotional).toList();
    }
    if (_selectedFilter == 'system') {
      return list.where((n) => n.type == NotificationType.system).toList();
    }
    return list;
  }

  Future<void> _handleNotificationTap(AppNotification notification) async {
    _repo.markAsRead(notification.id);
    final role = await context.read<AuthProvider>().getUserRole();
    final isOwner = role == 'owner';

    if (notification.type == NotificationType.orderUpdate || notification.type == NotificationType.payment) {
      String? orderId = notification.data['orderId'];
      if (orderId == null) {
        final body = LocalizationService.isTamil ? notification.bodyTa : notification.bodyEn;
        final match = RegExp(r'\(#([a-zA-Z0-9]+)\)').firstMatch(body);
        if (match != null) orderId = match.group(1);
      }

      if (orderId != null && orderId.isNotEmpty) {
        if (isOwner) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => OwnerOrderDetailsScreen(orderId: orderId!)));
        } else {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => FarmerOrderTrackingScreen(orderId: orderId!)));
        }
      } else {
        if (isOwner) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OwnerOrdersScreen()));
        } else {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FarmerOrdersScreen()));
        }
      }
    } else if (notification.type == NotificationType.advisory) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FarmerAiPlantDoctorScreen()));
    }
  }

  void _markAllAsRead() {
    _repo.getUserNotifications().first.then((list) {
      for (var n in list) {
        if (!n.isRead) _repo.markAsRead(n.id);
      }
    });
  }

  Widget _buildEmptyState(bool isTa) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 30)]),
            child: Icon(Icons.notifications_none_rounded, size: 72, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 24),
          Text(isTa ? 'அறிவிப்புகள் எதுவும் இல்லை' : 'Everything is captured', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1A1C1E))),
          const SizedBox(height: 8),
          Text(isTa ? 'உங்களுக்கு இப்போது அறிவிப்புகள் எதுவும் இல்லை' : 'You have no new notifications right now.', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationTile({required this.notification, required this.onTap, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final isTa = LocalizationService.isTamil;
    String title = isTa ? notification.titleTa : notification.titleEn;
    String rawBody = isTa ? notification.bodyTa : notification.bodyEn;
    
    // Aggressive ID removal for clean display
    String cleanBody = rawBody.replaceAll(RegExp(r'\s*\(#[a-zA-Z0-9]+\)\s*'), ' ').trim();
    String cleanTitle = title.replaceAll(RegExp(r'\s*\(#[a-zA-Z0-9]+\)\s*'), ' ').trim();

    final now = DateTime.now();
    final diff = now.difference(notification.sentAt);
    String timeStr = _formatTime(diff);

    Color iconColor;
    IconData icon;
    Color iconBg;

    switch (notification.type) {
      case NotificationType.orderUpdate:
        iconColor = const Color(0xFF10B981);
        icon = Icons.local_shipping_rounded;
        iconBg = const Color(0xFFE8F5E9);
        break;
      case NotificationType.promotional:
        iconColor = const Color(0xFFFACC15);
        icon = Icons.star_rounded;
        iconBg = const Color(0xFFFEF9C3);
        break;
      case NotificationType.system:
        iconColor = const Color(0xFF6366F1);
        icon = Icons.info_rounded;
        iconBg = const Color(0xFFEEF2FF);
        break;
      case NotificationType.payment:
        iconColor = const Color(0xFFF97316);
        icon = Icons.payments_rounded;
        iconBg = const Color(0xFFFFF7ED);
        break;
      default:
        iconColor = Colors.grey;
        icon = Icons.notifications_rounded;
        iconBg = Colors.grey.shade100;
    }

    if (notification.priority == NotificationPriority.critical) {
      iconColor = Colors.red;
      iconBg = const Color(0xFFFEF2F2);
    }

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(24)),
        child: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
      ),
      onDismissed: (_) => onDismiss(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.white : const Color(0xFFF0F7FF),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: notification.isRead ? Colors.transparent : AppColors.primary.withOpacity(0.2)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  if (!notification.isRead)
                    Positioned(
                      right: 2, top: 2,
                      child: Container(width: 10, height: 10, decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(cleanTitle, style: GoogleFonts.outfit(fontSize: 15, fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold, color: const Color(0xFF1A1C1E)))),
                        Text(timeStr, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(cleanBody, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF4A4D50), height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(Duration diff) {
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    return DateFormat('MMM d').format(notification.sentAt);
  }
}

// Helper for SliverList with separators
class SliverChildSeparatedBuilderDelegate extends SliverChildBuilderDelegate {
  SliverChildSeparatedBuilderDelegate(
    Widget Function(BuildContext, int) itemBuilder, {
    required Widget Function(BuildContext, int) separatorBuilder,
    required int itemCount,
  }) : super(
          (context, index) {
            final itemIndex = index ~/ 2;
            if (index.isEven) {
              return itemBuilder(context, itemIndex);
            } else {
              return separatorBuilder(context, itemIndex);
            }
          },
          childCount: (itemCount * 2 - 1).clamp(0, double.maxFinite.toInt()),
        );
}
