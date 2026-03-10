import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import '../products/farmer_product_list_screen.dart';
import 'widgets/product_grid_card.dart';

class FarmerCategoriesScreen extends StatefulWidget {
  final bool showBack;

  const FarmerCategoriesScreen({super.key, this.showBack = false});

  @override
  State<FarmerCategoriesScreen> createState() => _FarmerCategoriesScreenState();
}

class _FarmerCategoriesScreenState extends State<FarmerCategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6), // Slightly cooler grey for modern feel
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              sliver: SliverToBoxAdapter(
                child: Text(
                  _searchQuery.isEmpty 
                      ? LocalizationService.tr('title_categories')
                      : (LocalizationService.isTamil ? 'தேடல் முடிவுகள்' : 'Search Results'),
                  style: GoogleFonts.notoSansTamil(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            _searchQuery.isEmpty ? _buildCategoryGrid() : _buildSearchProductsResultGrid(),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: const Color(0xFFF4F7F6),
      elevation: 0,
      pinned: true,
      floating: true,
      expandedHeight: 160, // Taller header to fix overflow
      leading: widget.showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.showBack)
                Text(
                  LocalizationService.tr('home_products'), // "Products" or "Marketplace"
                  style: GoogleFonts.notoSansTamil(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              if (!widget.showBack) const SizedBox(height: 16),
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: LocalizationService.isTamil ? 'விதை, உரம் தேடுக...' : 'Search seeds, fertilizers...',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    suffixIcon: _searchQuery.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildCategoryGrid() {
    // ... categories stream builder ...
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('categories')
          .orderBy('sortOrder', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Text(LocalizationService.tr('msg_categories_coming_soon')),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.9, 
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final data = docs[index].data();
                final id = docs[index].id;
                final nameTa = data['name_ta'] as String? ?? '';
                final nameEn = data['name_en'] as String? ?? '';
                final iconKey = data['icon'] as String? ?? '';

                return _ModernCategoryCard(
                  nameTa: nameTa,
                  nameEn: nameEn,
                  iconKey: iconKey,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FarmerProductListScreen(
                          categoryId: id,
                          categoryNameTa: nameTa,
                          categoryNameEn: nameEn,
                        ),
                      ),
                    );
                  },
                );
              },
              childCount: docs.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchProductsResultGrid() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
        }

        final allProducts = snapshot.data?.docs ?? [];
        final filteredProducts = allProducts.where((doc) {
          final data = doc.data();
          final nameEn = (data['name_en'] as String? ?? '').toLowerCase();
          final nameTa = (data['name_ta'] as String? ?? '').toLowerCase();
          return nameEn.contains(_searchQuery) || nameTa.contains(_searchQuery);
        }).toList();

        if (filteredProducts.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Column(
                children: [
                   const SizedBox(height: 40),
                   Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                   const SizedBox(height: 16),
                   Text(
                      LocalizationService.isTamil ? 'முடிவுகள் ஏதுமில்லை' : 'No products found',
                      style: GoogleFonts.poppins(color: AppColors.textSecondary),
                   ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.68,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return ProductGridCard(
                  productId: filteredProducts[index].id,
                  data: filteredProducts[index].data(),
                );
              },
              childCount: filteredProducts.length,
            ),
          ),
        );
      },
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final String imageAsset;
  final IconData icon;
  final Color iconColor;

  const _FeaturedCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.imageAsset,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
             padding: const EdgeInsets.all(8),
             decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                shape: BoxShape.circle,
             ),
             child: Icon(icon, color: iconColor, size: 28),
          ),
          Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                     fontSize: 14,
                     fontWeight: FontWeight.bold,
                     color: const Color(0xFF1A1C1E),
                     height: 1.2
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                     fontSize: 12,
                     fontWeight: FontWeight.w600,
                     color: iconColor
                  ),
                ),
             ],
          )
        ],
      ),
    );
  }
}

class _ModernCategoryCard extends StatelessWidget {
  final String nameTa;
  final String nameEn;
  final String iconKey;
  final VoidCallback onTap;

  const _ModernCategoryCard({
    required this.nameTa,
    required this.nameEn,
    required this.iconKey,
    required this.onTap,
  });

  IconData _resolveIcon(String key) {
     switch (key) {
       case 'seeds': return Icons.spa;
       case 'fertilizers': return Icons.grass;
       case 'pesticides': return Icons.bug_report;
       case 'tools': return Icons.handyman;
       case 'machinery': return Icons.agriculture;
       case 'irrigation': return Icons.water_drop;
       default: return Icons.category;
     }
  }

  @override
  Widget build(BuildContext context) {
    final icon = _resolveIcon(iconKey);
    final isTa = LocalizationService.isTamil;
    final primary = isTa ? nameTa : nameEn;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             // Iconic Circle
             Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                   color: const Color(0xFFF5F5F5),
                   shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: AppColors.primary),
             ),
             const SizedBox(height: 16),
             Text(
                primary,
                style: GoogleFonts.notoSansTamil(
                   fontSize: 16,
                   fontWeight: FontWeight.bold,
                   color: AppColors.textPrimary
                ),
                textAlign: TextAlign.center,
             ),
          ],
        ),
      ),
    );
  }
}
