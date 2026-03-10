import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/widgets/common_image.dart';
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
    
    // Stock Logic
    bool isStockOut = stock <= 0;
    bool isLowStock = stock > 0 && stock <= 5;
    
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FarmerProductDetailsScreen(productId: productId),
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
                offset: const Offset(0, 4)
             )
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             // Image Section
             Expanded(
                child: Container(
                   width: double.infinity,
                   decoration: const BoxDecoration(
                      color: Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                   ),
                   child: Stack(
                      children: [
                         SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            child: CommonImage(
                               imageUrl: (data['imageUrl'] as String?) ?? '',
                               fit: BoxFit.cover,
                               borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                         ),
                         
                         if (offerPercent != null && offerPercent > 0)
                            Positioned(
                               top: 10, left: 10,
                               child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                     color: Colors.red,
                                     borderRadius: BorderRadius.circular(8)
                                  ),
                                  child: Text(
                                     '${offerPercent.toInt()}% OFF',
                                     style: GoogleFonts.poppins(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                               ),
                            )
                      ],
                   ),
                ),
             ),
             
             // Content Section
             Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      // Name
                      Text(
                         displayName,
                         style: isTa 
                           ? GoogleFonts.notoSansTamil(fontSize: 14, fontWeight: FontWeight.bold, height: 1.2)
                           : GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, height: 1.2),
                         maxLines: 1,
                         overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                         '$displayUnit',
                         style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 8),
                      
                      // Price & Action
                      Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                            Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                  if (data['isOfferActive'] == true) ...[
                                    Text(
                                      '₹${data['price']}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      '₹${_calculateOfferPrice(data).toStringAsFixed(0)}',
                                       style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                                    ),
                                  ] else
                                    Text(
                                       '₹$price',
                                       style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                                    ),

                                  if (isStockOut)
                                     Text(
                                        LocalizationService.tr('stock_out_en'),
                                        style: GoogleFonts.poppins(fontSize: 10, color: Colors.red, fontWeight: FontWeight.w600),
                                     )
                                  else if (isLowStock)
                                     Text(
                                        'Low Stock',
                                        style: GoogleFonts.poppins(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.w600),
                                     )
                               ],
                            ),
                            
                            InkWell(
                               onTap: isStockOut ? null : () {
                                  context.read<CartProvider>().addItem(
                                     productId: productId,
                                     nameTa: nameTa,
                                     nameEn: nameEn,
                                     price: _calculateOfferPrice(data),
                                     unitTa: unitTa,
                                     unitEn: unitEn,
                                     imageUrl: data['imageUrl'] as String?,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(LocalizationService.tr('snackbar_added_to_cart')),
                                      duration: const Duration(milliseconds: 800),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                               },
                               child: Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(
                                     color: isStockOut ? Colors.grey.shade300 : AppColors.primary,
                                     borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.add, color: Colors.white, size: 18),
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

  double _calculateOfferPrice(Map<String, dynamic> data) {
    final price = (data['price'] as num? ?? 0).toDouble();
    final isOfferActive = data['isOfferActive'] as bool? ?? false;
    
    if (!isOfferActive) return price;

    final offerType = data['offerType'] as String? ?? 'percentage';
    final offerValue = (data['offerValue'] as num? ?? 0).toDouble();

    if (offerType == 'percentage') {
      final discount = (price * offerValue) / 100;
      final finalPrice = price - discount;
      return finalPrice < 0 ? 0 : finalPrice;
    } else {
       return offerValue; // Flat price
    }
  }
}
