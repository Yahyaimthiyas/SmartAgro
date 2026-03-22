import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/widgets/common_image.dart';
import '../../../../core/utils/price_utils.dart';
import '../../cart/cart_provider.dart';
import '../farmer_product_details_screen.dart';

class ProductGridCard extends StatelessWidget {
  final String productId;
  final Map<String, dynamic> data;

  const ProductGridCard({
    super.key,
    required this.productId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final isTa = LocalizationService.isTamil;
    
    final nameTa = data['name_ta'] as String? ?? '';
    final nameEn = data['name_en'] as String? ?? '';
    final price = data['price'] as num? ?? 0;
    final unitTa = data['unit_ta'] as String? ?? '';
    final unitEn = data['unit_en'] as String? ?? '';
    final stock = data['stock'] as int? ?? 0;
    final offerPercent = data['offerPercent'] as num?;

    final displayName = LocalizationService.pickTaEn(nameTa, nameEn);
    final displayUnit = LocalizationService.pickTaEn(unitTa, unitEn);
    
    bool isStockOut = stock <= 0;
    
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FarmerProductDetailsScreen(productId: productId),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
             BoxShadow(
               color: Colors.black.withOpacity(0.04),
               blurRadius: 12,
               offset: const Offset(0, 4),
             ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             // Image Section (simulating the grey placeholder in the UI if no image)
             Expanded(
                child: Stack(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty) 
                          ? CommonImage(
                              imageUrl: data['imageUrl'] as String,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: const Color(0xFFEEEEEE),
                              child: const Center(child: Icon(Icons.image_outlined, color: Colors.grey, size: 32)),
                            ),
                      ),
                    ),
                    if (offerPercent != null && offerPercent > 0)
                      Positioned(
                        top: 8, left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.googleRed,
                            borderRadius: BorderRadius.circular(4)
                          ),
                          child: Text(
                            '${offerPercent.toInt()}% OFF',
                            style: GoogleFonts.inter(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                  ],
                ),
             ),
             
             // Content Section
             Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      Text(
                         displayName.isEmpty ? 'Product Name' : displayName,
                         style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF222222)),
                         maxLines: 1,
                         overflow: TextOverflow.ellipsis,
                      ),
                      if (displayUnit.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                           displayUnit,
                           style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                      const SizedBox(height: 6),
                      
                      // Price (Green)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: PriceUtils.isOfferActuallyActive(data) ? Row(
                          children: [
                            Text(
                              '₹${data['price']}',
                              style: GoogleFonts.inter(fontSize: 10, decoration: TextDecoration.lineThrough, color: Colors.grey.shade500),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '₹${PriceUtils.calculateFinalPrice(data).toStringAsFixed(0)}',
                               style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                            ),
                          ],
                        ) : Text(
                           '₹$price',
                           style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                        ),
                      ),
                      
                      const SizedBox(height: 10),
                      
                      // Full width Add to Cart Button
                      SizedBox(
                        width: double.infinity,
                        height: 32,
                        child: ElevatedButton(
                           onPressed: isStockOut ? null : () {
                              context.read<CartProvider>().addItem(
                                 productId: productId,
                                 nameTa: nameTa,
                                 nameEn: nameEn,
                                 price: PriceUtils.calculateFinalPrice(data),
                                 unitTa: unitTa,
                                 unitEn: unitEn,
                                 imageUrl: data['imageUrl'] as String?,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(LocalizationService.tr('snackbar_added_to_cart')),
                                  duration: const Duration(milliseconds: 800),
                                  behavior: SnackBarBehavior.floating,
                                  shape: const StadiumBorder(),
                                ),
                              );
                           },
                           style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF5F5F7), // Light grey
                              foregroundColor: const Color(0xFF333333),
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                           ),
                           child: Text(
                             isTa ? 'கார்ட்டில் சேர்' : 'Add to Cart', 
                             style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
                           ),
                        ),
                      )
                   ],
                ),
             )
          ],
        ),
      ),
    );
  }
}
