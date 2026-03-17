import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/colors.dart';
import '../../../core/widgets/common_image.dart';
import '../../../core/services/localization_service.dart';
import 'package:animate_do/animate_do.dart';
import '../products/farmer_categories_screen.dart';
import '../products/farmer_product_list_screen.dart';
import '../products/farmer_product_details_screen.dart'; 
import '../products/widgets/product_grid_card.dart';
import '../orders/farmer_orders_screen.dart';
import '../orders/farmer_order_tracking_screen.dart'; 
import '../rebuy/farmer_rebuy_screen.dart';
import '../advisory/farmer_ai_plant_doctor_screen.dart';
import '../dosage/farmer_disease_list_screen.dart';
import '../cart/farmer_cart_screen.dart';
import '../../notifications/ui/farmer_notification_screen.dart';
import 'widgets/home_weather_widget.dart';
import '../orders/farmer_feedback_history_screen.dart';

class FarmerHomeScreen extends StatefulWidget {
  const FarmerHomeScreen({super.key});

  @override
  State<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends State<FarmerHomeScreen> {
  final PageController _bannerController = PageController(viewportFraction: 0.92);
  int _currentBanner = 0;

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isTa = LocalizationService.isTamil;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(user),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const SizedBox(height: 12),
                  _buildShopStatusIndicator(),
                  const SizedBox(height: 20),
                  _buildSectionHeader(LocalizationService.tr('home_special_offers')),
                  _buildBannerSection(),
                  const SizedBox(height: 24),
                  _buildSectionHeader(isTa ? 'வகைகள்' : 'Shop by Category'),
                  _buildCategoryStrip(isTa),
                  const SizedBox(height: 24),
                  _buildPopularBrands(isTa),
                  const SizedBox(height: 24),
                  _buildSectionHeader(LocalizationService.tr('home_quick_actions')),
                  _buildQuickActionsGrid(),
                  const SizedBox(height: 24),
                  _buildHotSellingSection(isTa),
                  const SizedBox(height: 24),
                  _buildSectionHeader(isTa ? 'ஆலோசனை' : 'Expert Advisory'),
                  _buildAdvisorySection(),
                  const SizedBox(height: 24),
                  _buildWeatherCard(),
                  const SizedBox(height: 24),
                  _buildSectionHeader(isTa ? 'பருவகால கருவிகள்' : 'Seasonal Kits'),
                  const _SeasonalKitsSection(),
                  const SizedBox(height: 24),
                  if (user != null) ...[
                    _buildSectionHeader(LocalizationService.tr('home_recent_orders')),
                    _buildRecentOrderSection(user.uid),
                    const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(User? user) {
    return SliverAppBar(
      expandedHeight: 140.0,
      floating: true,
      pinned: true,
      backgroundColor: AppColors.background,
      surfaceTintColor: AppColors.background,
      elevation: 0,
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: AppColors.primaryContainer,
          child: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 20),
        ),
      ),
      title: Text(
        'SmartAgro',
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          fontSize: 24,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmerNotificationScreen())),
        ),
        IconButton(
          icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.textPrimary),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmerCartScreen())),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(20, 100, 20, 0),
          child: Column(
            children: [
              _buildSearchBar(),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: TextField(
        readOnly: true,
        onTap: () {
           // Go to search
        },
        decoration: InputDecoration(
          hintText: LocalizationService.isTamil ? 'தேடுங்கள்...' : 'Search for products...',
          hintStyle: GoogleFonts.inter(color: AppColors.textPlaceholder, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildShopStatusIndicator() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('shop_settings').doc('current').snapshots(),
      builder: (context, snapshot) {
        final isOpen = snapshot.data?.data()?['isOpen'] ?? true;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isOpen ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isOpen ? Colors.green.shade100 : Colors.red.shade100),
            boxShadow: [
              BoxShadow(
                color: (isOpen ? Colors.green : Colors.red).withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isOpen ? Colors.green.shade100 : Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOpen ? Icons.storefront_rounded : Icons.store_mall_directory_rounded,
                  color: isOpen ? Colors.green.shade700 : Colors.red.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOpen 
                        ? (LocalizationService.isTamil ? 'கடை திறந்துள்ளது' : 'Shop is Open')
                        : (LocalizationService.isTamil ? 'கடை மூடப்பட்டுள்ளது' : 'Shop is Closed'),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isOpen ? Colors.green.shade900 : Colors.red.shade900,
                      ),
                    ),
                    Text(
                      isOpen ? (LocalizationService.isTamil ? 'இப்போது ஆர்டர் செய்யுங்கள்' : 'Order your supplies now') 
                             : (LocalizationService.isTamil ? 'நாளை காலை மீண்டும் பார்க்கவும்' : 'Check back tomorrow morning'),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: (isOpen ? Colors.green.shade700 : Colors.red.shade700).withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 12, color: isOpen ? Colors.green.shade300 : Colors.red.shade300),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionsGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      mainAxisSpacing: 24,
      crossAxisSpacing: 12,
      childAspectRatio: 0.8,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _quickActionTile(Icons.storefront_outlined, 'பொருட்கள்', 'Products', AppColors.primary, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmerCategoriesScreen(showBack: true)))),
        _quickActionTile(Icons.history_rounded, 'மறுமுறை', 'Rebuy', Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmerRebuyScreen()))),
        _quickActionTile(Icons.receipt_long_rounded, 'ஆர்டர்கள்', 'Orders', Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmerOrdersScreen()))),
        _quickActionTile(Icons.medical_services_outlined, 'மருந்தளவு', 'Dosage', Colors.red, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmerDiseaseListScreen()))),
        _quickActionTile(Icons.rate_review_outlined, 'கருத்துக்கள்', 'Feedback', Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmerFeedbackHistoryScreen()))),
        _quickActionTile(Icons.local_offer_outlined, 'சலுகைகள்', 'Offers', Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmerProductListScreen(categoryId: 'offers', categoryNameEn: 'Special Offers', categoryNameTa: 'சிறப்பு சலுகைகள்')))),
      ],
    );
  }

  Widget _quickActionTile(IconData icon, String titleTa, String titleEn, Color color, VoidCallback onTap) {
    final isTa = LocalizationService.isTamil;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            isTa ? titleTa : titleEn,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBannerSection() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('banners').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        
        // Show fallback local image if no banners in Firestore
        final List<Widget> banners = docs.isNotEmpty 
          ? docs.map((d) => ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CommonImage(imageUrl: d.data()['imageUrl'] ?? '', fit: BoxFit.cover),
              )).toList()
          : [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  File(r'C:\Users\SANJAI\.gemini\antigravity\brain\915e6d9b-7013-4b4f-bcfd-1d44322ca841\special_offers_banner_1773756698244.png'),
                  fit: BoxFit.cover,
                ),
              )
            ];

        return SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: banners.length,
            onPageChanged: (idx) => setState(() => _currentBanner = idx),
            itemBuilder: (context, index) => Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppColors.surfaceVariant,
              ),
              child: banners[index],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPopularBrands(bool isTa) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0, top: 0, bottom: 0,
            width: 150,
            child: Opacity(
              opacity: 0.1,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(topRight: Radius.circular(24), bottomRight: Radius.circular(24)),
                child: Image.file(
                  File(r'C:\Users\SANJAI\.gemini\antigravity\brain\915e6d9b-7013-4b4f-bcfd-1d44322ca841\featured_brands_bg_1773756725979.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(isTa ? 'பிரபலமான பிராண்டுகள்' : 'Top Brands'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 90,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _brandCircle('Syngenta', 'https://upload.wikimedia.org/wikipedia/en/thumb/f/f6/Syngenta_Logo.svg/1200px-Syngenta_Logo.svg.png'),
                      _brandCircle('Bayer', 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f7/Bayer_logo.svg/1200px-Bayer_logo.svg.png'),
                      _brandCircle('UPL', 'https://upload.wikimedia.org/wikipedia/commons/e/e0/UPL_Logo.png'),
                      _brandCircle('Coromandel', 'https://upload.wikimedia.org/wikipedia/en/3/3a/Coromandel_International_logo.png'),
                      _brandCircle('Sumitomo', 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Sumitomo_Chemical_logo.svg/1024px-Sumitomo_Chemical_logo.svg.png'),
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

  Widget _brandCircle(String name, String url) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: ClipOval(child: Padding(padding: const EdgeInsets.all(8), child: CommonImage(imageUrl: url, fit: BoxFit.contain))),
          ),
          const SizedBox(height: 6),
          Text(
            name, 
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textPrimary), 
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

   Widget _buildRecentOrderSection(String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
        final order = snapshot.data!.docs.first;
        final data = order.data();
        final status = data['status'] ?? 'pending';
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Positioned(
                  right: -10, top: -10,
                  child: Icon(Icons.local_shipping_outlined, size: 80, color: AppColors.primary.withOpacity(0.05)),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(LocalizationService.isTamil ? 'சமீபத்திய ஆர்டர்' : 'Recent Order Status', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                          const Spacer(),
                          Text('#${order.id.substring(0, 6)}', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(LocalizationService.isTamil ? 'நிலை' : 'STATUS', style: GoogleFonts.inter(fontSize: 10, letterSpacing: 1, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(status.toUpperCase(), style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 14)),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FarmerOrderTrackingScreen(orderId: order.id))),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(LocalizationService.tr('view_details'), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdvisorySection() {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmerAiPlantDoctorScreen())),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
           borderRadius: BorderRadius.circular(24),
           image: DecorationImage(
             image: FileImage(File(r'C:\Users\SANJAI\.gemini\antigravity\brain\915e6d9b-7013-4b4f-bcfd-1d44322ca841\ai_plant_doctor_hero_1773755932208.png')),
             fit: BoxFit.cover,
             colorFilter: ColorFilter.mode(AppColors.primary.withOpacity(0.7), BlendMode.srcOver),
           ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      LocalizationService.isTamil ? 'AI பயிர் டாக்டர்' : 'AI Plant Doctor',
                      style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      LocalizationService.isTamil ? 'உங்கள் பயிர் நோயைக் கண்டறிய புகைப்படம் எடுக்கவும்' : 'Take a photo to diagnose crop diseases instantly',
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withOpacity(0.9)),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 20),
              child: Icon(Icons.document_scanner_rounded, color: Colors.white, size: 48),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard() => const HomeWeatherWidget();

  Widget _buildHotSellingSection(bool isTa) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('products').limit(10).snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();
        
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0, top: 0, right: 0,
                height: 120,
                child: Opacity(
                  opacity: 0.15,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                    child: Image.file(
                      File(r'C:\Users\SANJAI\.gemini\antigravity\brain\915e6d9b-7013-4b4f-bcfd-1d44322ca841\hot_selling_products_bg_1773756834765.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(isTa ? 'அதிகம் விற்கப்படுபவை' : 'Hot Selling Products'),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: SizedBox(
                              width: 160,
                              child: ProductGridCard(productId: docs[index].id, data: docs[index].data()),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryStrip(bool isTa) {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _categoryCard(
            isTa ? 'விதைகள்' : 'Seeds', 
            r'C:\Users\SANJAI\.gemini\antigravity\brain\915e6d9b-7013-4b4f-bcfd-1d44322ca841\category_seeds_1773756890490.png',
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmerProductListScreen(categoryId: 'seeds', categoryNameEn: 'Seeds', categoryNameTa: 'விதைகள்')))
          ),
          _categoryCard(
            isTa ? 'உரங்கள்' : 'Fertilizers', 
            r'C:\Users\SANJAI\.gemini\antigravity\brain\915e6d9b-7013-4b4f-bcfd-1d44322ca841\category_fertilizers_1773756916237.png',
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmerProductListScreen(categoryId: 'fertilizers', categoryNameEn: 'Fertilizers', categoryNameTa: 'உரங்கள்')))
          ),
          _categoryCard(
            isTa ? 'பூச்சிக்கொல்லிகள்' : 'Pesticides', 
            r'C:\Users\SANJAI\.gemini\antigravity\brain\915e6d9b-7013-4b4f-bcfd-1d44322ca841\category_pesticides_1773756942495.png',
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmerProductListScreen(categoryId: 'pesticides', categoryNameEn: 'Pesticides', categoryNameTa: 'பூச்சிக்கொல்லிகள்')))
          ),
          _categoryCard(
            isTa ? 'கருவிகள்' : 'Tools', 
            r'C:\Users\SANJAI\.gemini\antigravity\brain\915e6d9b-7013-4b4f-bcfd-1d44322ca841\category_tools_1773756976987.png',
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmerProductListScreen(categoryId: 'tools', categoryNameEn: 'Tools', categoryNameTa: 'கருவிகள்')))
          ),
        ],
      ),
    );
  }

  Widget _categoryCard(String title, String imagePath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: FileImage(File(imagePath)),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _WeatherProductPromoSection extends StatelessWidget {
  const _WeatherProductPromoSection();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // Placeholder if needed
  }
}

class _SeasonalKitsSection extends StatelessWidget {
  const _SeasonalKitsSection();

  @override
  Widget build(BuildContext context) {
    return Container(
       height: 140,
       decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: DecorationImage(
             image: FileImage(File(r'C:\Users\SANJAI\.gemini\antigravity\brain\915e6d9b-7013-4b4f-bcfd-1d44322ca841\seasonal_kits_promo_1773755900110.png')),
             fit: BoxFit.cover,
             colorFilter: ColorFilter.mode(Colors.orange.shade800.withOpacity(0.6), BlendMode.srcOver),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
       ),
       child: Padding(
         padding: const EdgeInsets.all(20),
         child: Row(
           children: [
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Text(
                     LocalizationService.isTamil ? 'பருவகால தொகுப்புகள்' : 'Seasonal Kits',
                     style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                   ),
                   const SizedBox(height: 4),
                   Text(
                     LocalizationService.isTamil ? 'தற்போதைய காலநிலைக்கு ஏற்ற உரங்கள் மற்றும் விதைகள்' : 'Perfect blends for the current weather & crop cycle',
                     style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                   ),
                 ],
               ),
             ),
             const Icon(Icons.inventory_rounded, color: Colors.white, size: 40),
           ],
         ),
       ),
    );
  }
}
