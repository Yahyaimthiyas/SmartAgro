import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../core/widgets/common_image.dart';
import '../../../core/services/localization_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../cart/cart_provider.dart';
import '../checkout/farmer_checkout_screen.dart';
import '../profile/farmer_profile_setup_screen.dart';

class FarmerCartScreen extends StatelessWidget {
  const FarmerCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

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
          LocalizationService.tr('title_cart'),
          style: GoogleFonts.notoSansTamil(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    LocalizationService.tr('msg_cart_empty'),
                    style: GoogleFonts.notoSansTamil(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Container(
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
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                             // Thumbnail
                             Container(
                               width: 70,
                               height: 70,
                               decoration: BoxDecoration(
                                 color: AppColors.primaryLight.withOpacity(0.5),
                                 borderRadius: BorderRadius.circular(16),
                               ),
                               child: item.imageUrl != null 
                                  ? CommonImage(imageUrl: item.imageUrl, fit: BoxFit.cover, borderRadius: BorderRadius.circular(16))
                                  : const Icon(Icons.spa, color: AppColors.primary, size: 30),
                             ),

                             const SizedBox(width: 16),
                             // Info
                             Expanded(
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Text(
                                     item.nameTa,
                                     style: GoogleFonts.notoSansTamil(
                                       fontSize: 15,
                                       fontWeight: FontWeight.bold,
                                       color: AppColors.textPrimary,
                                     ),
                                     maxLines: 1,
                                     overflow: TextOverflow.ellipsis,
                                   ),
                                   if (item.nameEn.isNotEmpty) 
                                     Text(
                                       item.nameEn,
                                       style: GoogleFonts.poppins(
                                         fontSize: 12,
                                         color: AppColors.textSecondary,
                                       ),
                                       maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                     ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '₹${item.price.toStringAsFixed(0)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                 ],
                               ),
                             ),
                             // Controls
                             Column(
                               children: [
                                  Row(
                                    children: [
                                      _qtyBtn(
                                        icon: Icons.remove,
                                        onTap: () {
                                          final newQty = item.quantity - 1;
                                          context.read<CartProvider>().updateQuantity(item.productId, newQty);
                                        }
                                      ),
                                      Container(
                                        width: 32,
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${item.quantity}',
                                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ),
                                      _qtyBtn(
                                        icon: Icons.add,
                                        onTap: () {
                                          final newQty = item.quantity + 1;
                                          context.read<CartProvider>().updateQuantity(item.productId, newQty);
                                        }
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                               ],
                             )
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                // Bottom Summary
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            LocalizationService.tr('label_total'),
                            style: GoogleFonts.notoSansTamil(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '₹${cart.totalAmount.toStringAsFixed(0)}',
                            style: GoogleFonts.notoSansTamil(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: cart.items.isEmpty
                            ? null
                            : () async {
                                final user = context.read<firebase_auth.User?>();
                                if (user != null) {
                                  final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                                  final data = doc.data();
                                  final hasAddress = data?['hasAddress'] == true;
                                  
                                  if (!hasAddress && context.mounted) {
                                     showDialog(
                                       context: context,
                                       builder: (context) => AlertDialog(
                                          title: Text(LocalizationService.tr('title_address_required') ?? "Address Required"),
                                          content: Text(LocalizationService.tr('msg_address_required') ?? "We need your delivery address to proceed with the order."),
                                          actions: [
                                             TextButton(
                                               onPressed: () => Navigator.pop(context),
                                               child: const Text("Cancel"),
                                             ),
                                             ElevatedButton(
                                               onPressed: () {
                                                  Navigator.pop(context);
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                       builder: (_) => const FarmerProfileSetupScreen(mode: ProfileSetupMode.full)
                                                    )
                                                  );
                                               },
                                               child: const Text("Add Address"),
                                             )
                                          ],
                                       )
                                     );
                                     return;
                                  }
                                }
                                
                                if (context.mounted) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const FarmerCheckoutScreen(),
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                           backgroundColor: AppColors.primary,
                           padding: const EdgeInsets.symmetric(vertical: 18),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                           elevation: 4,
                           shadowColor: AppColors.primary.withOpacity(0.4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              LocalizationService.tr('btn_proceed_to_checkout'),
                              style: GoogleFonts.notoSansTamil(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _qtyBtn({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: Colors.black87),
      ),
    );
  }
}
