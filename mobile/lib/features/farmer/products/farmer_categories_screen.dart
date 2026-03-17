import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import '../products/farmer_product_list_screen.dart';
import '../cart/farmer_cart_screen.dart';
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
      backgroundColor: AppColors.background,
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
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            _searchQuery.isEmpty ? _buildCategoryGrid() : _buildSearchProductsResultGrid(),
            if (_searchQuery.isEmpty) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
              _buildHorizontalCategoryLists(),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 48)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: AppColors.background,
      surfaceTintColor: AppColors.background,
      elevation: 0,
      pinned: true,
      floating: true,
      expandedHeight: 140,
      leading: widget.showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      actions: [
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FarmerCartScreen())),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildSearchBar(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: LocalizationService.isTamil ? 'அனைத்தையும் தேடுங்கள்...' : 'Search everything...',
          hintStyle: GoogleFonts.inter(color: AppColors.textPlaceholder, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
          suffixIcon: _searchQuery.isNotEmpty 
              ? IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () => _searchController.clear())
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('categories').orderBy('sortOrder').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.2, 
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final data = docs[index].data();
                return _ModernCategoryCard(
                  nameTa: data['name_ta'] ?? '',
                  nameEn: data['name_en'] ?? '',
                  iconKey: data['icon'] ?? '',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FarmerProductListScreen(categoryId: docs[index].id, categoryNameTa: data['name_ta'] ?? '', categoryNameEn: data['name_en'] ?? ''))),
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
        final allProducts = snapshot.data?.docs ?? [];
        final filtered = allProducts.where((doc) {
          final data = doc.data();
          final nameEn = (data['name_en'] as String? ?? '').toLowerCase();
          final nameTa = (data['name_ta'] as String? ?? '').toLowerCase();
          return nameEn.contains(_searchQuery) || nameTa.contains(_searchQuery);
        }).toList();

        if (filtered.isEmpty) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: Text("No products found"))));

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.7),
            delegate: SliverChildBuilderDelegate((context, index) => ProductGridCard(productId: filtered[index].id, data: filtered[index].data()), childCount: filtered.length),
          ),
        );
      },
    );
  }

  Widget _buildHorizontalCategoryLists() {
    const categories = [
      {'id': 'seeds', 'en': 'Seeds', 'ta': 'விதைகள்'},
      {'id': 'fertilizers', 'en': 'Fertilizers', 'ta': 'உரங்கள்'},
    ];

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildHorizontalCategoryRow(categories[index]),
        childCount: categories.length,
      ),
    );
  }

  Widget _buildHorizontalCategoryRow(Map<String, String> cat) {
    final isTa = LocalizationService.isTamil;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isTa ? cat['ta']! : cat['en']!, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FarmerProductListScreen(categoryId: cat['id']!, categoryNameTa: cat['ta']!, categoryNameEn: cat['en']!))), child: const Text('See All')),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('products').where('categoryId', isEqualTo: cat['id']).limit(5).snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: docs.length,
                itemBuilder: (context, index) => Padding(padding: const EdgeInsets.only(right: 12), child: SizedBox(width: 150, child: ProductGridCard(productId: docs[index].id, data: docs[index].data()))),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ModernCategoryCard extends StatelessWidget {
  final String nameTa;
  final String nameEn;
  final String iconKey;
  final VoidCallback onTap;

  const _ModernCategoryCard({required this.nameTa, required this.nameEn, required this.iconKey, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isTa = LocalizationService.isTamil;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
                child: Icon(_resolveIcon(iconKey), size: 28, color: AppColors.primary),
             ),
             const SizedBox(height: 12),
             Text(isTa ? nameTa : nameEn, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  IconData _resolveIcon(String key) {
     switch (key) {
       case 'seeds': return Icons.spa_rounded;
       case 'fertilizers': return Icons.grass_rounded;
       case 'pesticides': return Icons.bug_report_rounded;
       default: return Icons.category_rounded;
     }
  }
}
