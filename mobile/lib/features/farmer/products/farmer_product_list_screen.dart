import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import '../cart/cart_provider.dart';
import '../cart/farmer_cart_screen.dart';
import 'widgets/product_grid_card.dart';

class FarmerProductListScreen extends StatefulWidget {
  final String? categoryId;
  final String? categoryNameTa;
  final String? categoryNameEn;
  final String? brand; // New parameter for brand filtering

  const FarmerProductListScreen({
    super.key,
    this.categoryId,
    this.categoryNameTa,
    this.categoryNameEn,
    this.brand,
  });

  @override
  State<FarmerProductListScreen> createState() => _FarmerProductListScreenState();
}

class _FarmerProductListScreenState extends State<FarmerProductListScreen> {
  String? _selectedSubCategory;

  final Map<String, List<String>> _subCategoriesMap = {
    'seeds': [
      'Field Crop Seeds', 'Vegetable Seeds', 'Fruit Seeds', 'Flower Seeds', 
      'Fodder Seeds', 'Hybrid Seeds', 'Organic Seeds', 'Tissue Culture Plants'
    ],
    'fertilizers': [
      'Chemical Fertilizers', 'Bio Fertilizers', 'Organic Fertilizers', 
      'Micronutrient Fertilizers', 'Water Soluble Fertilizers'
    ],
    'pesticides': [
      'Insecticides', 'Systemic Insecticides', 'Contact Insecticides', 'Biological Insecticides'
    ],
    'fungicides': [
      'Contact Fungicides', 'Systemic Fungicides', 'Combination Fungicides'
    ],
    'bactericides': [
      'Antibiotic bactericides', 'Copper-based bactericides'
    ],
    'herbicides': [
      'Selective Herbicides', 'Non-selective Herbicides', 'Pre-emergence Herbicides', 'Post-emergence Herbicides'
    ],
    'pgr': [
      'Growth promoters', 'Growth inhibitors', 'Plant hormones', 'Flowering stimulants', 'Yield boosters'
    ],
    'biopesticides': [
      'Neem-based pesticides', 'Microbial pesticides', 'Botanical pesticides', 'Fungal biocontrol agents'
    ],
  };

  @override
  Widget build(BuildContext context) {
    final subCats = widget.categoryId != null ? (_subCategoriesMap[widget.categoryId] ?? []) : [];
    final isTa = LocalizationService.isTamil;

    String titleTa = widget.categoryNameTa ?? (widget.brand ?? '');
    String titleEn = widget.categoryNameEn ?? (widget.brand ?? '');

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
              titleTa,
              style: GoogleFonts.notoSansTamil(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              titleEn,
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
      body: Column(
        children: [
          if (subCats.isNotEmpty)
            Container(
              height: 60,
              color: Colors.white,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                scrollDirection: Axis.horizontal,
                itemCount: subCats.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ChoiceChip(
                      label: Text(isTa ? 'அனைத்தும்' : 'All'),
                      selected: _selectedSubCategory == null,
                      onSelected: (val) => setState(() => _selectedSubCategory = null),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(color: _selectedSubCategory == null ? Colors.white : Colors.black87),
                    );
                  }
                  final sub = subCats[index - 1];
                  final isSelected = _selectedSubCategory == sub;
                  return ChoiceChip(
                    label: Text(sub),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _selectedSubCategory = val ? sub : null),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                  );
                },
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _buildQuery().snapshots(),
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
                    childAspectRatio: 0.68,
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
          ),
        ],
      ),
    );
  }

  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('products');
    
    if (widget.categoryId != null) {
      if (widget.categoryId == 'offers') {
        query = query.where('offerPercentage', isGreaterThan: 0);
      } else {
        query = query.where('categoryId', isEqualTo: widget.categoryId);
      }
    }
    
    if (widget.brand != null) {
      query = query.where('brand', isEqualTo: widget.brand);
    }
    
    if (_selectedSubCategory != null) {
      query = query.where('subCategory', isEqualTo: _selectedSubCategory);
    }
    
    return query;
  }
}
