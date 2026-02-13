import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../core/widgets/common_image.dart'; // [NEW]
import '../../../core/services/localization_service.dart';
import '../cart/cart_provider.dart';
import '../dosage/dosage_calculator_screen.dart';

class FarmerProductDetailsScreen extends StatefulWidget {
  final String productId;
  final String? cropId;

  const FarmerProductDetailsScreen({
    super.key,
    required this.productId,
    this.cropId,
  });

  @override
  State<FarmerProductDetailsScreen> createState() => _FarmerProductDetailsScreenState();
}

class _FarmerProductDetailsScreenState extends State<FarmerProductDetailsScreen>
    with SingleTickerProviderStateMixin {
  int _quantity = 1;
  int _selectedTabIndex = 0;
  
  // Cache the product data to prevent reloading on tab switches
  Map<String, dynamic>? _cachedProductData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProductData();
  }

  Future<void> _loadProductData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .get();
      
      if (mounted) {
        setState(() {
          _cachedProductData = doc.exists ? doc.data() : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTa = LocalizationService.isTamil;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cachedProductData == null
              ? Center(
                  child: Text(
                    LocalizationService.tr('msg_product_not_found'),
                    style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textSecondary),
                  ),
                )
              : _buildProductContent(_cachedProductData!, isTa),
    );
  }

  Widget _buildProductContent(Map<String, dynamic> data, bool isTa) {
    final nameTa = data['name_ta'] as String? ?? '';
    final nameEn = data['name_en'] as String? ?? '';
    final price = data['price'] as num? ?? 0;
    final unitTa = data['unit_ta'] as String? ?? '';
    final unitEn = data['unit_en'] as String? ?? '';
    final stock = data['stock'] as int? ?? 0;
    final imageUrl = data['imageUrl'] as String?;
    final descriptionTa = data['description_ta'] as String? ?? '';
    final descriptionEn = data['description_en'] as String? ?? '';
    final dosageTa = data['dosage_ta'] as String? ?? '';
    final dosageEn = data['dosage_en'] as String? ?? '';
    final safetyTa = data['safety_ta'] as String? ?? '';
    final safetyEn = data['safety_en'] as String? ?? '';

    String stockLabelTa;
    String stockLabelEn;
    Color stockColor;
    Color stockBgColor;
    
    if (stock <= 0) {
      stockLabelTa = LocalizationService.tr('stock_out_ta');
      stockLabelEn = LocalizationService.tr('stock_out_en');
      stockColor = Colors.red;
      stockBgColor = Colors.red.shade50;
    } else if (stock <= 3) {
      stockLabelTa = LocalizationService.tr('stock_low_ta');
      stockLabelEn = LocalizationService.tr('stock_low_en');
      stockColor = Colors.orange;
      stockBgColor = Colors.orange.shade50;
    } else {
      stockLabelTa = LocalizationService.tr('stock_in_ta');
      stockLabelEn = LocalizationService.tr('stock_in_en');
      stockColor = Colors.green;
      stockBgColor = Colors.green.shade50;
    }

    final displayName = LocalizationService.pickTaEn(nameTa, nameEn);
    final displayUnit = LocalizationService.pickTaEn(unitTa, unitEn);
    final stockText = isTa ? stockLabelTa : stockLabelEn;
    
    // [NEW] Privacy: Hide exact count, just show status
    final stockDisplay = stockText; 

    double finalPrice = price.toDouble();
    bool isOfferActive = data['isOfferActive'] as bool? ?? false;
    if (isOfferActive) {
      final offerType = data['offerType'] as String? ?? 'percentage';
      final offerValue = (data['offerValue'] as num? ?? 0).toDouble();
      if (offerType == 'percentage') {
         final discount = (price * offerValue) / 100;
         finalPrice = price - discount;
      } else {
         finalPrice = offerValue;
      }
      if (finalPrice < 0) finalPrice = 0;
    }

    final maxQty = stock > 0 ? stock : 1;
    // Only reset quantity if it exceeds max, don't reset to 1 on rebuild if valid
    if (_quantity > maxQty) _quantity = maxQty;

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
             SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                 icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
                 onPressed: () => Navigator.of(context).pop(),
                 style: IconButton.styleFrom(
                   backgroundColor: Colors.white.withOpacity(0.8),
                   shape: const CircleBorder(),
                 ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: imageUrl != null && imageUrl.isNotEmpty
                    ? CommonImage( // [NEW] Use CommonImage
                        imageUrl: imageUrl, // Handles Base64 & Network
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Colors.grey[100],
                        child: const Icon(Icons.image_outlined, size: 80, color: Colors.grey),
                      ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                transform: Matrix4.translationValues(0, -20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: isTa
                                ? GoogleFonts.notoSansTamil(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  )
                                : GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                         Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: stockBgColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            stockDisplay, // Privacy update
                            style: isTa
                                ? GoogleFonts.notoSansTamil(
                                    fontSize: 12,
                                    color: stockColor,
                                    fontWeight: FontWeight.bold,
                                  )
                                : GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: stockColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                          ),
                        ),
                        const Spacer(),
                        
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (isOfferActive)
                              Text(
                                '₹$price',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                ),
                              ),
                            Text(
                              '₹${finalPrice.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: isOfferActive ? Colors.green.shade700 : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '/ $displayUnit',
                          style: isTa
                              ? GoogleFonts.notoSansTamil(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                )
                              : GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    const SizedBox(height: 32),
                    
                    // [MODERNIZED] Custom Animated Tab Bar
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          _buildTabItem(0, LocalizationService.tr('tab_description')),
                          _buildTabItem(1, LocalizationService.tr('tab_dosage')),
                          _buildTabItem(2, LocalizationService.tr('tab_safety')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // [DYNAMIC CONTENT] No fixed height - INSTANT SWITCHING
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      switchInCurve: Curves.easeInOut,
                      switchOutCurve: Curves.easeInOut,
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey<int>(_selectedTabIndex),
                        child: _buildTabContent(
                          descriptionTa: descriptionTa,
                          descriptionEn: descriptionEn,
                          dosageTa: dosageTa,
                          dosageEn: dosageEn,
                          safetyTa: safetyTa,
                          safetyEn: safetyEn,
                          isTa: isTa,
                        ),
                      ),
                    ),
                     // Padding for bottom bar
                     const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
        
        // [MODERNIZED] Bottom Bar
        Positioned(
           left: 0, 
           right: 0, 
           bottom: 0,
           child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                   BoxShadow(
                     color: Colors.black.withOpacity(0.08),
                     blurRadius: 20,
                     offset: const Offset(0, -4),
                   ),
                ],
              ),
              child: SafeArea(
                 child: Row(
                   children: [
                     // Quantity Selector
                     Container(
                       decoration: BoxDecoration(
                         color: Colors.grey[100],
                         borderRadius: BorderRadius.circular(16),
                         border: Border.all(color: Colors.grey[200]!),
                       ),
                       padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                       child: Row(
                         children: [
                           _qtyButton(
                             icon: Icons.remove, 
                             onTap: () {
                               if (_quantity > 1) setState(() => _quantity--);
                             }
                           ),
                           SizedBox(
                             width: 40,
                             child: Text(
                               '$_quantity',
                               textAlign: TextAlign.center,
                               style: GoogleFonts.poppins(
                                 fontSize: 18, 
                                 fontWeight: FontWeight.bold
                               ),
                             ),
                           ),
                           _qtyButton(
                             icon: Icons.add, 
                             onTap: () {
                                // Note: Max stock check is done in build(), but good to check here too if possible
                                setState(() => _quantity++); 
                             }
                           ),
                         ],
                       ),
                     ),
                     const SizedBox(width: 16),
                     
                     // Add to Cart Button
                     Expanded(
                       child: SizedBox(
                         height: 56,
                         child: ElevatedButton(
                           onPressed: stock <= 0
                               ? null
                               : () {
                                   context.read<CartProvider>().addItem(
                                         productId: widget.productId,
                                         nameTa: nameTa,
                                         nameEn: nameEn,
                                         price: finalPrice,
                                         unitTa: unitTa,
                                         unitEn: unitEn,
                                         imageUrl: imageUrl,
                                         quantity: _quantity,
                                       );
                                   ScaffoldMessenger.of(context).showSnackBar(
                                     SnackBar(
                                       content: Text(
                                         LocalizationService.tr('snackbar_added_to_cart'),
                                         style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.w600),
                                       ),
                                       backgroundColor: Colors.green.shade800,
                                       behavior: SnackBarBehavior.floating,
                                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                       margin: const EdgeInsets.all(16),
                                     ),
                                   );
                                 },
                           style: ElevatedButton.styleFrom(
                             backgroundColor: AppColors.primary,
                             foregroundColor: Colors.white,
                             elevation: 4,
                             shadowColor: AppColors.primary.withOpacity(0.4),
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                           ),
                           child: Text(
                             LocalizationService.tr('btn_add_to_cart'),
                             style: GoogleFonts.notoSansTamil(
                               fontSize: 18,
                               fontWeight: FontWeight.bold,
                             ),
                           ),
                         ),
                       ),
                     ),
                   ],
                 ),
              ),
           ),
        ),
      ],
    );
  }

  Widget _buildInfoText(String ta, String en, bool isTa) {
    final text = LocalizationService.pickTaEn(ta, en);
    if (text.isEmpty) {
      return Center(
        child: Text(
          LocalizationService.tr('msg_info_coming_soon'),
          style: GoogleFonts.poppins(color: AppColors.textSecondary),
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        text,
        style: isTa 
           ? GoogleFonts.notoSansTamil(fontSize: 14, height: 1.6, color: AppColors.textPrimary)
           : GoogleFonts.poppins(fontSize: 14, height: 1.6, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildDosageTab(String ta, String en, bool isTa) {
     return Column(
       children: [
         _buildInfoText(ta, en, isTa),
         const SizedBox(height: 12),
         SizedBox(
           width: double.infinity,
           height: 48,
           child: OutlinedButton(
             onPressed: () {
               Navigator.of(context).push(
                 MaterialPageRoute(
                   builder: (_) => DosageCalculatorScreen(
                     productId: widget.productId,
                     cropId: widget.cropId,
                   ),
                 ),
               );
             },
             style: OutlinedButton.styleFrom(
               side: const BorderSide(color: AppColors.primary),
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
             ),
             child: Text(
               LocalizationService.tr('dosage_calc_btn_for_my_land'),
               style: GoogleFonts.notoSansTamil(
                 fontSize: 14,
                 fontWeight: FontWeight.bold,
                 color: AppColors.primary,
               ),
             ),
           ),
         ),
       ],
     );
  }

  Widget _buildTabItem(int index, String title) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: isSelected
                ? GoogleFonts.notoSansTamil(
                    fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)
                : GoogleFonts.notoSansTamil(
                    fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent({
    required String descriptionTa,
    required String descriptionEn,
    required String dosageTa,
    required String dosageEn,
    required String safetyTa,
    required String safetyEn,
    required bool isTa,
  }) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildInfoText(descriptionTa, descriptionEn, isTa);
      case 1:
        return _buildDosageTab(dosageTa, dosageEn, isTa);
      case 2:
        return _buildInfoText(safetyTa, safetyEn, isTa);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _qtyButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
