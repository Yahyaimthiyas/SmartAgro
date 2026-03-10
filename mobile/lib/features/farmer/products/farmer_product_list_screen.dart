import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../core/widgets/common_image.dart'; // [NEW]
import '../../../core/services/localization_service.dart';
import '../cart/cart_provider.dart';
import '../cart/farmer_cart_screen.dart';
import 'widgets/product_grid_card.dart';

class FarmerProductListScreen extends StatelessWidget {
  final String categoryId;
  final String categoryNameTa;
  final String categoryNameEn;

  const FarmerProductListScreen({
    super.key,
    required this.categoryId,
    required this.categoryNameTa,
    required this.categoryNameEn,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Column(
          children: [
            Text(
              categoryNameTa,
              style: GoogleFonts.notoSansTamil(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              categoryNameEn,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FarmerCartScreen()),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('categoryId', isEqualTo: categoryId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                    Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      LocalizationService.tr('msg_no_products_in_category'),
                      style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textSecondary),
                    ),
                 ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.68, // Taller cards for images
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              return ProductGridCard(
                 productId: docs[index].id,
                 data: data,
              );
            },
          );
        },
      ),
    );
  }
}
