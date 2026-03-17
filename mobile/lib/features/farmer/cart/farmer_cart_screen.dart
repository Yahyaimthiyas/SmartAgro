import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../../core/constants/colors.dart';
import '../../../core/widgets/common_image.dart';
import '../../../core/services/localization_service.dart';
import '../cart/cart_provider.dart';
import '../checkout/farmer_checkout_screen.dart';
import '../profile/farmer_profile_setup_screen.dart';

class FarmerCartScreen extends StatelessWidget {
  const FarmerCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final isTa = LocalizationService.isTamil;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(LocalizationService.tr('title_cart'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          if (cart.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              onPressed: () => _showClearCartDialog(context, cart),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(color: AppColors.surfaceVariant, shape: BoxShape.circle),
                    child: const Icon(Icons.shopping_cart_outlined, size: 64, color: AppColors.primary),
                  ),
                  const SizedBox(height: 24),
                  Text(LocalizationService.tr('msg_cart_empty'), style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(isTa ? 'ஆரம்பிக்கலாம்' : 'Start Shopping'),
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
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: item.imageUrl != null
                                  ? CommonImage(imageUrl: item.imageUrl, width: 80, height: 80, fit: BoxFit.cover)
                                  : Container(width: 80, height: 80, color: AppColors.background, child: const Icon(Icons.eco_outlined)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(isTa ? item.nameTa : item.nameEn, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Text('₹${item.price.toStringAsFixed(0)}', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.primary)),
                                  const SizedBox(height: 12),
                                  _QuantitySelector(item: item),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: AppColors.textPlaceholder, size: 20),
                              onPressed: () => cart.removeItem(item.productId),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                _buildBottomSummary(context, cart),
              ],
            ),
    );
  }

  Widget _buildBottomSummary(BuildContext context, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(LocalizationService.tr('label_total'), style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
              Text('₹${cart.totalAmount.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          ElevatedButton(
            onPressed: () => _handleCheckout(context, cart),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
            child: Text(LocalizationService.tr('btn_proceed_to_checkout')),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocalizationService.tr('title_clear_cart') ?? 'Clear Cart?'),
        content: Text(LocalizationService.tr('msg_clear_cart') ?? 'Are you sure you want to remove all items?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(LocalizationService.tr('btn_cancel'))),
          TextButton(onPressed: () { cart.clear(); Navigator.pop(context); }, child: Text(LocalizationService.tr('btn_clear'), style: const TextStyle(color: AppColors.error))),
        ],
      ),
    );
  }

  Future<void> _handleCheckout(BuildContext context, CartProvider cart) async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.data()?['hasAddress'] != true) {
         // Show address dialog or redirect
      }
    }
    if (context.mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmerCheckoutScreen()));
    }
  }
}

class _QuantitySelector extends StatelessWidget {
  final CartItem item;
  const _QuantitySelector({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(Icons.remove, () => cart.updateQuantity(item.productId, item.quantity - 1)),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold))),
          _btn(Icons.add, () => cart.updateQuantity(item.productId, item.quantity + 1)),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
        child: Icon(icon, size: 14, color: AppColors.primary),
      ),
    );
  }
}
