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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             // Image Section
             Expanded(
                child: Stack(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: CommonImage(
                           imageUrl: (data['imageUrl'] as String?) ?? '',
                           fit: BoxFit.cover,
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
                         displayName,
                         style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                         maxLines: 1,
                         overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                         displayUnit,
                         style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      
                      Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                            Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                  if (PriceUtils.isOfferActuallyActive(data)) ...[
                                    Text(
                                      '₹${data['price']}',
                                      style: GoogleFonts.inter(fontSize: 10, decoration: TextDecoration.lineThrough, color: AppColors.textPlaceholder),
                                    ),
                                    Text(
                                      '₹${PriceUtils.calculateFinalPrice(data).toStringAsFixed(0)}',
                                       style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ] else
                                    Text(
                                       '₹$price',
                                       style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                               ],
                            ),
                            
                            IconButton.filledTonal(
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
                               icon: const Icon(Icons.add, size: 18),
                               style: IconButton.styleFrom(
                                  backgroundColor: isStockOut ? Colors.grey.shade100 : AppColors.primaryContainer,
                                  foregroundColor: AppColors.primary,
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(32, 32),
                               ),
                            )
                         ],
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
