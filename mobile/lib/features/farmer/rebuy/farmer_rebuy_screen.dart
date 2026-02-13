import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import '../cart/cart_provider.dart';

class FarmerRebuyScreen extends StatelessWidget {
  const FarmerRebuyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          LocalizationService.tr('title_rebuy'),
          style: GoogleFonts.notoSansTamil(
            fontSize: 18,
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snapshot.data?.docs ?? [];
          // Client-side sorting to avoid Firestore Index creation
          docs = List.from(docs)..sort((a, b) {
             final t1 = a.data()['createdAt'] as Timestamp?;
             final t2 = b.data()['createdAt'] as Timestamp?;
             if (t1 == null && t2 == null) return 0;
             if (t1 == null) return 1;
             if (t2 == null) return -1;
             return t2.compareTo(t1); // Descending
          });
          
          if (docs.length > 20) {
             docs = docs.sublist(0, 20);
          }

          final Map<String, _RebuyItem> map = {};

          for (final doc in docs) {
            final data = doc.data();
            final items = (data['items'] as List<dynamic>? ?? []);
            for (final raw in items) {
              if (raw is! Map<String, dynamic>) continue;
              final pid = raw['productId'] as String?;
              if (pid == null) continue;
              final nameTa = raw['name_ta'] as String? ?? '';
              final nameEn = raw['name_en'] as String? ?? '';
              final unitTa = raw['unit_ta'] as String? ?? '';
              final unitEn = raw['unit_en'] as String? ?? '';
              final price = raw['price'] as num? ?? 0;
              final qty = (raw['quantity'] as num? ?? 0).toInt();

              if (!map.containsKey(pid)) {
                map[pid] = _RebuyItem(
                  productId: pid,
                  nameTa: nameTa,
                  nameEn: nameEn,
                  unitTa: unitTa,
                  unitEn: unitEn,
                  price: price,
                  totalQty: qty,
                  times: 1,
                );
              } else {
                final item = map[pid]!;
                item.totalQty += qty;
                item.times += 1;
              }
            }
          }

          final items = map.values.toList()
            ..sort((a, b) => b.totalQty.compareTo(a.totalQty));

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                         color: AppColors.primary.withOpacity(0.1),
                         shape: BoxShape.circle
                      ),
                      child: const Icon(Icons.history_outlined, size: 48, color: AppColors.primary),
                   ),
                   const SizedBox(height: 24),
                   Text(
                    LocalizationService.tr('msg_no_previous_orders'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansTamil(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                   const SizedBox(height: 24),
                   ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(), // Go back (likely to home)
                      style: ElevatedButton.styleFrom(
                         backgroundColor: AppColors.primary,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
                      ),
                      child: Text(
                         "Browse Shop",
                         style: GoogleFonts.poppins(fontWeight: FontWeight.bold)
                      )
                   )
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                     BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4)
                     )
                  ]
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.nameTa,
                            style: GoogleFonts.notoSansTamil(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary
                            ),
                          ),
                          if (item.nameEn.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.nameEn,
                              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Container(
                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                             decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8)
                             ),
                             child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                   Icon(Icons.repeat, size: 12, color: Colors.grey.shade600),
                                   const SizedBox(width: 4),
                                   Flexible(
                                     child: Text(
                                       '${LocalizationService.tr('label_ordered')} ${item.times} ${LocalizationService.tr('label_times')} · ${LocalizationService.tr('label_total')} ${item.totalQty} ${item.unitEn}',
                                       style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                                       overflow: TextOverflow.ellipsis,
                                     ),
                                   ),
                                ],
                             ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                       children: [
                          Text(
                             '₹${item.price.toStringAsFixed(0)}',
                             style: GoogleFonts.notoSansTamil(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              context.read<CartProvider>().addItem(
                                    productId: item.productId,
                                    nameTa: item.nameTa,
                                    nameEn: item.nameEn,
                                    price: item.price,
                                    unitTa: item.unitTa,
                                    unitEn: item.unitEn,
                                  );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    LocalizationService.tr('snackbar_added_to_cart'),
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                               backgroundColor: AppColors.primary,
                               elevation: 0,
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                               minimumSize: Size.zero,
                               tapTargetSize: MaterialTapTargetSize.shrinkWrap
                            ),
                            child: Text(
                              LocalizationService.tr('btn_rebuy'),
                              style: GoogleFonts.notoSansTamil(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                       ],
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _RebuyItem {
  final String productId;
  final String nameTa;
  final String nameEn;
  final String unitTa;
  final String unitEn;
  final num price;
  int totalQty;
  int times;

  _RebuyItem({
    required this.productId,
    required this.nameTa,
    required this.nameEn,
    required this.unitTa,
    required this.unitEn,
    required this.price,
    required this.totalQty,
    required this.times,
  });
}
