import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';

class OwnerReportsScreen extends StatelessWidget {
  const OwnerReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: Text(
          LocalizationService.tr('owner_nav_reports'),
          style: GoogleFonts.notoSansTamil(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance.collection('orders').get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                         color: Colors.blue.withOpacity(0.05),
                         shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bar_chart, size: 48, color: Colors.blueGrey),
                   ),
                   const SizedBox(height: 16),
                  Text(
                    LocalizationService.tr('owner_reports_no_data'),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          int totalOrders = docs.length;
          double totalRevenue = 0;
          int cashCount = 0;
          int creditCount = 0;

          for (final doc in docs) {
            final data = doc.data();
            final amount = (data['totalAmount'] as num? ?? 0).toDouble();
            totalRevenue += amount;
            final method = data['paymentMethod'] as String? ?? 'cash';
            if (method == 'credit') {
              creditCount++;
            } else {
              cashCount++;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 // Revenue Banner
                 Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                       gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF66BB6A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                       ),
                       borderRadius: BorderRadius.circular(24),
                       boxShadow: [
                          BoxShadow(
                             color: AppColors.primary.withOpacity(0.3),
                             blurRadius: 15,
                             offset: const Offset(0, 8),
                          )
                       ]
                    ),
                    child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                          Text(
                             LocalizationService.tr('owner_reports_total_revenue'),
                             style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                             ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                             '₹${totalRevenue.toStringAsFixed(0)}',
                             style: GoogleFonts.notoSansTamil(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                             ),
                          ),
                       ],
                    ),
                 ),
                 
                 const SizedBox(height: 24),
                 
                 // Stats Grid
                 GridView.count(
                   shrinkWrap: true,
                   physics: const NeverScrollableScrollPhysics(),
                   crossAxisCount: 2,
                   childAspectRatio: 1.3,
                   mainAxisSpacing: 16,
                   crossAxisSpacing: 16,
                   children: [
                      _StatCard(
                         title: LocalizationService.tr('owner_reports_total_orders'),
                         value: '$totalOrders',
                         icon: Icons.shopping_bag_outlined,
                         color: Colors.blue,
                      ),
                      _StatCard(
                         title: "Avg. Order Value", // Add real key if needed, using fallback
                         value: '₹${totalOrders > 0 ? (totalRevenue / totalOrders).toStringAsFixed(0) : 0}',
                         icon: Icons.analytics_outlined,
                         color: Colors.purple,
                      ),
                   ],
                 ),

                 const SizedBox(height: 24),

                 // Payment Method Analysis
                 Text(
                    LocalizationService.tr('owner_reports_payment_methods'),
                    style: GoogleFonts.notoSansTamil(
                       fontSize: 18,
                       fontWeight: FontWeight.bold,
                       color: AppColors.textPrimary
                    ),
                 ),
                 const SizedBox(height: 16),
                 Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(24),
                       boxShadow: [
                          BoxShadow(
                             color: Colors.black.withOpacity(0.04),
                             blurRadius: 10,
                             offset: const Offset(0, 4)
                          )
                       ]
                    ),
                    child: Row(
                       children: [
                          // Pie Chart
                          SizedBox(
                             height: 120,
                             width: 120,
                             child: PieChart(
                                PieChartData(
                                   sectionsSpace: 0,
                                   centerSpaceRadius: 30,
                                   sections: [
                                      PieChartSectionData(
                                         color: Colors.blue,
                                         value: cashCount.toDouble(),
                                         radius: 30,
                                         showTitle: false,
                                      ),
                                      PieChartSectionData(
                                         color: Colors.orange,
                                         value: creditCount.toDouble(), 
                                         radius: 30,
                                         showTitle: false,
                                      ),
                                   ],
                                ),
                             ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                             child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                   _LegendItem(
                                      label: LocalizationService.tr('owner_reports_cash_orders'),
                                      value: '$cashCount',
                                      color: Colors.blue,
                                   ),
                                   const SizedBox(height: 12),
                                   _LegendItem(
                                      label: LocalizationService.tr('owner_reports_credit_orders'),
                                      value: '$creditCount',
                                      color: Colors.orange,
                                   ),
                                ],
                             ),
                          )
                       ],
                    ),
                 ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
   final String title;
   final String value;
   final IconData icon;
   final Color color;

   const _StatCard({required this.title, required this.value, required this.icon, required this.color});

   @override
  Widget build(BuildContext context) {
    return Container(
       padding: const EdgeInsets.all(16),
       decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
             BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4)
             )
          ]
       ),
       child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                   color: color.withOpacity(0.1),
                   shape: BoxShape.circle
                ),
                child: Icon(icon, size: 20, color: color),
             ),
             Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                      value,
                      style: GoogleFonts.poppins(
                         fontSize: 24,
                         fontWeight: FontWeight.bold,
                         color: AppColors.textPrimary
                      ),
                   ),
                   Text(
                      title,
                      style: GoogleFonts.notoSansTamil(
                         fontSize: 12,
                         color: AppColors.textSecondary,
                         height: 1.2
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                   )
                ],
             )
          ],
       ),
    );
  }
}

class _LegendItem extends StatelessWidget {
   final String label;
   final String value;
   final Color color;

   const _LegendItem({required this.label, required this.value, required this.color});

   @override
  Widget build(BuildContext context) {
    return Row(
       mainAxisAlignment: MainAxisAlignment.spaceBetween,
       children: [
          Row(
             children: [
                Container(
                   width: 12,
                   height: 12,
                   decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                   label,
                   style: GoogleFonts.notoSansTamil(
                      fontSize: 12,
                      color: AppColors.textPrimary
                   ),
                ),
             ],
          ),
          Text(
             value,
             style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary
             ),
          )
       ],
    );
  }
}
