import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import 'farmer_order_tracking_screen.dart';

class FarmerOrdersScreen extends StatelessWidget {
  const FarmerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            LocalizationService.tr('title_my_orders'),
            style: GoogleFonts.notoSansTamil(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Text(
            LocalizationService.tr('error_login_again'),
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          LocalizationService.tr('title_my_orders'),
          style: GoogleFonts.notoSansTamil(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
             return Center(
                child: Padding(
                   padding: const EdgeInsets.all(20),
                   child: Text("Error: ${snapshot.error}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                )
             );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = List<DocumentSnapshot<Map<String, dynamic>>>.from(snapshot.data?.docs ?? []);
          // Client-side sorting to avoid missing index or composite index requirements
          docs.sort((a, b) {
             final t1 = a.data()?['createdAt'] as Timestamp?;
             final t2 = b.data()?['createdAt'] as Timestamp?;
             if (t1 == null || t2 == null) return 0;
             return t2.compareTo(t1); // Descending
          });
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.history, size: 60, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    LocalizationService.tr('msg_no_orders_yet'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansTamil(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final id = docs[index].id;
              final status = data?['status'] as String? ?? 'reserved';
              final total = data?['totalAmount'] as num? ?? 0;
              final payment = data?['paymentMethod'] as String? ?? 'cash';
              final ts = data?['createdAt'] as Timestamp?;
              final created = ts?.toDate();

              final statusMeta = _statusMeta(status);

              return InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FarmerOrderTrackingScreen(orderId: id),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Status Strip
                        Container(
                          width: 6,
                          decoration: BoxDecoration(
                            color: statusMeta.color,
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                       decoration: BoxDecoration(
                                          color: statusMeta.color.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                       ),
                                       child: Text(
                                          LocalizationService.tr(statusMeta.chipTextKey).toUpperCase(),
                                          style: GoogleFonts.poppins(
                                             fontSize: 11,
                                             fontWeight: FontWeight.w600,
                                             color: statusMeta.color
                                          ),
                                       ),
                                    ),
                                    Text(
                                      '₹${total.toStringAsFixed(0)}',
                                      style: GoogleFonts.notoSansTamil(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  LocalizationService.tr(statusMeta.labelKey),
                                  style: GoogleFonts.notoSansTamil(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    if (created != null)
                                      Text(
                                        '${created.day}/${created.month}/${created.year} ${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}',
                                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    const SizedBox(width: 12),
                                    Icon(Icons.payment, size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                     Text(
                                      payment == 'cash'
                                          ? LocalizationService.tr('payment_cash')
                                          : LocalizationService.tr('payment_credit'),
                                      style: GoogleFonts.notoSansTamil(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Arrow
                        const Padding(
                           padding: EdgeInsets.only(right: 16),
                           child: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StatusMeta {
  final String labelKey;
  final String chipTextKey;
  final Color color;

  const _StatusMeta({
    required this.labelKey,
    required this.chipTextKey,
    required this.color,
  });
}

_StatusMeta _statusMeta(String status) {
  switch (status) {
    case 'ready':
      return const _StatusMeta(
        labelKey: 'status_ready_label',
        chipTextKey: 'status_ready',
        color: Colors.orange,
      );
    case 'picked':
      return const _StatusMeta(
        labelKey: 'status_picked_label',
        chipTextKey: 'status_picked',
        color: Colors.green,
      );
    case 'cancelled':
      return const _StatusMeta(
        labelKey: 'status_cancelled_label',
        chipTextKey: 'status_cancelled',
        color: Colors.red,
      );
    case 'reserved':
    default:
      return const _StatusMeta(
        labelKey: 'status_placed_label',
        chipTextKey: 'status_placed',
        color: Colors.blue,
      );
  }
}
