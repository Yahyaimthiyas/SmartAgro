import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import '../cart/cart_provider.dart';
import '../orders/farmer_order_success_screen.dart';

class FarmerCheckoutScreen extends StatefulWidget {
  const FarmerCheckoutScreen({super.key});

  @override
  State<FarmerCheckoutScreen> createState() => _FarmerCheckoutScreenState();
}

class _FarmerCheckoutScreenState extends State<FarmerCheckoutScreen> {
  String _paymentMethod = 'cash';
  bool _isPlacing = false;

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
          LocalizationService.tr('title_checkout'),
          style: GoogleFonts.notoSansTamil(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Text(
                'கூடை காலியாக உள்ளது',
                style: GoogleFonts.notoSansTamil(fontSize: 14, color: AppColors.textSecondary),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Receipt Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.05),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.receipt_long, color: AppColors.primary),
                                    const SizedBox(width: 12),
                                    Text(
                                      LocalizationService.tr('title_order_summary'),
                                      style: GoogleFonts.notoSansTamil(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1, color: Color(0xFFEEEEEE)),
                              // Items
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    for (final item in cart.items) ...[
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.nameTa,
                                                    style: GoogleFonts.notoSansTamil(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  if (item.nameEn.isNotEmpty)
                                                    Text(
                                                      item.nameEn,
                                                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'x${item.quantity}',
                                              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                                            ),
                                            const SizedBox(width: 16),
                                            Text(
                                              '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                                              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const Divider(height: 30, thickness: 1, color: Color(0xFFDDDDDD)),
                                    // Total
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          LocalizationService.tr('label_total'),
                                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          '₹${cart.totalAmount.toStringAsFixed(0)}',
                                          style: GoogleFonts.notoSansTamil(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        Text(
                          LocalizationService.tr('title_pickup_info'),
                          style: GoogleFonts.notoSansTamil(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                               Container(
                                 padding: const EdgeInsets.all(12),
                                 decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    shape: BoxShape.circle,
                                 ),
                                 child: Icon(Icons.store_outlined, color: Colors.orange.shade700),
                               ),
                               const SizedBox(width: 16),
                               Expanded(
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text(
                                       LocalizationService.tr('pickup_shop_name'),
                                       style: GoogleFonts.notoSansTamil(
                                         fontSize: 14,
                                         fontWeight: FontWeight.bold,
                                       ),
                                     ),
                                     const SizedBox(height: 4),
                                     Text(
                                       LocalizationService.tr('pickup_shop_address'),
                                       style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                                     ),
                                     const SizedBox(height: 4),
                                     Text(
                                       LocalizationService.tr('pickup_pick_within'),
                                       style: GoogleFonts.poppins(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w500),
                                     ),
                                   ],
                                 ),
                               ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                        
                        Text(
                          LocalizationService.tr('title_payment_method'),
                          style: GoogleFonts.notoSansTamil(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        _paymentOption(
                           value: 'cash',
                           title: LocalizationService.tr('payment_cash'),
                           subtitle: '',
                           icon: Icons.payments_outlined,
                        ),
                        const SizedBox(height: 12),
                        _paymentOption(
                           value: 'credit',
                           title: LocalizationService.tr('payment_credit'),
                           subtitle: LocalizationService.tr('payment_credit_note'),
                           icon: Icons.credit_card_outlined,
                        ),
                        
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                     color: Colors.white,
                     boxShadow: [
                        BoxShadow(
                           color: Colors.black.withOpacity(0.05),
                           blurRadius: 10,
                           offset: const Offset(0, -4)
                        )
                     ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isPlacing || cart.items.isEmpty ? null : () => _placeOrder(context, cart),
                        style: ElevatedButton.styleFrom(
                           backgroundColor: AppColors.primary,
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                           elevation: 0,
                        ),
                        child: _isPlacing
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                   Text(
                                    LocalizationService.tr('btn_place_order'),
                                    style: GoogleFonts.notoSansTamil(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.check_circle_outline, color: Colors.white),
                                ],
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _paymentOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _paymentMethod == value;
    return InkWell(
      onTap: () => setState(() => _paymentMethod = value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
         padding: const EdgeInsets.all(16),
         decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
               color: isSelected ? AppColors.primary : Colors.grey.shade200,
               width: isSelected ? 2 : 1
            ),
         ),
         child: Row(
            children: [
               Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                     color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade50,
                     shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: isSelected ? AppColors.primary : Colors.grey.shade600),
               ),
               const SizedBox(width: 16),
               Expanded(
                 child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text(
                          title,
                          style: GoogleFonts.notoSansTamil(
                             fontSize: 15,
                             fontWeight: FontWeight.w600,
                             color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                          ),
                       ),
                       if(subtitle.isNotEmpty)
                          Text(
                             subtitle,
                             style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                          )
                    ],
                 ),
               ),
               if(isSelected)
                  const Icon(Icons.radio_button_checked, color: AppColors.primary)
               else
                  const Icon(Icons.radio_button_off, color: Colors.grey),
            ],
         ),
      ),
    );
  }

  Future<void> _placeOrder(BuildContext context, CartProvider cart) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService.tr('error_login_again')),
        ),
      );
      return;
    }
    if (cart.items.isEmpty) return;

    setState(() => _isPlacing = true);

    try {
      final total = cart.totalAmount;
      final orderRef = FirebaseFirestore.instance.collection('orders').doc();

      // [STOCK MANAGEMENT] Use a transaction to safely check and reduce stock
      await FirebaseFirestore.instance.runTransaction((transaction) async {
         // 1. Read all product docs to check stock
         for (final item in cart.items) {
            final productRef = FirebaseFirestore.instance.collection('products').doc(item.productId);
            final productDoc = await transaction.get(productRef);
            
            if (!productDoc.exists) {
               throw Exception("Product '${item.nameEn}' no longer exists.");
            }
            
            final currentStock = (productDoc.data()?['stock'] as num?)?.toInt() ?? 0;
            if (currentStock < item.quantity) {
               throw Exception("Insufficient stock for '${item.nameTa}' (Available: $currentStock)");
            }
         }

         // 2. Reduce Stock
         for (final item in cart.items) {
            final productRef = FirebaseFirestore.instance.collection('products').doc(item.productId);
            transaction.update(productRef, {
               'stock': FieldValue.increment(-item.quantity)
            });
         }

         // 3. Create Order
         transaction.set(orderRef, {
            'userId': user.uid,
            'shopId': 'default_shop',
            'status': 'reserved',
            'paymentMethod': _paymentMethod,
            'totalAmount': total,
            'createdAt': FieldValue.serverTimestamp(),
            'items': cart.items.map((item) => {
               'productId': item.productId,
               'name_ta': item.nameTa,
               'name_en': item.nameEn,
               'price': item.price,
               'quantity': item.quantity,
               'unit_ta': item.unitTa,
               'unit_en': item.unitEn,
            }).toList(),
         });
      });

      cart.clear();

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => FarmerOrderSuccessScreen(
            orderId: orderRef.id,
            totalAmount: total,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${LocalizationService.tr('error_failed_place_order')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPlacing = false);
      }
    }
  }
}
