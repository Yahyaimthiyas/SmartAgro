import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import '../alerts/owner_alerts_screen.dart';
import '../farmers/owner_farmers_screen.dart';
import '../orders/owner_orders_screen.dart';
import '../reports/owner_reports_screen.dart';
import '../stock/owner_stock_screen.dart';
import '../stock/owner_edit_product_screen.dart';
import '../notifications/owner_notification_screen.dart'; // [NEW]

class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'Owner';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Very light grey-blue background
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .limit(20)
            .snapshots(),
        builder: (context, orderSnapshot) {
          final orderDocs = orderSnapshot.data?.docs ?? [];

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context, userName),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RevenueCard(orders: orderDocs),
                      const SizedBox(height: 24),
                      _RevenueChartCard(orders: orderDocs),
                      const SizedBox(height: 24),
                      _SectionTitle(
                        title: LocalizationService.tr('owner_dashboard_quick_actions_title'),
                      ),
                      const SizedBox(height: 12),
                      const _QuickActionsRow(),
                      const SizedBox(height: 24),
                      _SectionTitle(
                        title: LocalizationService.tr('owner_dashboard_recent_section_title'),
                        action: LocalizationService.tr('view_all'),
                        onActionTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerOrdersScreen())),
                      ),
                      const SizedBox(height: 12),
                      _RecentOrdersList(orders: orderDocs),
                      const SizedBox(height: 24),
                       _SectionTitle(title: LocalizationService.tr('owner_dashboard_stock_section_title')),
                      const SizedBox(height: 12),
                      const _StockSummaryCard(),
                      const SizedBox(height: 24),
                      _SectionTitle(title: LocalizationService.tr('owner_dashboard_credit_section_title')),
                      const SizedBox(height: 12),
                      const _CreditSummaryCard(),
                      const SizedBox(height: 24),
                      const _RiskAlertCard(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, String userName) {
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, d MMM').format(now);

    return SliverAppBar(
      backgroundColor: const Color(0xFFF5F7FA),
      elevation: 0,
      pinned: true,
      expandedHeight: 120.0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        centerTitle: false,
        title: LayoutBuilder(
          builder: (context, constraints) {
             return const SizedBox.shrink(); // Hide default title, using background for layout
          }
        ),
        background: Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    LocalizationService.tr('welcome'),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userName,
                    style: GoogleFonts.notoSansTamil(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    formattedDate,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _NotificationButton(),
                  const SizedBox(width: 12),
                  _SettingsButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/owner-settings'),
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.settings_outlined, color: AppColors.textPrimary, size: 20),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerNotificationScreen())), 
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary, size: 20),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onActionTap;

  const _SectionTitle({required this.title, this.action, this.onActionTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.notoSansTamil(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (action != null) ...[
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              action!,
              style: GoogleFonts.notoSansTamil(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> orders;

  const _RevenueCard({required this.orders});

  @override
  Widget build(BuildContext context) {
    double revenue = 0;
    int pending = 0;
    int completed = 0;

    for (final doc in orders) {
      final data = doc.data();
      final status = data['status'] as String? ?? 'reserved';
      final amount = (data['totalAmount'] as num? ?? 0).toDouble();

      if (status == 'picked') {
        revenue += amount;
        completed++;
      } else if (status != 'cancelled') {
        pending++;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary, 
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocalizationService.tr('owner_dashboard_orders_revenue'),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${revenue.toStringAsFixed(0)}',
            style: GoogleFonts.notoSansTamil(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _RevenueStat(
                label: LocalizationService.tr('owner_dashboard_orders_active'),
                value: '$pending',
                icon: Icons.hourglass_empty,
              ),
              Container(height: 24, width: 1, color: Colors.white.withOpacity(0.3), margin: const EdgeInsets.symmetric(horizontal: 16)),
              _RevenueStat(
                label: LocalizationService.tr('owner_dashboard_orders_completed'),
                value: '$completed',
                icon: Icons.check_circle_outline,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RevenueStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _RevenueStat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 16),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.notoSansTamil(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label.split(' ').first, 
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _QuickActionTile(
            icon: Icons.add_circle_outline,
            label: LocalizationService.tr('owner_action_product'),
            color: Colors.blue,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OwnerEditProductScreen())),
          ),
          const SizedBox(width: 12),
          _QuickActionTile(
            icon: Icons.inventory_2_outlined,
            label: LocalizationService.tr('owner_action_stock'),
            color: Colors.orange,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerStockScreen())),
          ),
          const SizedBox(width: 12),
          _QuickActionTile(
            icon: Icons.people_outline,
            label: LocalizationService.tr('owner_action_farmers'),
            color: Colors.purple,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerFarmersScreen())),
          ),
          const SizedBox(width: 12),
          _QuickActionTile(
            icon: Icons.bar_chart,
            label: LocalizationService.tr('owner_action_reports'),
            color: Colors.teal,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerReportsScreen())),
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90, 
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentOrdersList extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> orders;

  const _RecentOrdersList({required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            LocalizationService.tr('owner_orders_none_recent'),
            style: GoogleFonts.poppins(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final recent = orders.take(3).toList();

    return Column(
      children: recent.map((doc) => _OrderTile(data: doc.data(), id: doc.id)).toList(),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final String id;

  const _OrderTile({required this.data, required this.id});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String? ?? 'reserved';
    final total = (data['totalAmount'] as num? ?? 0).toDouble();
    final ts = data['createdAt'] as Timestamp?;
    final date = ts != null ? DateFormat('MMM d, h:mm a').format(ts.toDate()) : 'Unknown';

    Color statusColor;
    String statusText;

    switch (status) {
      case 'ready':
        statusColor = Colors.orange;
        statusText = LocalizationService.tr('status_ready');
        break;
      case 'picked':
        statusColor = Colors.green;
        statusText = LocalizationService.tr('status_picked');
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = LocalizationService.tr('status_cancelled');
        break;
      default:
        statusColor = Colors.blue;
        statusText = LocalizationService.tr('status_placed');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.shopping_bag_outlined, color: statusColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "#$id",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  date,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "₹${total.toStringAsFixed(0)}",
                style: GoogleFonts.notoSansTamil(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StockSummaryCard extends StatelessWidget {
  const _StockSummaryCard();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        int low = 0;
        int out = 0;
        for (var doc in docs) {
          final s = (doc.data()['stock'] as num? ?? 0).toInt();
          if (s <= 0) out++;
          else if (s <= 3) low++;
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MiniStat(
                 label: LocalizationService.tr('owner_stock_low'),
                value: "$low",
                color: Colors.orange,
                icon: Icons.warning_amber_rounded,
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade200),
              _MiniStat(
                label: LocalizationService.tr('owner_stock_out'),
                value: "$out",
                color: Colors.red,
                icon: Icons.remove_circle_outline,
              ),
            ],
          ),
        );
      }
    );
  }
}

class _CreditSummaryCard extends StatelessWidget {
  const _CreditSummaryCard();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('creditLedger').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        double balance = 0;
        for (var doc in docs) {
          final amt = (doc.data()['amount'] as num? ?? 0).toDouble();
          final type = doc.data()['type'] ?? 'credit';
          if (type == 'credit') balance += amt;
          else balance -= amt;
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF263238), // Dark Grey
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LocalizationService.tr('owner_credit_balance'),
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    "₹${balance.abs().toStringAsFixed(0)}",
                    style: GoogleFonts.notoSansTamil(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (balance != 0)
                Chip(
                  label: Text(
                    balance > 0 ? "Outstanding" : "Advance",
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  backgroundColor: balance > 0 ? Colors.red : Colors.green,
                ),
            ],
          ),
        );
      }
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MiniStat({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.notoSansTamil(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _RiskAlertCard extends StatelessWidget {
  const _RiskAlertCard();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'rejected')
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        final rejectedCount = snapshot.data?.docs.length ?? 0;
        if (rejectedCount == 0) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade100),
          ),
          child: Row(
            children: [
              const Icon(Icons.security, color: Colors.red),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocalizationService.tr('owner_security_alert'),
                      style: GoogleFonts.notoSansTamil(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade900,
                      ),
                    ),
                    Text(
                      "$rejectedCount ${LocalizationService.tr('owner_security_alert_msg')}",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.red.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RevenueChartCard extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> orders;

  const _RevenueChartCard({required this.orders});

  @override
  Widget build(BuildContext context) {
    // 1. Prepare Data: Last 7 days
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final map = <int, double>{}; // Day Index (0-6) -> Revenue

    for (int i = 0; i < 7; i++) {
      map[i] = 0;
    }

    for (final doc in orders) {
      final data = doc.data();
      final status = data['status'] as String? ?? 'reserved';
      if (status == 'cancelled') continue;

      final ts = (data['createdAt'] as Timestamp?)?.toDate();
      if (ts == null) continue;

      final date = DateTime(ts.year, ts.month, ts.day);
      final diff = today.difference(date).inDays;

      if (diff >= 0 && diff < 7) {
        final amt = (data['totalAmount'] as num? ?? 0).toDouble();
        // Index 6 is Today, 0 is 6 days ago in chart X-axis usually.
        // Let's map 0..6 where 6 is Today.
        final index = 6 - diff;
        map[index] = (map[index] ?? 0) + amt;
      }
    }

    final spots = <FlSpot>[];
    double maxRevenue = 0;
    for (int i = 0; i < 7; i++) {
      final val = map[i] ?? 0;
      if (val > maxRevenue) maxRevenue = val;
      spots.add(FlSpot(i.toDouble(), val));
    }

    if (maxRevenue == 0) maxRevenue = 100; // Default scale

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocalizationService.tr('owner_revenue_trend'),
            style: GoogleFonts.notoSansTamil(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            LocalizationService.tr('owner_last_7_days'),
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 1.70,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        // 6 means Today.
                        final day = today.subtract(Duration(days: 6 - index));
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            DateFormat('E').format(day)[0], // M, T, W...
                            style: GoogleFonts.poppins(
                                color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: maxRevenue * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF66BB6A)],
                    ),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.3),
                          AppColors.primary.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


