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
import '../stock/owner_disease_management_screen.dart';
import '../notifications/owner_notification_screen.dart'; // [NEW]
import '../billing/owner_direct_billing_screen.dart';
import '../suppliers/owner_suppliers_screen.dart';
import '../stock/owner_product_demand_screen.dart'; // [NEW]
import '../crop_guide/owner_crop_guide_screen.dart';

class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? (LocalizationService.isTamil ? 'உரிமையாளர்' : 'Owner');

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
                      const _WeatherAdvisory(), // [NEW]
                      const SizedBox(height: 16),
                      _RevenueCard(orders: orderDocs),
                      const SizedBox(height: 24),
                      _GoalTrackerCard(orders: orderDocs), // [NEW]
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
                      const SizedBox(height: 32),
                      const _StockAlertsSection(),
                      const SizedBox(height: 24),
                      const _DeadStockSection(), // [NEW]
                      const SizedBox(height: 24),
                      const _VillageSalesSection(), // [NEW]
                      const SizedBox(height: 24),
                      const _TopFarmersRankingSection(), // [NEW]
                      const SizedBox(height: 24),
                      const _FarmerCropDistributionSection(), // [NEW]
                      const SizedBox(height: 24),
                      const _TopProfitProductsSection(), // [NEW]
                      const SizedBox(height: 24),
                      const _ProfitableDaySection(), // [NEW]
                      const SizedBox(height: 24),
                      const _ExpiryFlashSaleSection(), // [NEW]
                      const SizedBox(height: 24),
                      const _InactiveFarmerReminder(), // [NEW]
                      const SizedBox(height: 24),
                      const _ExpiryAlertsSection(),
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
      backgroundColor: AppColors.background,
      elevation: 0,
      pinned: true,
      expandedHeight: 130.0,
      centerTitle: false,
      flexibleSpace: FlexibleSpaceBar(
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
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userName,
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _AppBarIconButton(
                    icon: Icons.notifications_none_rounded,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerNotificationScreen())),
                  ),
                  const SizedBox(width: 12),
                  _AppBarIconButton(
                    icon: Icons.settings_outlined,
                    onTap: () => Navigator.pushNamed(context, '/owner-settings'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _AppBarIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 24),
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
            style: GoogleFonts.outfit(
              fontSize: 20,
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                action!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
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
    double todayRevenue = 0;
    double monthlyRevenue = 0;
    int todayOrders = 0;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(now.year, now.month, 1);

    for (final doc in orders) {
      final data = doc.data();
      final status = data['status'] as String? ?? 'reserved';
      final amount = (data['totalAmount'] as num? ?? 0).toDouble();
      final ts = data['createdAt'] as Timestamp?;
      
      if (ts == null || status == 'cancelled') continue;
      
      final date = ts.toDate();
      if (date.isAfter(todayStart)) {
        todayRevenue += amount;
        todayOrders++;
      }
      if (date.isAfter(monthStart)) {
        monthlyRevenue += amount;
      }
    }

    final isTa = LocalizationService.isTamil;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF00332B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    Text(
                      isTa ? 'இன்றைய விற்பனை' : "TODAY'S SALES",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withOpacity(0.6),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${todayRevenue.toStringAsFixed(0)}',
                      style: GoogleFonts.outfit(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                 ],
               ),
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                 decoration: BoxDecoration(
                   color: AppColors.accent,
                   borderRadius: BorderRadius.circular(12),
                 ),
                 child: Text(
                   '$todayOrders Bills',
                   style: GoogleFonts.inter(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                 ),
               ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _RevenueStat(
                label: isTa ? 'மாதாந்திர விற்பனை' : 'Monthly',
                value: '₹${monthlyRevenue.toStringAsFixed(0)}',
                icon: Icons.auto_graph_rounded,
              ),
              const Spacer(),
              _RevenueStat(
                label: isTa ? 'மதிப்பிடப்பட்ட லாபம்' : 'Profit',
                value: '₹${(todayRevenue * 0.15).toStringAsFixed(0)}',
                icon: Icons.toll_rounded,
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
        Container(
           padding: const EdgeInsets.all(8),
           decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
           child: Icon(icon, color: AppColors.accent, size: 16),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label, 
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.white.withOpacity(0.6),
                fontWeight: FontWeight.w500,
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
            icon: Icons.receipt_long,
            label: LocalizationService.tr('owner_nav_billing'),
            color: Colors.green,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerDirectBillingScreen())),
          ),
          const SizedBox(width: 12),
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
            icon: Icons.medical_services_outlined,
            label: LocalizationService.isTamil ? 'நோய் மேலாண்மை' : 'Diseases',
            color: Colors.red,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerDiseaseManagementScreen())),
          ),
          const SizedBox(width: 12),
          _QuickActionTile(
            icon: Icons.menu_book_outlined,
            label: LocalizationService.isTamil ? 'பயிர் வழிகாட்டி' : 'Crop Guides',
            color: Colors.teal,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerCropGuideScreen())),
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
            icon: Icons.business,
            label: LocalizationService.isTamil ? 'விற்பனையாளர்கள்' : 'Suppliers',
            color: Colors.brown,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerSuppliersScreen())),
          ),
          const SizedBox(width: 12),
          _QuickActionTile(
            icon: Icons.assignment_outlined,
            label: LocalizationService.isTamil ? 'தேவைகள்' : 'Demand',
            color: Colors.indigo,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerProductDemandScreen())),
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
    final isTa = LocalizationService.isTamil;
    String date = 'Unknown';
    if (ts != null) {
      if (isTa) {
        // Simple Tamil date format
        date = "${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}";
      } else {
        date = DateFormat('MMM d, h:mm a').format(ts.toDate());
      }
    }

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
                    balance > 0 ? (LocalizationService.isTamil ? 'நிலுவை' : 'Outstanding') : (LocalizationService.isTamil ? 'முன்பணம்' : 'Advance'),
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

class _StockAlertsSection extends StatelessWidget {
  const _StockAlertsSection();

  @override
  Widget build(BuildContext context) {
    final isTa = LocalizationService.isTamil;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('products')
          .where('stock', isLessThanOrEqualTo: 5)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(
              title: isTa ? 'குறைந்த அளவு இருப்பு' : 'Low Stock Alerts',
              action: LocalizationService.tr('view_all'),
              onActionTap: () => Navigator.pushNamed(context, '/owner-stock'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data();
                  final stock = data['stock'] as int;
                  final name = LocalizationService.pickTaEn(data['name_ta'], data['name_en']);
                  
                  return Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange.shade800),
                            const SizedBox(width: 4),
                            Text(
                              'Stock: $stock',
                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ExpiryAlertsSection extends StatelessWidget {
  const _ExpiryAlertsSection();

  @override
  Widget build(BuildContext context) {
    final isTa = LocalizationService.isTamil;
    final criticalDate = DateTime.now().add(const Duration(days: 90));

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('products')
          .where('expiryDate', isLessThanOrEqualTo: Timestamp.fromDate(criticalDate))
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        
        return Column(
          children: [
            if (docs.isNotEmpty) ...[
              _SectionTitle(title: isTa ? 'காலாவதியாகும் பொருட்கள்' : 'Product Expiry'),
              const SizedBox(height: 12),
              ...docs.take(3).map((doc) {
                final data = doc.data();
                final name = LocalizationService.pickTaEn(data['name_ta'], data['name_en']);
                final expiry = (data['expiryDate'] as Timestamp).toDate();
                final diff = expiry.difference(DateTime.now()).inDays;
                return ListTile(
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Expires in $diff days'),
                  leading: const Icon(Icons.event_busy, color: Colors.orange),
                );
              }),
            ],
            const SizedBox(height: 24),
            const _CreditExpiryAlertsSection(),
          ],
        );
      },
    );
  }
}

class _CreditExpiryAlertsSection extends StatelessWidget {
  const _CreditExpiryAlertsSection();

  @override
  Widget build(BuildContext context) {
    final isTa = LocalizationService.isTamil;
    final now = DateTime.now();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('paymentMethod', isEqualTo: 'credit')
          .where('status', isEqualTo: 'picked')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final docs = snapshot.data!.docs.where((doc) {
           final expiry = (doc.data()['creditExpiryDate'] as Timestamp?)?.toDate();
           if (expiry == null) return false;
           return expiry.difference(now).inDays <= 7;
        }).toList();

        if (docs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(title: isTa ? 'காலாவதியாகும் கடன்கள்' : 'Expiring Credits'),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data();
                  final expiry = (data['creditExpiryDate'] as Timestamp?)?.toDate() ?? now;
                  final daysLeft = expiry.difference(now).inDays;
                  final total = data['totalAmount'] as num;

                  return Container(
                    width: 180,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: daysLeft < 0 ? Colors.red.shade50 : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: daysLeft < 0 ? Colors.red.shade100 : Colors.blue.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('#${docs[index].id.substring(0,8).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('₹$total', style: const TextStyle(fontSize: 12)),
                        const Spacer(),
                        Text(
                          daysLeft < 0 ? (isTa ? 'காலாவதியானது!' : 'Expired!') : (isTa ? '$daysLeft நாட்கள் உள்ளன' : '$daysLeft days left'),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: daysLeft < 0 ? Colors.red : Colors.blue),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GoalTrackerCard extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> orders;
  const _GoalTrackerCard({required this.orders});

  @override
  Widget build(BuildContext context) {
    const double goalAmount = 200000;
    double currentMonthSales = 0;
    
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    for (var doc in orders) {
      final ts = (doc.data()['createdAt'] as Timestamp?);
      if (ts == null) continue;
      if (ts.toDate().isAfter(monthStart) && doc.data()['status'] != 'cancelled') {
        currentMonthSales += (doc.data()['totalAmount'] as num? ?? 0).toDouble();
      }
    }

    final progress = (currentMonthSales / goalAmount).clamp(0.0, 1.0);
    final isTa = LocalizationService.isTamil;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isTa ? 'விற்பனை இலக்கு' : 'Monthly Sales Goal', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
              Text('₹${goalAmount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(progress > 0.8 ? Colors.green : Colors.blue),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${currentMonthSales.toStringAsFixed(0)} Achieved', 
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)
              ),
              Text('${(progress * 100).toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpiryFlashSaleSection extends StatelessWidget {
  const _ExpiryFlashSaleSection();

  @override
  Widget build(BuildContext context) {
    final isTa = LocalizationService.isTamil;
    final now = DateTime.now();
    final thirtyDaysLater = now.add(const Duration(days: 30));

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final expiringDocs = snapshot.data!.docs.where((doc) {
          final expiry = (doc.data()['expiryDate'] as Timestamp?)?.toDate();
          if (expiry == null) return false;
          return expiry.isAfter(now) && expiry.isBefore(thirtyDaysLater);
        }).toList();

        if (expiringDocs.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFD81B60)]),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.flash_on, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isTa ? 'விரைவு விற்பனை பரிந்துரை!' : 'Flash Sale Suggestion!',
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                isTa 
                  ? 'சில பொருட்கள் விரைவில் காலாவதியாகின்றன. அவற்றை விற்க 15% தள்ளுபடி வழங்கவும்.' 
                  : 'A few products are expiring soon. Offer a 15% discount to clear stock quickly.',
                style: GoogleFonts.notoSansTamil(color: Colors.white.withOpacity(0.9), fontSize: 12),
              ),
              const SizedBox(height: 16),
              ...expiringDocs.take(2).map((doc) {
                final name = isTa ? (doc.data()['name_ta'] ?? doc.data()['name_en']) : (doc.data()['name_en'] ?? doc.data()['name_ta']);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                      Text(isTa ? '15% தள்ளுபடி' : '15% Off', style: const TextStyle(color: Colors.yellow, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}

class _InactiveFarmerReminder extends StatelessWidget {
  const _InactiveFarmerReminder();

  @override
  Widget build(BuildContext context) {
    final isTa = LocalizationService.isTamil;
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'farmer')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final inactiveFarmers = snapshot.data!.docs.where((doc) {
          final lastVisit = (doc.data()['lastVisitDate'] as Timestamp?)?.toDate();
          if (lastVisit == null) return false;
          return lastVisit.isBefore(thirtyDaysAgo);
        }).toList();

        if (inactiveFarmers.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.orange.shade100),
            boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_off_outlined, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isTa ? 'செயலற்ற விவசாயிகள்' : 'Inactive Farmers',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...inactiveFarmers.take(3).map((doc) {
                final name = doc.data()['name'] ?? 'Farmer';
                final lastVisit = (doc.data()['lastVisitDate'] as Timestamp?)?.toDate();
                final days = lastVisit != null ? now.difference(lastVisit).inDays : 0;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 12, backgroundColor: Colors.orange.shade50, child: const Icon(Icons.person, size: 12, color: Colors.orange)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                      Text(isTa ? '$days நாட்களுக்கு முன்' : '$days days ago', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {}, // Would link to SMS broadcast
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    isTa ? 'அனைவருக்கும் எஸ்எம்எஸ் அனுப்பவும்' : 'Send SMS to All',
                    style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WeatherAdvisory extends StatelessWidget {
  const _WeatherAdvisory();

  @override
  Widget build(BuildContext context) {
    final isTa = LocalizationService.isTamil;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.wb_sunny_rounded, color: Colors.orange, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTa ? 'இன்றைய வானிலை: 32°C' : 'Today\'s Weather: 32°C',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue.shade900),
                ),
                Text(
                  isTa 
                    ? 'மிதமான வெப்பம். தக்காளி செடிகளுக்கு அதிக நீர் பாய்ச்சவும்.' 
                    : 'Mild heat. Increase irrigation for Tomato crops.',
                  style: GoogleFonts.notoSansTamil(fontSize: 11, color: Colors.blue.shade700),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Text(
              isTa ? 'சன்னி' : 'Sunny',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange),
            ),
          )
        ],
      ),
    );
  }
}




class _DeadStockSection extends StatelessWidget {
  const _DeadStockSection();

  @override
  Widget build(BuildContext context) {
    final isTa = LocalizationService.isTamil;
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('stock', isGreaterThan: 0)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final deadStockDocs = snapshot.data!.docs.where((doc) {
          final lastSold = (doc.data()['lastSoldDate'] as Timestamp?)?.toDate();
          if (lastSold == null) return true; // Never sold is also dead stock
          return lastSold.isBefore(thirtyDaysAgo);
        }).toList();

        if (deadStockDocs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(title: LocalizationService.tr('owner_dashboard_dead_stock')),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.red.shade50),
              ),
              child: Column(
                children: deadStockDocs.take(3).map((doc) {
                  final data = doc.data();
                  final name = LocalizationService.pickTaEn(data['name_ta'], data['name_en']);
                  final stock = data['stock'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(name, style: const TextStyle(fontSize: 12))),
                        Text('${isTa ? "இருப்பு" : "Stock"}: $stock', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _VillageSalesSection extends StatelessWidget {
  const _VillageSalesSection();

  @override
  Widget build(BuildContext context) {
    final isTa = LocalizationService.isTamil;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final Map<String, int> villageCounts = {};
        for (var doc in snapshot.data!.docs) {
          final village = doc.data()['customerVillage'] as String? ?? (isTa ? 'தெரியவில்லை' : 'Unknown');
          if (village.trim().isEmpty) continue;
          villageCounts[village] = (villageCounts[village] ?? 0) + 1;
        }

        if (villageCounts.isEmpty) return const SizedBox.shrink();

        final sortedVillages = villageCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(title: LocalizationService.tr('owner_dashboard_village_sales')),
            const SizedBox(height: 12),
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (sortedVillages.first.value + 2).toDouble(),
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= sortedVillages.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              sortedVillages[value.toInt()].key.split(' ').first,
                              style: const TextStyle(fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(sortedVillages.take(5).length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: sortedVillages[i].value.toDouble(),
                          color: AppColors.primary,
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                        )
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FarmerCropDistributionSection extends StatelessWidget {
  const _FarmerCropDistributionSection();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'farmer').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final Map<String, int> cropCounts = {};
        for (var doc in snapshot.data!.docs) {
          final crop = doc.data()['primaryCrop'] as String?;
          if (crop != null && crop.isNotEmpty) {
            cropCounts[crop] = (cropCounts[crop] ?? 0) + 1;
          }
        }

        if (cropCounts.isEmpty) return const SizedBox.shrink();

        final sortedCrops = cropCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(title: LocalizationService.tr('owner_dashboard_crop_distribution')),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              child: Column(
                children: sortedCrops.take(4).map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.grass, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600))),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)), child: Text('${e.value} Farmers', style: TextStyle(color: Colors.green.shade800, fontSize: 11, fontWeight: FontWeight.bold))),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TopProfitProductsSection extends StatelessWidget {
  const _TopProfitProductsSection();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('products').where('stock', isGreaterThan: 0).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final docs = snapshot.data!.docs.toList();
        // Calculate mock margin for sorting. Higher margin items will be shown here.
        docs.sort((a, b) {
          final aPrice = (a.data()['price'] as num?)?.toDouble() ?? 0;
          final bPrice = (b.data()['price'] as num?)?.toDouble() ?? 0;
          return bPrice.compareTo(aPrice); // Simple sorting by price for demonstration
        });

        if (docs.isEmpty) return const SizedBox.shrink();

        final isTa = LocalizationService.isTamil;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(title: LocalizationService.tr('owner_dashboard_top_profit')),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.amber.shade100)),
              child: Column(
                children: docs.take(3).map((e) {
                  final data = e.data();
                  final name = isTa ? (data['name_ta'] ?? data['name_en']) : (data['name_en'] ?? data['name_ta']);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
                        Row(
                          children: [
                            const Icon(Icons.arrow_upward, color: Colors.green, size: 14),
                            Text(' ~15%', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        )
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProfitableDaySection extends StatelessWidget {
  const _ProfitableDaySection();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('orders').limit(500).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final Map<int, double> daySales = {};
        for (var doc in snapshot.data!.docs) {
          final ts = (doc.data()['createdAt'] as Timestamp?)?.toDate();
          final amount = (doc.data()['totalAmount'] as num?)?.toDouble() ?? 0;
          if (ts != null) {
            daySales[ts.weekday] = (daySales[ts.weekday] ?? 0) + amount;
          }
        }

        if (daySales.isEmpty) return const SizedBox.shrink();

        final sortedDays = daySales.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        final bestDayInt = sortedDays.first.key;
        final bestDayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][bestDayInt - 1];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(title: LocalizationService.tr('owner_dashboard_profitable_day')),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.blue.shade100)),
              child: Row(
                children: [
                  const Icon(Icons.event_available, color: Colors.blue, size: 28),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bestDayName, style: TextStyle(color: Colors.blue.shade900, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Highest Sales Volume Day', style: TextStyle(color: Colors.blue.shade700, fontSize: 12)),
                    ],
                  ),
                  const Spacer(),
                  Text('₹${sortedDays.first.value.toStringAsFixed(0)}', style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TopFarmersRankingSection extends StatelessWidget {
  const _TopFarmersRankingSection();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('orders').where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 30)))).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final Map<String, double> farmerSpends = {};
        final Map<String, String> farmerNames = {};

        for (var doc in snapshot.data!.docs) {
          final data = doc.data();
          final farmerId = data['farmerId'] as String?;
          if (farmerId == null) continue;
          
          final amount = (data['totalAmount'] as num?)?.toDouble() ?? 0;
          final name = data['customerName'] as String? ?? 'Unknown Farmer';
          
          farmerSpends[farmerId] = (farmerSpends[farmerId] ?? 0) + amount;
          farmerNames[farmerId] = name;
        }

        if (farmerSpends.isEmpty) return const SizedBox.shrink();

        final sortedFarmers = farmerSpends.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        final isTa = LocalizationService.isTamil;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
               children: [
                  const Icon(Icons.workspace_premium, color: Colors.amber, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    isTa ? 'Top Farmers (இந்த மாதம்)' : 'Top Farmers (This Month)',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
               ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                 color: Colors.white,
                 borderRadius: BorderRadius.circular(24),
                 boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 8))],
                 border: Border.all(color: Colors.amber.shade200),
              ),
              child: Column(
                children: sortedFarmers.take(3).toList().asMap().entries.map((entry) {
                  final index = entry.key;
                  final farmerId = entry.value.key;
                  final spend = entry.value.value;
                  final name = farmerNames[farmerId] ?? 'Farmer';
                  
                  IconData medalIcon;
                  Color medalColor;
                  if (index == 0) { medalIcon = Icons.emoji_events; medalColor = Colors.amber; }
                  else if (index == 1) { medalIcon = Icons.military_tech; medalColor = Colors.grey.shade400; }
                  else { medalIcon = Icons.military_tech; medalColor = Colors.brown.shade300; }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: medalColor.withOpacity(0.2),
                          child: Icon(medalIcon, color: medalColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(isTa ? 'சிறந்த வாடிக்கையாளர்' : 'Loyal Customer', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        Text('₹${spend.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700, fontSize: 15)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
