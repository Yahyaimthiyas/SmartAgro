import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import '../stock/owner_edit_product_screen.dart';
import '../stock/owner_stock_screen.dart';
import '../stock/owner_disease_management_screen.dart';
import '../farmers/owner_farmers_screen.dart';
import '../reports/owner_reports_screen.dart';
import '../notifications/owner_notification_screen.dart';
import '../orders/owner_orders_screen.dart';

class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isTa = LocalizationService.isTamil;
    final userName = user?.displayName ?? (isTa ? 'உரிமையாளர்' : 'Owner');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Professional light grey background
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .limit(10)
            .snapshots(),
        builder: (context, snapshot) {
          final orders = snapshot.data?.docs ?? [];
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Premium Header with Profile & Icons
              _buildHeader(context, userName, isTa),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      
                      // 2. Executive Revenue Hero Card
                      FadeInDown(
                        duration: const Duration(milliseconds: 600),
                        child: _buildRevenueHero(orders, isTa),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // 3. Quick Actions Grid
                      Text(
                        isTa ? 'விரைவான செயல்கள்' : 'Quick Actions',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1C1E),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildQuickActions(context),
                      
                      const SizedBox(height: 32),
                      
                      // 4. Recent Orders Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isTa ? 'சமீபத்திய ஆர்டர்கள்' : 'Recent Orders',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1C1E),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const OwnerOrdersScreen()),
                            ),
                            child: Text(
                              isTa ? 'அனைத்தையும் காண்' : 'VIEW ALL',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildRecentOrders(orders, isTa),
                      
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

  Widget _buildHeader(BuildContext context, String userName, bool isTa) {
    return SliverAppBar(
      backgroundColor: const Color(0xFFF8F9FA),
      pinned: true,
      elevation: 0,
      leadingWidth: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF10B981)]),
              shape: BoxShape.circle,
            ),
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SmartAgro',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
              Text(
                isTa ? 'மீண்டும் வருக, உரிமையாளர்' : 'WELCOME BACK, OWNER',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        _buildCircleAction(context, Icons.notifications_none_rounded, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerNotificationScreen()));
        }),
        const SizedBox(width: 8),
        _buildCircleAction(context, Icons.settings_outlined, () {
          Navigator.pushNamed(context, '/owner-settings');
        }),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildCircleAction(BuildContext context, IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF1A1C1E), size: 22),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildRevenueHero(List<QueryDocumentSnapshot<Map<String, dynamic>>> orders, bool isTa) {
    double todayRevenue = 0;
    int todayOrders = 0;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    for (final doc in orders) {
      final data = doc.data();
      final status = data['status'] as String? ?? 'reserved';
      final amount = (data['totalAmount'] as num? ?? 0).toDouble();
      final ts = data['createdAt'] as Timestamp?;
      if (ts == null || status == 'cancelled') continue;
      if (ts.toDate().isAfter(todayStart)) {
        todayRevenue += amount;
        todayOrders++;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF38BDF8)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isTa ? 'இன்றைய விற்பனை' : "TODAY'S SALES",
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.9),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${NumberFormat('#,##,###').format(todayRevenue)}',
            style: GoogleFonts.outfit(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.15),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildHeroStat(
                  isTa ? 'தோராயமான லாபம்' : 'EST. PROFIT',
                  '₹${NumberFormat('#,##,###').format(todayRevenue * 0.18)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.9,
      children: [
        _buildActionCard(context, Icons.add_circle_outline_rounded, 'Add Product', Colors.green, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerEditProductScreen()));
        }),
        _buildActionCard(context, Icons.inventory_2_outlined, 'Stock', Colors.orange, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerStockScreen()));
        }),
        _buildActionCard(context, Icons.medical_services_outlined, 'Diseases', Colors.red, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerDiseaseManagementScreen()));
        }),
        _buildActionCard(context, Icons.people_outline_rounded, 'Farmers', Colors.purple, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerFarmersScreen()));
        }),
        _buildActionCard(context, Icons.analytics_outlined, 'Reports', Colors.teal, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerReportsScreen()));
        }),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return FadeInUp(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                LocalizationService.tr(label.toLowerCase().replaceAll(' ', '_')),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1C1E),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentOrders(List<QueryDocumentSnapshot<Map<String, dynamic>>> orders, bool isTa) {
    if (orders.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: Text(
          isTa ? 'ஆர்டர்கள் எதுவும் இல்லை' : 'No recent orders yet',
          style: GoogleFonts.inter(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: orders.take(4).map((doc) => _buildOrderTile(doc.id, doc.data(), isTa)).toList(),
    );
  }

  Widget _buildOrderTile(String id, Map<String, dynamic> data, bool isTa) {
    final status = data['status'] as String? ?? 'placed';
    final total = (data['totalAmount'] as num? ?? 0).toDouble();
    final ts = data['createdAt'] as Timestamp?;
    
    // Clean ID: Just show last 5 characters
    final cleanId = id.length > 5 ? id.substring(id.length - 5).toUpperCase() : id.toUpperCase();
    
    String dateStr = '';
    if (ts != null) {
      dateStr = DateFormat('MMM d, yyyy • hh:mm a').format(ts.toDate());
    }

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'ready': statusColor = Colors.orange; statusLabel = 'READY'; break;
      case 'picked': statusColor = Colors.green; statusLabel = 'PICKED'; break;
      case 'cancelled': statusColor = Colors.red; statusLabel = 'CANCELLED'; break;
      default: statusColor = Colors.blue; statusLabel = 'PROCESSING';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.shopping_bag_outlined, color: Colors.grey.shade400, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #$cleanId',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1C1E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${NumberFormat('#,###').format(total)}',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    letterSpacing: 0.5,
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
