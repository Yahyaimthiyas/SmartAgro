import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import '../cart/cart_provider.dart';
import '../products/farmer_product_details_screen.dart';

class FarmerCropDetailsScreen extends StatelessWidget {
  final String cropId;

  const FarmerCropDetailsScreen({super.key, required this.cropId});

  // Estimated crop duration in days
  int _getEstimatedDuration(String cropType) {
    switch (cropType.toLowerCase()) {
      case 'sugarcane': return 365;
      case 'cotton': return 160;
      case 'maize': return 100;
      case 'groundnut': return 110;
      case 'rice':
      case 'paddy':
        return 120;
      default: return 120;
    }
  }

  String _getCropImage(String cropType) {
    switch (cropType.toLowerCase()) {
      case 'sugarcane': return 'assets/images/crops/sugarcane.png';
      case 'cotton': return 'assets/images/crops/cotton.png';
      case 'maize': return 'assets/images/crops/maize.png';
      case 'groundnut': return 'assets/images/crops/groundnut.png';
      case 'rice':
      case 'paddy':
        return 'assets/images/crops/rice.png';
      default: return 'assets/images/crops/rice.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance.collection('crops').doc(cropId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    LocalizationService.tr('cropdetails_not_found'),
                    style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(LocalizationService.tr('label_go_back')),
                  )
                ],
              ),
            );
          }

          final data = snapshot.data!.data()!;
          final cropTypeId = data['cropTypeId'] as String? ?? '';
          final area = (data['area'] as num?)?.toDouble() ?? 0;
          final areaUnit = (data['areaUnit'] as String?) ?? 'acres';
          final ts = data['sowingDate'] as Timestamp?;
          final sowingDate = ts?.toDate();
          final now = DateTime.now();
          final daysOld = sowingDate != null ? now.difference(sowingDate).inDays : 0;
          
          final cropLabel = LocalizationService.tr('crop_${cropTypeId.isEmpty ? 'rice' : cropTypeId}_label');
          final imageAsset = _getCropImage(cropTypeId);
          final duration = _getEstimatedDuration(cropTypeId);
          final progress = (daysOld / duration).clamp(0.0, 1.0);
          final remainingDays = (duration - daysOld).clamp(0, duration);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 240.0,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: AppColors.primary,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const BackButton(color: AppColors.textPrimary),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding: const EdgeInsets.only(bottom: 16),
                  title: Text(
                    cropLabel,
                    style: GoogleFonts.notoSansTamil(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                      shadows: [
                        const Shadow(offset: Offset(0, 1), blurRadius: 4, color: Colors.black45)
                      ],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Image.asset(
                          imageAsset,
                          fit: BoxFit.contain,
                          errorBuilder: (_,__,___) => const Icon(Icons.grass, size: 80, color: Colors.white24),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.primaryDark.withOpacity(0.8),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.timer_outlined, color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  LocalizationService.tr('label_crop_cycle'),
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "$daysOld / $duration ${LocalizationService.tr('label_days')}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 12,
                                backgroundColor: Colors.grey.shade100,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progress > 0.8 ? Colors.green : AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              remainingDays <= 0 
                                  ? LocalizationService.tr('msg_ready_for_harvest') 
                                  : "${LocalizationService.tr('label_harvest_in')} $remainingDays ${LocalizationService.tr('label_days')}",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: remainingDays <= 0 ? Colors.green : AppColors.textSecondary,
                                fontWeight: remainingDays <= 0 ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),

                      // Key Stats Grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.5,
                        children: [
                          _buildStatCard(
                            title: LocalizationService.tr('crop_unit_${areaUnit == 'hectares' ? 'hectares' : 'acres'}'),
                            value: area.toStringAsFixed(1),
                            icon: Icons.landscape_outlined,
                            color: Colors.blue,
                          ),
                          _buildStatCard(
                            title: LocalizationService.tr('label_sowing_date'),
                            value: sowingDate != null 
                                ? "${sowingDate.day}/${sowingDate.month}/${sowingDate.year}"
                                : "-",
                            icon: Icons.calendar_today_outlined,
                            color: Colors.orange,
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      _buildRecommendationsSection(
                        context: context,
                        cropId: cropId,
                        cropTypeId: cropTypeId,
                        daysOld: daysOld,
                      ),
                      
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

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection({
    required BuildContext context,
    required String cropId,
    required String cropTypeId,
    required int daysOld,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
                       LocalizationService.tr('cropdetails_recommended_products_title'),
                       style: GoogleFonts.notoSansTamil(
                         fontSize: 18,
                         fontWeight: FontWeight.bold,
                         color: AppColors.textPrimary,
                       ),
                     ),
                     Text(
                       LocalizationService.tr('label_based_on_stage'),
                       style: GoogleFonts.poppins(
                         fontSize: 12,
                         color: AppColors.textSecondary
                       ),
                     ),
                   ],
                 ),
               ),
            ],
         ),
        const SizedBox(height: 16),
        FutureBuilder<List<_RecommendedProduct>>(
          future: _loadRecommendations(cropTypeId, daysOld),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final items = snapshot.data ?? const [];

            if (items.isEmpty) {
              return Container(
                 width: double.infinity,
                 padding: const EdgeInsets.all(32),
                 decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200)
                 ),
                 child: Column(
                    children: [
                       const Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
                       const SizedBox(height: 16),
                       Text(
                         LocalizationService.tr('cropdetails_no_recommendations'),
                         style: GoogleFonts.notoSansTamil(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                         textAlign: TextAlign.center,
                       ),
                    ],
                 ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildRecommendedCard(context, cropId, item);
              },
            );
          },
        ),
      ],
    );
  }

  Future<List<_RecommendedProduct>> _loadRecommendations(String cropTypeId, int daysOld) async {
    if (cropTypeId.isEmpty) return const [];

    final now = DateTime.now();
    final month = now.month;

    final recSnap = await FirebaseFirestore.instance
        .collection('crop_recommendations')
        .where('cropTypeId', isEqualTo: cropTypeId)
        .get();

    final List<_RecommendedProduct> results = [];

    for (final doc in recSnap.docs) {
      final data = doc.data();
      final minDays = (data['minDays'] as num?)?.toInt();
      final maxDays = (data['maxDays'] as num?)?.toInt();
      final seasonStart = (data['seasonStartMonth'] as num?)?.toInt();
      final seasonEnd = (data['seasonEndMonth'] as num?)?.toInt();
      final productId = data['productId'] as String?;

      if (productId == null) continue;

      // Age filter
      if (minDays != null && daysOld < minDays) continue;
      if (maxDays != null && daysOld > maxDays) continue;

      // Season filter (if configured)
      if (seasonStart != null && seasonEnd != null) {
        final inRange = seasonStart <= seasonEnd
            ? (month >= seasonStart && month <= seasonEnd)
            : (month >= seasonStart || month <= seasonEnd);
        if (!inRange) continue;
      }

      final prodSnap = await FirebaseFirestore.instance.collection('products').doc(productId).get();
      if (!prodSnap.exists) continue;
      final p = prodSnap.data()!;

      results.add(
        _RecommendedProduct(
          productId: productId,
          nameTa: p['name_ta'] as String? ?? '',
          nameEn: p['name_en'] as String? ?? '',
          price: p['price'] as num? ?? 0,
          unitTa: p['unit_ta'] as String? ?? '',
          unitEn: p['unit_en'] as String? ?? '',
          imageUrl: p['imageUrl'] as String?,
          purposeTa: data['purpose_ta'] as String? ?? '',
          purposeEn: data['purpose_en'] as String? ?? '',
          dosageTa: data['dosage_ta'] as String? ?? '',
          dosageEn: data['dosage_en'] as String? ?? '',
        ),
      );
    }

    return results;
  }

  Widget _buildRecommendedCard(BuildContext context, String cropId, _RecommendedProduct item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
           BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)
           )
        ]
      ),
      padding: const EdgeInsets.all(12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product Image
            ClipRRect(
               borderRadius: BorderRadius.circular(20),
               child: Container(
                 width: 100,
                 color: AppColors.primaryLight,
                 child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                     ? Image.network(item.imageUrl!, fit: BoxFit.cover)
                     : const Center(child: Icon(Icons.local_florist_outlined, color: AppColors.primaryDark, size: 32)),
               ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     // Title
                    Text(
                      item.nameTa,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                    
                    const Spacer(),
                    
                    if (item.purposeTa.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                         decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8)
                         ),
                         child: Text(
                           item.purposeTa,
                           maxLines: 1,
                           overflow: TextOverflow.ellipsis,
                           style: GoogleFonts.notoSansTamil(fontSize: 11, color: Colors.blue.shade800, fontWeight: FontWeight.w600),
                         ),
                      ),
                    ],
        
                    const SizedBox(height: 12),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${item.price.toStringAsFixed(0)}',
                              style: GoogleFonts.notoSansTamil(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                           height: 36,
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
                                  content: Text(
                                    LocalizationService.tr('snackbar_added_to_cart'),
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            child: Text(
                              LocalizationService.tr('btn_add_to_cart'),
                              style: GoogleFonts.notoSansTamil(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendedProduct {
  final String productId;
  final String nameTa;
  final String nameEn;
  final num price;
  final String unitTa;
  final String unitEn;
  final String? imageUrl;
  final String purposeTa;
  final String purposeEn;
  final String dosageTa;
  final String dosageEn;

  _RecommendedProduct({
    required this.productId,
    required this.nameTa,
    required this.nameEn,
    required this.price,
    required this.unitTa,
    required this.unitEn,
    required this.imageUrl,
    required this.purposeTa,
    required this.purposeEn,
    required this.dosageTa,
    required this.dosageEn,
  });
}

