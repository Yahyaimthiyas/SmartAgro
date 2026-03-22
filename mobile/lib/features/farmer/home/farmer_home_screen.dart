import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/colors.dart';
import '../../../core/widgets/common_image.dart';
import '../../../core/services/localization_service.dart';
import '../products/farmer_categories_screen.dart';
import '../products/farmer_product_list_screen.dart';
import '../products/widgets/product_grid_card.dart';
import '../orders/farmer_orders_screen.dart';
import '../orders/farmer_order_tracking_screen.dart'; 
import '../rebuy/farmer_rebuy_screen.dart';
import '../cart/farmer_cart_screen.dart';
import '../../notifications/ui/farmer_notification_screen.dart';
import 'widgets/home_weather_widget.dart';
import '../orders/farmer_feedback_history_screen.dart';
import '../dosage/farmer_disease_list_screen.dart';
import '../advisory/farmer_ai_plant_doctor_screen.dart';
import '../profile/farmer_profile_screen.dart';
import '../products/farmer_product_search_screen.dart';

class FarmerHomeScreen extends StatefulWidget {
  const FarmerHomeScreen({super.key});

  @override
  State<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends State<FarmerHomeScreen> {
  final PageController _bannerController = PageController(viewportFraction: 1.0);
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
      backgroundColor: const Color(0xFFF8F9FA), // Soft grey background
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: _buildSearchBar(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildShopStatusIndicator(),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(isTa ? 'சிறப்பு சலுகைகள்' : 'Special offers'),
            _buildBannerSection(),
            const SizedBox(height: 28),
            _buildSectionHeader(isTa ? 'வகைகள்' : 'Shop by Category'),
            _buildCategoryStrip(isTa),
            const SizedBox(height: 28),
            _buildSectionHeader(isTa ? 'பிரபலமான பிராண்டுகள்' : 'Top Brands'),
            _buildPopularBrands(isTa),
            const SizedBox(height: 28),
            _buildSectionHeader(isTa ? 'விரைவான செயல்பாடுகள்' : 'Quick Actions'),
            _buildQuickActionsGrid(isTa),
            const SizedBox(height: 28),
            _buildHotSellingHeader(isTa),
            _buildHotSellingSection(isTa),
            const SizedBox(height: 28),
            _buildSectionHeader(isTa ? 'நிபுணர் ஆலோசனை' : 'Expert Advisory'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildAdvisorySection(isTa),
            ),
            const SizedBox(height: 28),
            _buildSectionHeader(isTa ? 'வானிலை' : 'Weather'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: HomeWeatherWidget(),
            ),
            const SizedBox(height: 28),
            if (user != null) ...[
              _buildSectionHeader(isTa ? 'சமீபத்திய ஆர்டர்கள்' : 'Recent orders'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _buildRecentOrderSection(user.uid),
              ),
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF8F9FA),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FarmerProfileScreen())),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 22),
          ),
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
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          color: const Color(0xFF222222),
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildHotSellingHeader(bool isTa) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isTa ? 'அதிகம் விற்கப்படுபவை' : 'Hot Selling',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF222222), fontSize: 18),
          ),
          Text(
            isTa ? 'அனைத்தும்' : 'View all',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        readOnly: true,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmerProductSearchScreen()));
        },
        decoration: InputDecoration(
          hintText: LocalizationService.isTamil ? 'தயாரிப்புகளைத் தேடுங்கள்...' : 'Search for products...',
          hintStyle: GoogleFonts.inter(color: AppColors.textPlaceholder, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isOpen ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE), // Very light green/red
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isOpen ? const Color(0xFFC8E6C9) : const Color(0xFFFFCDD2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOpen ? Icons.storefront_rounded : Icons.store_mall_directory_rounded,
                  color: isOpen ? Colors.green.shade700 : Colors.red.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOpen 
                        ? (LocalizationService.isTamil ? 'கடை திறந்துள்ளது' : 'Shop is Open')
                        : (LocalizationService.isTamil ? 'கடை மூடப்பட்டுள்ளது' : 'Shop is Closed'),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: const Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isOpen ? (LocalizationService.isTamil ? 'இப்போது ஆர்டர் செய்யுங்கள்' : 'Order your supplies now') 
                             : (LocalizationService.isTamil ? 'நாளை காலை பார்ப்போம்' : 'Check back tomorrow morning'),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBannerSection() {
    final isTa = LocalizationService.isTamil;
    
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('isOfferActive', isEqualTo: true)
          .limit(4)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final docs = snapshot.data!.docs;
        
        if (docs.isEmpty) {
          // Fallback if no offers exist, still premium
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF0D6846)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Icon(Icons.inventory_2_outlined, color: Colors.white.withOpacity(0.5), size: 48),
                     const SizedBox(height: 8),
                     Text(isTa ? 'சிறந்த தரம், சரியான விலை' : 'Best Quality, Right Price', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
              ),
            ),
          );
        }

        return Column(
          children: [
            SizedBox(
              height: 160,
              child: PageView.builder(
                controller: _bannerController,
                itemCount: docs.length,
                onPageChanged: (idx) => setState(() => _currentBanner = idx),
                itemBuilder: (context, index) {
                  final data = docs[index].data();
                  final String name = isTa ? (data['name_ta'] ?? data['name_en'] ?? '') : (data['name_en'] ?? data['name_ta'] ?? '');
                  final String imageUrl = data['imageUrl'] ?? '';
                  final num price = data['price'] ?? 0;
                  final String type = data['offerType'] ?? 'percentage';
                  final num value = data['offerValue'] ?? 0;
                  
                  String badgeText = '';
                  if (type == 'percentage' && value > 0) badgeText = '$value% OFF';
                  if (type == 'flat' && value > 0) badgeText = '₹$value OFF';

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: GestureDetector(
                      onTap: () {
                         // Fallback navigation or actual details
                         Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmerProductListScreen(categoryId: 'offers', categoryNameEn: 'Special Offers', categoryNameTa: 'சிறப்பு சலுகைகள்')));
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 8))],
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: Stack(
                          children: [
                            // Product Image BG
                            Positioned.fill(
                              child: CommonImage(imageUrl: imageUrl, fit: BoxFit.cover),
                            ),
                            // Dark Gradient Overlay for text visibility
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.black.withOpacity(0.8), Colors.transparent, Colors.black.withOpacity(0.4)],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                ),
                              ),
                            ),
                            // Content
                            Positioned(
                              left: 20,
                              bottom: 20,
                              right: 20,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (badgeText.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade600,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        badgeText,
                                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ),
                                  Text(
                                    name,
                                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                docs.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentBanner == index ? 24 : 8,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentBanner == index ? AppColors.primary : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryStrip(bool isTa) {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _pureCircleCategory(isTa ? 'விதைகள்' : 'Seeds', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmerProductListScreen(categoryId: 'seeds', categoryNameEn: 'Seeds', categoryNameTa: 'விதைகள்')))),
          _pureCircleCategory(isTa ? 'உரங்கள்' : 'Fertilizers', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmerProductListScreen(categoryId: 'fertilizers', categoryNameEn: 'Fertilizers', categoryNameTa: 'உரங்கள்')))),
          _pureCircleCategory(isTa ? 'பூச்சிக்..' : 'Pesticides', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmerProductListScreen(categoryId: 'pesticides', categoryNameEn: 'Pesticides', categoryNameTa: 'பூச்சிக்கொல்லிகள்')))),
        ],
      ),
    );
  }

  Widget _pureCircleCategory(String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              height: 70,
              width: 70,
              decoration: const BoxDecoration(
                color: Color(0xFFEEEEEE), // Soft grey placeholder
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: Text(
                title,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF222222)),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularBrands(bool isTa) {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _brandCircle('Syngenta'),
          _brandCircle('Bayer'),
          _brandCircle('UPL'),
          _brandCircle('Corteva'),
        ],
      ),
    );
  }

  Widget _brandCircle(String name) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                 BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Center(
              child: Text(
                name,
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(bool isTa) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.95,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _quickActionWhiteCard(Icons.shopping_bag_outlined, isTa ? 'பொருட்கள்' : 'Products', Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmerCategoriesScreen(showBack: true)))),
          _quickActionWhiteCard(Icons.autorenew_rounded, isTa ? 'மறுமுறை' : 'Rebuy', Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmerRebuyScreen()))),
          _quickActionWhiteCard(Icons.assignment_outlined, isTa ? 'ஆர்டர்கள்' : 'Orders', Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmerOrdersScreen()))),
          _quickActionWhiteCard(Icons.science_outlined, isTa ? 'மருந்தளவு' : 'Dosage', Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmerDiseaseListScreen()))),
          _quickActionWhiteCard(Icons.chat_bubble_outline_rounded, isTa ? 'கருத்து' : 'Feedback', Colors.pink, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmerFeedbackHistoryScreen()))),
          _quickActionWhiteCard(Icons.local_offer_outlined, isTa ? 'சலுகைகள்' : 'Offers', Colors.deepOrange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmerProductListScreen(categoryId: 'offers', categoryNameEn: 'Special Offers', categoryNameTa: 'சிறப்பு சலுகைகள்')))),
        ],
      ),
    );
  }

  Widget _quickActionWhiteCard(IconData icon, String title, Color accentColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: Text(
                title,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF444444)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHotSellingSection(bool isTa) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('products').limit(10).snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();
        
        return SizedBox(
          height: 270,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 170, // Slightly wider for new layout
                  child: ProductGridCard(productId: docs[index].id, data: docs[index].data()),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAdvisorySection(bool isTa) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmerAiPlantDoctorScreen())),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 165, // Increased slightly for comfort
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
           borderRadius: BorderRadius.circular(20),
           gradient: const LinearGradient(
             colors: [Color(0xFF1E3A8A), Color(0xFF312E81)], // Premium Royal Blue to Indigo
             begin: Alignment.topLeft,
             end: Alignment.bottomRight,
           ),
           boxShadow: [
             BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
           ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -40,
                bottom: -40,
                child: Icon(
                  Icons.psychology_rounded,
                  size: 140,
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribute content
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTa ? 'AI பயிர் டாக்டர்' : 'AI Plant Doctor',
                        style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isTa ? 'உங்கள் கேமரா மூலம் பயிர் சிக்கல்களை உடனடியாக கண்டறியுங்கள்.' : 'Diagnose crop issues instantly using your camera.',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isTa ? 'இப்போது ஸ்கேன் செய்' : 'Scan Now',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
        final isTa = LocalizationService.isTamil;
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTa ? 'சமீபத்திய ஆர்டர்' : 'CURRENT ORDER',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Order #${order.id.substring(0, 6)} •',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF222222)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        status.toUpperCase(),
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FarmerOrderTrackingScreen(orderId: order.id))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(LocalizationService.tr('view_details'), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
