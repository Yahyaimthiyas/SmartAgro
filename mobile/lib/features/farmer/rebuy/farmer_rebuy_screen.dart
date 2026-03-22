import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import '../../../core/widgets/common_image.dart';
import '../cart/cart_provider.dart';

class FarmerRebuyScreen extends StatelessWidget {
  const FarmerRebuyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isTa = LocalizationService.isTamil;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isTa ? 'மீண்டும் வாங்க' : 'Rebuy Again',
          style: GoogleFonts.outfit(
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snapshot.data?.docs ?? [];
          // Client-side sorting and limiting to top 30 orders for frequency analysis
          docs = List.from(docs)..sort((a, b) {
             final t1 = a.data()['createdAt'] as Timestamp?;
             final t2 = b.data()['createdAt'] as Timestamp?;
             if (t1 == null || t2 == null) return 0;
             return t2.compareTo(t1);
          });
          
          if (docs.length > 30) docs = docs.sublist(0, 30);

          final Map<String, _RebuyItem> map = {};

          for (final doc in docs) {
            final data = doc.data();
            final items = (data['items'] as List<dynamic>? ?? []);
            for (final raw in items) {
              if (raw is! Map<String, dynamic>) continue;
              final pid = raw['productId'] as String?;
              if (pid == null) continue;
              
              if (!map.containsKey(pid)) {
                map[pid] = _RebuyItem(
                  productId: pid,
                  nameTa: raw['name_ta'] as String? ?? '',
                  nameEn: raw['name_en'] as String? ?? '',
                  unitTa: raw['unit_ta'] as String? ?? '',
                  unitEn: raw['unit_en'] as String? ?? '',
                  price: raw['price'] as num? ?? 0,
                  imageUrl: raw['imageUrl'] as String?,
                  totalQty: (raw['quantity'] as num? ?? 0).toInt(),
                  times: 1,
                );
              } else {
                final item = map[pid]!;
                item.totalQty += (raw['quantity'] as num? ?? 0).toInt();
                item.times += 1;
              }
            }
          }

          final items = map.values.toList()
            ..sort((a, b) => b.times.compareTo(a.times)); // Sort by frequency

          if (items.isEmpty) {
            return _buildEmptyState(isTa, context);
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _buildRebuyCard(items[index], isTa, context),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isTa, BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            isTa ? 'முந்தைய ஆர்டர்கள் எதுவும் இல்லை' : 'No previous orders yet',
            style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(isTa ? 'தயாரிப்புகளைக் காண்க' : 'Browse Products', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRebuyCard(_RebuyItem item, bool isTa, BuildContext context) {
    final displayName = isTa ? item.nameTa : item.nameEn;
    final displayUnit = isTa ? item.unitTa : item.unitEn;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                  ? CommonImage(imageUrl: item.imageUrl!, fit: BoxFit.cover)
                  : const Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 32),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.times >= 3)
                   Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                         color: Colors.orange.shade50,
                         borderRadius: BorderRadius.circular(4),
                         border: Border.all(color: Colors.orange.shade200)
                      ),
                      child: Text(
                        isTa ? 'அடிக்கடி வாங்கியது' : 'FREQUENTLY BOUGHT',
                        style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                      ),
                   ),
                Text(
                  displayName.isEmpty ? 'Product' : displayName,
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF222222)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  displayUnit,
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${item.price.toStringAsFixed(0)}',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Rebuy Action
          Column(
            children: [
               Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${item.times}x',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
               ),
               const SizedBox(height: 12),
               SizedBox(
                 height: 32,
                 child: ElevatedButton(
                    onPressed: () {
                      context.read<CartProvider>().addItem(
                        productId: item.productId,
                        nameTa: item.nameTa,
                        nameEn: item.nameEn,
                        price: item.price,
                        unitTa: item.unitTa,
                        unitEn: item.unitEn,
                        imageUrl: item.imageUrl,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isTa ? 'கார்ட்டில் சேர்க்கப்பட்டது!' : 'Added to Cart!'),
                          duration: const Duration(milliseconds: 800),
                          behavior: SnackBarBehavior.floating,
                          shape: const StadiumBorder(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F3F4),
                      foregroundColor: const Color(0xFF333333),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      isTa ? 'வாங்கு' : 'Rebuy', 
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
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

class _RebuyItem {
  final String productId;
  final String nameTa;
  final String nameEn;
  final String unitTa;
  final String unitEn;
  final num price;
  final String? imageUrl;
  int totalQty;
  int times;

  _RebuyItem({
    required this.productId,
    required this.nameTa,
    required this.nameEn,
    required this.unitTa,
    required this.unitEn,
    required this.price,
    this.imageUrl,
    required this.totalQty,
    required this.times,
  });
}
