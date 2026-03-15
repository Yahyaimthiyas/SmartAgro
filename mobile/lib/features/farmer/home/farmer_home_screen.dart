import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/colors.dart';
import '../../../core/widgets/common_image.dart';
import '../../../core/services/localization_service.dart';
import '../../../core/widgets/glass_container.dart';
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
import '../../notifications/repositories/notification_repository.dart';
import '../../notifications/models/app_notification.dart';
import 'widgets/home_weather_widget.dart';

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
      backgroundColor: const Color(0xFFF8F9FA),
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
                  const SizedBox(height: 32),
                  _buildPopularBrands(isTa),
                  const SizedBox(height: 32),
                  _buildSectionHeader(LocalizationService.tr('home_quick_actions')),
                  const SizedBox(height: 16),
                  _buildQuickActionsGrid(),
                  const SizedBox(height: 32),
                  _buildHotSellingSection(isTa),
                  const SizedBox(height: 32),
                  _buildSectionHeader(isTa ? 'ஆலோசனை' : 'Expert Advisory'),
                  const SizedBox(height: 16),
                  _buildAdvisorySection(),
                  const SizedBox(height: 32),
                  _buildWeatherCard(),
                   const SizedBox(height: 16),
                   const _WeatherProductPromoSection(),
                  const SizedBox(height: 32),
                  _buildSectionHeader(isTa ? 'பருவகால பயிர் கருவிகள்' : 'Seasonal Crop Kits'),
                  const SizedBox(height: 16),
                  const _SeasonalKitsSection(),
                  const SizedBox(height: 32),
                  _buildSectionHeader(isTa ? 'பயிர் வழிகாட்டி' : 'Crop Stage Guide'),
                  const SizedBox(height: 16),
                  const _CropStageGuideSection(),
                  const SizedBox(height: 32),
                  if (user != null) ...[
                    _buildSectionHeader(LocalizationService.tr('home_recent_orders')),
                    const SizedBox(height: 16),
                    _buildRecentOrderSection(user.uid),
                    const SizedBox(height: 48),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(User? user) {
    return SliverAppBar(
      expandedHeight: 140.0,
      floating: true,
      pinned: true,
      backgroundColor: AppColors.primary,
      elevation: 0,
      centerTitle: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Darker Top Section
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, Color(0xFF00332B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Decorative elements
            Positioned(
              top: -60,
              right: -60,
              child: CircleAvatar(radius: 120, backgroundColor: Colors.white.withOpacity(0.05)),
            ),
            
            Padding(
               padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
               child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                     _buildHeaderContent(user),
                  ],
               ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeaderContent(User? user) {
     final uid = user?.uid;

    if (uid == null) {
      return _basicHeader(null, user?.phoneNumber);
    }
    
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        String? name;
        String? phone = user?.phoneNumber;

        if (snapshot.hasData && snapshot.data!.data() != null) {
          final data = snapshot.data!.data()!;
          name = data['name'] as String?;
          phone = data['phone'] as String? ?? phone;
        }

        return _basicHeader(name ?? phone, phone);
      },
    );
  }

  Widget _basicHeader(String? displayName, String? phone) {
    final nameText = displayName ?? phone ?? '';
    final isTa = LocalizationService.isTamil;
    
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: BorderRadius.circular(24),
      opacity: 0.15,
      blur: 15,
      child: Row(
        children: [
          Container(
             padding: const EdgeInsets.all(2),
             decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.surface,
                child: const Icon(Icons.person, color: AppColors.primary, size: 28),
              ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isTa ? 'வணக்கம்,' : 'Welcome back,',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  nameText,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _buildAppBarAction(
            icon: Icons.notifications_none_rounded,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmerNotificationScreen())),
            badgeCount: 0, // Simplified for now
          ),
          const SizedBox(width: 10),
          _buildAppBarAction(
            icon: Icons.shopping_basket_outlined,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmerCartScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarAction({required IconData icon, required VoidCallback onTap, int badgeCount = 0}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            if (badgeCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  height: 8,
                  width: 8,
                  decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }


  Widget _buildBannerSection() {
    return SizedBox(
      height: 200,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('isOfferActive', isEqualTo: true)
            .limit(5)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return _placeholderBanner();
          }

          return PageView.builder(
            controller: _bannerController,
            physics: const PageScrollPhysics(), // Enable scrolling
            onPageChanged: (index) {
              setState(() {
                _currentBanner = index;
              });
            },
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final nameTa = data['name_ta'] as String? ?? '';
              final nameEn = data['name_en'] as String? ?? '';
              final offerType = data['offerType'] as String? ?? 'percentage';
              final offerVal = (data['offerValue'] as num? ?? 0).toDouble();

              final imageUrl = data['imageUrl'] as String?;

              String titleEn = '';
              String titleTa = '';
              String subEn = 'Limited time offer! Buy now.';
              String subTa = 'சிறப்பு சலுகை! இன்றே வாங்குங்கள்.';

              if (offerType == 'percentage') {
                titleEn = "${offerVal.toStringAsFixed(0)}% ${LocalizationService.tr('stock_off_suffix')}";
                titleTa = "${offerVal.toStringAsFixed(0)}% தள்ளுபடி";
                subEn = "${LocalizationService.tr('on_preposition')} $nameEn";
                subTa = "$nameTa மீது";
              } else {
                titleEn = "₹${offerVal.toStringAsFixed(0)} ${LocalizationService.tr('suffix_only')}";
                titleTa = "₹${offerVal.toStringAsFixed(0)} ${LocalizationService.tr('suffix_only')}";
                 subEn = "${LocalizationService.tr('label_flat_price')} ${LocalizationService.tr('on_preposition')} $nameEn";
                subTa = "$nameTa ${LocalizationService.tr('label_special_offer')}";
              }

              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FarmerProductDetailsScreen(productId: docs[index].id, cropId: null), // [FIX] doc -> docs[index]
                      ),
                    );
                  },
                  child: _bannerCard(
                    titleTa: titleTa,
                    titleEn: titleEn,
                    subtitleTa: subTa,
                    subtitleEn: subEn,
                    colorIndex: index,
                    offerType: offerType,
                    imageUrl: imageUrl,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _placeholderBanner() {
    return _bannerCard(
      titleTa: LocalizationService.tr('home_special_offers'),
      titleEn: LocalizationService.tr('banner_placeholder_title_en'),
      subtitleTa: LocalizationService.tr('banner_placeholder_subtitle_ta'),
      subtitleEn: LocalizationService.tr('banner_placeholder_subtitle_en'),
      colorIndex: 0,
    );
  }

  Widget _bannerCard({
    required String titleTa,
    required String titleEn,
    required String subtitleTa,
    required String subtitleEn,
    required int colorIndex,
    String? offerType,
    String? imageUrl,
  }) {
    final isTa = LocalizationService.isTamil;
    final title = LocalizationService.pickTaEn(titleTa, titleEn);
    final subtitle = LocalizationService.pickTaEn(subtitleTa, subtitleEn);
    
    // Modern gradients
    final gradients = [
      const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)]),
      const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF42A5F5)]),
      const LinearGradient(colors: [Color(0xFFE65100), Color(0xFFFFA726)]),
    ];
    final gradient = gradients[colorIndex % gradients.length];

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Text(
                    (offerType == 'flat' ? LocalizationService.tr('label_special_offer') : LocalizationService.tr('label_big_sale')).toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: isTa
                      ? GoogleFonts.notoSansTamil(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        )
                      : GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: isTa
                      ? GoogleFonts.notoSansTamil(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                        )
                      : GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Image or Icon
          Container(
            width: 130, // [UPDATED] Increased size
            height: 130,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
              ],
            ),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? CommonImage(
                    imageUrl: imageUrl,
                    width: 130,
                    height: 130,
                    borderRadius: BorderRadius.circular(16),
                    fit: BoxFit.cover,
                  )
                : Icon(
                    Icons.local_offer,
                    color: gradient.colors.last,
                    size: 50,
                  ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _quickActionCard(
          icon: Icons.storefront_outlined,
          titleTa: LocalizationService.tr('home_products'),
          titleEn: LocalizationService.tr('home_products_sub'),
          color: const Color(0xFFE8F5E9), // Light Green
          iconColor: const Color(0xFF2E7D32),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FarmerCategoriesScreen(showBack: true))),
        ),

        _quickActionCard(
          icon: Icons.history_outlined,
          titleTa: LocalizationService.tr('home_rebuy'),
          titleEn: LocalizationService.tr('home_rebuy_sub'),
          color: const Color(0xFFE3F2FD), // Light Blue
          iconColor: const Color(0xFF1565C0),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FarmerRebuyScreen())),
        ),
        _quickActionCard(
          icon: Icons.receipt_long_outlined,
          titleTa: LocalizationService.tr('home_my_orders'),
          titleEn: LocalizationService.tr('home_my_orders_sub'),
          color: const Color(0xFFF3E5F5), // Light Purple
          iconColor: const Color(0xFF7B1FA2),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FarmerOrdersScreen())),
        ),
        _quickActionCard(
          icon: Icons.medical_services_outlined,
          titleTa: LocalizationService.isTamil ? 'நோய் மற்றும் மருந்தளவு' : 'Disease & Dosage',
          titleEn: LocalizationService.isTamil ? 'D&D' : 'Dosage Advice',
          color: const Color(0xFFFFEBEE), // Light Red
          iconColor: const Color(0xFFC62828),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FarmerDiseaseListScreen())),
        ),
        _quickActionCard( // [NEW] Feedback
          icon: Icons.feedback_outlined,
          titleTa: LocalizationService.isTamil ? 'கருத்து/புகார்' : 'Feedback/Issues',
          titleEn: 'Feedback',
          color: const Color(0xFFFFF3E0), // Light Orange
          iconColor: const Color(0xFFE65100),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LocalizationService.isTamil ? 'விரைவில்...' : 'Feature Coming Soon. Call Store.')));
          },
        ),
        _quickActionCard( // [NEW] Smart Offers
          icon: Icons.local_offer_outlined,
          titleTa: LocalizationService.isTamil ? 'சிறப்பு சலுகைகள்' : 'Special Offers',
          titleEn: 'Smart Offers',
          color: const Color(0xFFE0F7FA), // Light Cyan
          iconColor: const Color(0xFF00838F),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LocalizationService.isTamil ? 'புதிய சலுகைகள் இல்லை' : 'No new offers available.')));
          },
        ),
        _quickActionCard( // [NEW] Land Calculator
          icon: Icons.calculate_outlined,
          titleTa: LocalizationService.isTamil ? 'உர கணக்கீட்டாளர்' : 'Product Calculator',
          titleEn: 'Land Calc',
          color: const Color(0xFFF3E5F5), // Light purple
          iconColor: const Color(0xFF6A1B9A),
          onTap: () => _showLandCalculator(context),
        ),
      ],
    );
  }

  Widget _quickActionCard({
    required IconData icon,
    required String titleTa,
    required String titleEn,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final isTa = LocalizationService.isTamil;
    final primary = isTa ? titleTa : titleEn;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
             BoxShadow(
              color: const Color(0xFF1E293B).withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const Spacer(),
            Text(
              primary,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.2,
               ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
             Container(
               width: 24,
               height: 3,
               decoration: BoxDecoration(
                 color: iconColor.withOpacity(0.3),
                 borderRadius: BorderRadius.circular(2),
               ),
             )
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    final isTa = LocalizationService.isTamil;
    final subtitle = LocalizationService.pickTaEn(
      LocalizationService.tr('weather_today_line_ta'),
      LocalizationService.tr('weather_today_line_en'),
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF0277BD), Color(0xFF01579B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF01579B).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
             child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                         color: Colors.white.withOpacity(0.2),
                         borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        LocalizationService.tr('label_weather_update').toUpperCase(),
                        style: GoogleFonts.inter(
                           fontSize: 10,
                           fontWeight: FontWeight.w800,
                           color: Colors.white,
                           letterSpacing: 1,
                        ),
                      ),
                   ),
                   const SizedBox(height: 16),
                   Text(
                   LocalizationService.tr('home_weather_today'),
                   style: GoogleFonts.outfit(
                       fontSize: 22,
                       color: Colors.white,
                       fontWeight: FontWeight.bold,
                   ),
                 ),
                 const SizedBox(height: 4),
                 Text(
                   subtitle,
                   style: GoogleFonts.inter(
                       fontSize: 14,
                       color: Colors.white.withOpacity(0.8),
                       height: 1.4,
                   ),
                 ),
                ],
             ),
          ),
          Container(
             height: 64,
             width: 64,
             decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.1)),
             ),
             child: const Icon(Icons.wb_sunny_rounded, color: AppColors.accent, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvisorySection() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('advisories')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
           return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
        }

        final doc = snapshot.data?.docs.isNotEmpty == true
            ? snapshot.data!.docs.first
            : null;

        if (doc == null) {
          return _advisoryCard(
            titleTa: LocalizationService.tr('nav_advisory'),
            titleEn: LocalizationService.isTamil ? 'AI பயிர் மருத்துவர்' : 'AI Plant Doctor',
            messageTa: LocalizationService.tr('msg_advisory_empty_desc'),
            messageEn: LocalizationService.tr('msg_advisory_empty_desc'),
          );
        }

        final data = doc.data();
        return _advisoryCard(
          titleTa: data['title_ta'] as String? ?? '',
          titleEn: data['title_en'] as String? ?? '',
          messageTa: data['message_ta'] as String? ?? '',
          messageEn: data['message_en'] as String? ?? '',
        );
      },
    );
  }

  Widget _advisoryCard({
    required String titleTa,
    required String titleEn,
    required String messageTa,
    required String messageEn,
  }) {
    final isTa = LocalizationService.isTamil;
    final title = LocalizationService.pickTaEn(titleTa, titleEn);
    final message = LocalizationService.pickTaEn(messageTa, messageEn);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1), // Very light yellow
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD54F), width: 1),
        boxShadow: [
           BoxShadow(
              color: const Color(0xFFFFD54F).withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
           )
        ]
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD54F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.campaign_outlined, color: Color(0xFFF57F17), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocalizationService.tr('label_latest_alert'),
                       style: GoogleFonts.poppins(
                         fontSize: 10,
                         fontWeight: FontWeight.w800,
                         color: const Color(0xFFF57F17),
                         letterSpacing: 1,
                       ),
                    ),
                    Text(
                      title,
                      style: isTa
                          ? GoogleFonts.notoSansTamil(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                               color: const Color(0xFF4F3A00),
                            )
                          : GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                               color: const Color(0xFF4F3A00),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              message,
              style: isTa
                  ? GoogleFonts.notoSansTamil(fontSize: 14, color: const Color(0xFF5D4037))
                  : GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF5D4037)),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
           const SizedBox(height: 16),
           SizedBox(
             width: double.infinity,
             child: OutlinedButton(
               onPressed: () {
                  // Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FarmerAiPlantDoctorScreen()));
               },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFFA000)),
                   foregroundColor: const Color(0xFFE65100),
                   padding: const EdgeInsets.symmetric(vertical: 14),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                   textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600)
                ),
               child: Text(
                 LocalizationService.tr('home_view_all'), // reusing "View all" logic or similar
                  style: isTa ? GoogleFonts.notoSansTamil(fontSize: 14, fontWeight: FontWeight.bold) : null,
               ),
             ),
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final doc = snapshot.data?.docs.isNotEmpty == true
            ? snapshot.data!.docs.first
            : null;

        if (doc == null) {
          return Center(
             child: Text(
            LocalizationService.tr('msg_no_recent_orders'),
            style: GoogleFonts.notoSansTamil(fontSize: 14, color: AppColors.textSecondary),
          ));
        }

        final data = doc.data();
        final status = data['status'] as String? ?? 'reserved';
        final total = data['totalAmount'] as num? ?? 0;
        final items = (data['items'] as List<dynamic>? ?? []);
        final firstItem = items.isNotEmpty ? items.first as Map<String, dynamic> : null;
        final nameTa = firstItem?['name_ta'] as String? ?? '';
        final nameEn = firstItem?['name_en'] as String? ?? '';
        final isTa = LocalizationService.isTamil;
        final name = (nameTa.isNotEmpty || nameEn.isNotEmpty)
            ? LocalizationService.pickTaEn(nameTa, nameEn)
            : LocalizationService.tr('title_my_orders');
        final totalLabel = LocalizationService.tr('label_total');
        final statusLabel = LocalizationService.tr('label_status');

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FarmerOrderTrackingScreen(orderId: doc.id),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: isTa
                          ? GoogleFonts.notoSansTamil(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            )
                          : GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                     totalLabel,
                      style: GoogleFonts.notoSansTamil(fontSize: 13, color: AppColors.textSecondary),
                   ),
                   Text(
                    '₹$total',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      },
    );
  }

  Widget _buildShopStatusIndicator() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('shop_settings').doc('current').snapshots(),
      builder: (context, snapshot) {
        final isOpen = (snapshot.data?.data() as Map<String, dynamic>?)?['isOpen'] ?? true;
        final isTa = LocalizationService.isTamil;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isOpen ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isOpen ? Colors.green.shade200 : Colors.red.shade200),
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
                  isOpen ? Icons.store_outlined : Icons.remove_shopping_cart_outlined,
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
                        ? (isTa ? 'கடை திறந்துள்ளது' : 'Shop is Open')
                        : (isTa ? 'கடை மூடப்பட்டுள்ளது' : 'Shop is Closed'),
                      style: GoogleFonts.notoSansTamil(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isOpen ? Colors.green.shade900 : Colors.red.shade900,
                      ),
                    ),
                    Text(
                      isOpen 
                        ? (isTa ? 'ஆன்லைனில் ஆர்டர்களை ஏற்கிறோம்' : 'Accepting orders online')
                        : (isTa ? 'மீண்டும் விரைவில் திறக்கப்படும்' : 'Will reopen soon'),
                      style: GoogleFonts.notoSansTamil(
                        fontSize: 12,
                        color: isOpen ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isOpen)
                Icon(Icons.info_outline, color: Colors.red.shade300, size: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPopularBrands(bool isTa) {
    final brands = [
      {'name': 'Syngenta', 'logo': 'S'},
      {'name': 'Mahyco', 'logo': 'M'},
      {'name': 'Bayer', 'logo': 'B'},
      {'name': 'Rasi Seeds', 'logo': 'R'},
      {'name': 'Advanta', 'logo': 'A'},
      {'name': 'Kaveri', 'logo': 'K'},
      {'name': 'IFFCO', 'logo': 'I'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(isTa ? 'பிரபலமான பிராண்டுகள்' : 'Popular Brands'),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            scrollDirection: Axis.horizontal,
            itemCount: brands.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final brand = brands[index];
              return Column(
                children: [
                   InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FarmerProductListScreen(brand: brand['name']),
                        ),
                      );
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Center(
                        child: Text(
                          brand['logo']!,
                          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    brand['name']!,
                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHotSellingSection(bool isTa) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(isTa ? 'அதிகம் விற்கப்படுபவை' : 'Hot Selling Products'),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .where('salesCount', isGreaterThanOrEqualTo: 10)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                // If no high sales products, show latest products instead
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('products')
                      .orderBy('price', descending: true) // Just a placeholder order
                      .limit(5)
                      .snapshots(),
                  builder: (context, snapshot2) {
                    if (!snapshot2.hasData) return const SizedBox();
                    return _buildProductListView(snapshot2.data!.docs);
                  }
                );
              }
              return _buildProductListView(snapshot.data!.docs);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductListView(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      scrollDirection: Axis.horizontal,
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        return SizedBox(
          width: 160,
          child: ProductGridCard(
            productId: docs[index].id,
            data: docs[index].data(),
          ),
        );
      },
    );
  }

  // Categories section removed from dashboard as requested.
}

class _SeasonalKitsSection extends StatelessWidget {
  const _SeasonalKitsSection();

  @override
  Widget build(BuildContext context) {
    final isTa = LocalizationService.isTamil;
    // Mock data for seasonal kits
    final kits = [
      {'name_en': 'Paddy Sowing Kit', 'name_ta': 'நெல் விதைப்பு கிட்', 'items': 'Seeds, Base Fertilizer', 'color': Colors.green.shade50},
      {'name_en': 'Tomato Care Kit', 'name_ta': 'தக்காளி பராமரிப்பு கிட்', 'items': 'Fungicide, Booster', 'color': Colors.orange.shade50},
    ];

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: kits.length,
        itemBuilder: (context, i) {
          final kit = kits[i];
          return Container(
            width: 200,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kit['color'] as Color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    const Icon(Icons.eco, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(child: Text(isTa ? kit['name_ta'] as String : kit['name_en'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                  ],
                ),
                const SizedBox(height: 8),
                Text(kit['items'] as String, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CropStageGuideSection extends StatefulWidget {
  const _CropStageGuideSection();

  @override
  State<_CropStageGuideSection> createState() => _CropStageGuideSectionState();
}

class _CropStageGuideSectionState extends State<_CropStageGuideSection> {
  DateTime? _sowingDate;
  bool _isLoading = true;
  String _cropName = 'Paddy';
  List<Map<String, dynamic>> _cropStages = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      if (data != null) {
        if (data.containsKey('sowingDate')) {
          _sowingDate = (data['sowingDate'] as Timestamp?)?.toDate();
        }
        if (data.containsKey('activeCrop')) {
          _cropName = data['activeCrop'] as String;
        }
        if (data.containsKey('cropStages')) {
           _cropStages = List<Map<String, dynamic>>.from(data['cropStages']);
        }
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _changeCrop(bool isTa) async {
     final snapshot = await FirebaseFirestore.instance.collection('crop_guides').get();
     final crops = snapshot.docs.map((doc) => {
        'en': doc.data()['cropNameEn'] as String,
        'ta': doc.data()['cropNameTa'] as String,
        'docId': doc.id,
     }).toList();

     if (crops.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isTa ? 'வழிகாட்டிகள் எதுவும் இல்லை' : 'No guides available!')));
        return;
     }

     final selected = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        builder: (ctx) => ListView.builder(
           shrinkWrap: true,
           itemCount: crops.length,
           itemBuilder: (c, i) => ListTile(
              title: Text((isTa && crops[i]['ta'] != null ? crops[i]['ta'] : crops[i]['en'])?.toString() ?? ""),
              onTap: () => Navigator.pop(ctx, crops[i]),
           )
        )
     );

     if (selected != null) {
        final cropName = (isTa && selected['ta'] != null ? selected['ta'] : selected['en'])?.toString() ?? "";
        setState(() => _cropName = cropName);
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
           await FirebaseFirestore.instance.collection('users').doc(uid).set({
              'activeCrop': cropName,
              'activeCropId': selected['docId'],
              'cropStages': [], // Reset stages for new crop
           }, SetOptions(merge: true));
        }
     }
  }

  Future<void> _setSowingDate(BuildContext context, bool isTa) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final activeCropId = userDoc.data()?['activeCropId'] as String?;
      
      List<Map<String, dynamic>> fetchedStages = [];
      if (activeCropId != null) {
        final guideDoc = await FirebaseFirestore.instance.collection('crop_guides').doc(activeCropId).get();
        if (guideDoc.exists) {
          final stages = guideDoc.data()?['stages'] as List<dynamic>?;
          if (stages != null) {
            fetchedStages = stages.map((s) => Map<String, dynamic>.from(s)).toList();
          }
        }
      }

      setState(() {
        _sowingDate = picked;
        _cropStages = fetchedStages;
      });

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'sowingDate': picked,
        'activeCrop': _cropName,
        'cropStages': _cropStages,
      }, SetOptions(merge: true));

      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isTa ? 'விதைப்பு நாள் சேமிக்கப்பட்டது' : 'Sowing Date Saved! Calendar Started.')));
      }
    }
  }

  Future<void> _toggleStageTask(int index) async {
     setState(() {
        _cropStages[index]['isDone'] = !(_cropStages[index]['isDone'] as bool? ?? false);
     });
     final uid = FirebaseAuth.instance.currentUser?.uid;
     if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
           'cropStages': _cropStages,
        });
     }
  }

  Future<void> _addCustomTask(bool isTa) async {
     final titleCtrl = TextEditingController();
     final descCtrl = TextEditingController();
     final dayCtrl = TextEditingController();

     final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
           title: Text(isTa ? 'புதிய பணியைச் சேர்' : 'Add New Task'),
           content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                 TextField(controller: titleCtrl, decoration: InputDecoration(labelText: isTa ? 'பணி (எ.கா: நீர்ப்பாசனம்)' : 'Task (e.g., Watering)')),
                 TextField(controller: descCtrl, decoration: InputDecoration(labelText: isTa ? 'பரிந்துரை / குறிப்பு' : 'Recommendation / Note')),
                 TextField(controller: dayCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: isTa ? 'எந்த நாளில்? (எ.கா: 5)' : 'Day Number (e.g., 5)')),
              ],
           ),
           actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isTa ? 'ரத்து' : 'Cancel')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(isTa ? 'சேமி' : 'Save')),
           ],
        )
     );

     if (result == true && titleCtrl.text.isNotEmpty && dayCtrl.text.isNotEmpty) {
        final day = int.tryParse(dayCtrl.text) ?? 1;
        setState(() {
           _cropStages.add({
              'id': DateTime.now().millisecondsSinceEpoch.toString(),
              'titleTa': 'நாள் $day - ${titleCtrl.text}',
              'titleEn': 'Day $day - ${titleCtrl.text}',
              'descEn': descCtrl.text,
              'day': day,
              'isDone': false,
           });
           _cropStages.sort((a, b) => (a['day'] as int).compareTo(b['day'] as int));
        });
        
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
           await FirebaseFirestore.instance.collection('users').doc(uid).update({
              'cropStages': _cropStages,
           });
        }
     }
  }

  Future<void> _resetDiary(bool isTa) async {
     final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
           title: Text(isTa ? 'நிச்சயமாக அழிக்க விரும்புகிறீர்களா?' : 'Reset Diary?'),
           content: Text(isTa ? 'உங்கள் தற்போதைய பயிர் நாட்குறிப்பு அழிக்கப்படும்.' : 'Your current crop timeline will be reset.'),
           actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isTa ? 'ரத்து' : 'Cancel')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(isTa ? 'அழி' : 'Reset')),
           ],
        )
     );
     
     if (confirm == true) {
        setState(() => _sowingDate = null);
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
           await FirebaseFirestore.instance.collection('users').doc(uid).update({
              'sowingDate': FieldValue.delete(),
           });
        }
     }
  }

  @override
  Widget build(BuildContext context) {
    final isTa = LocalizationService.isTamil;
    int currentDay = 0;
    if (_sowingDate != null) {
       currentDay = DateTime.now().difference(_sowingDate!).inDays + 1;
       if (currentDay < 0) currentDay = 0;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green.shade100, width: 2),
        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Row(
                        children: [
                           Text(isTa ? 'பயிர்: $_cropName' : 'Crop: $_cropName', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                           const SizedBox(width: 8),
                           InkWell(
                              onTap: () => _changeCrop(isTa),
                              child: Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                 decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade300)),
                                 child: const Icon(Icons.edit, size: 12, color: Colors.grey),
                              ),
                           )
                        ],
                     ),
                     Text(isTa ? 'தனிப்பயனாக்கப்பட்ட பயிர் வழிகாட்டி' : 'Personalised Crop Guide', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                   ],
                 ),
              ),
              if (_sowingDate != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.shade200)),
                  child: Row(
                    children: [
                      const Icon(Icons.timer, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text('Day $currentDay', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          
          if (_isLoading)
             const Center(child: CircularProgressIndicator())
          else if (_sowingDate == null) ...[
             Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(16)),
                child: Column(
                   children: [
                      Icon(Icons.calendar_month, size: 40, color: Colors.orange.shade400),
                      const SizedBox(height: 8),
                      Text(isTa ? 'உங்கள் பயிர் நாட்குறிப்பைத் தொடங்கவும்' : 'Start your farming timeline', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                         onPressed: () => _setSowingDate(context, isTa),
                         style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade600, foregroundColor: Colors.white),
                         child: Text(isTa ? 'விதைப்பு நாளைத் தேர்ந்தெடுக்கவும்' : 'Set Sowing Date'),
                      )
                   ],
                ),
             )
          ] else ...[
             // Dynamic Timeline Logic
             for (int i = 0; i < _cropStages.length; i++)
               _buildDynamicTimelineItem(_cropStages[i], i, currentDay, isTa, isLast: i == _cropStages.length - 1),

             const SizedBox(height: 16),
             Row(
                children: [
                   Expanded(
                      child: OutlinedButton.icon(
                          onPressed: () => _addCustomTask(isTa),
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(isTa ? 'பணியைச் சேர்' : 'Add Task'),
                          style: OutlinedButton.styleFrom(
                             foregroundColor: Colors.purple.shade700,
                             side: BorderSide(color: Colors.purple.shade200),
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                      ),
                   ),
                   const SizedBox(width: 8),
                   Expanded(
                      child: OutlinedButton.icon(
                          onPressed: () {
                             if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isTa ? 'உரங்கள் கடையில் முன்னிலைப்படுத்தப்பட்டது' : 'Requested products marked in shop list!')));
                             }
                          },
                          icon: const Icon(Icons.add_shopping_cart, size: 18),
                          label: Text(isTa ? 'வாங்க' : 'Buy Items'),
                          style: OutlinedButton.styleFrom(
                             foregroundColor: Colors.green.shade700,
                             side: BorderSide(color: Colors.green.shade200),
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                      ),
                   ),
                   IconButton(
                      onPressed: () => _resetDiary(isTa),
                      icon: const Icon(Icons.refresh),
                      color: Colors.red.shade300,
                      tooltip: isTa ? 'மீட்டமை' : 'Reset Diary',
                   )
                ],
             ),
          ]
        ],
      ),
    );
  }

  Widget _buildDynamicTimelineItem(Map<String, dynamic> stage, int index, int currentDay, bool isTa, {bool isLast = false}) {
    final dayTarget = stage['day'] as int;
    final isDone = stage['isDone'] as bool? ?? false;
    final isActionNeeded = currentDay >= dayTarget && !isDone;
    final color = isDone ? Colors.green : (isActionNeeded ? Colors.amber.shade700 : Colors.grey.shade400);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            InkWell(
              onTap: () => _toggleStageTask(index),
              child: Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                   shape: BoxShape.circle, 
                   color: isDone ? Colors.green : (isActionNeeded ? Colors.amber.shade100 : Colors.white), 
                   border: Border.all(color: color, width: 2)
                ),
                child: isDone 
                   ? const Icon(Icons.check, size: 14, color: Colors.white) 
                   : (isActionNeeded ? const Icon(Icons.circle, size: 10, color: Colors.amber) : null),
              ),
            ),
            if (!isLast) Container(width: 2, height: 40, color: isDone ? Colors.green : Colors.grey.shade200),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                      Text(
                         isTa ? (stage['titleTa'] ?? stage['titleEn']) : stage['titleEn'], 
                         style: TextStyle(fontWeight: currentDay >= dayTarget ? FontWeight.bold : FontWeight.w600, fontSize: 14, color: currentDay >= dayTarget || isDone ? Colors.black : Colors.grey.shade500)
                      ),
                      if (isActionNeeded)
                         Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.amber.shade200)),
                            child: Text(isTa ? 'இப்போது' : 'Action Needed', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade800)),
                         )
                   ],
                ),
                const SizedBox(height: 4),
                Text(
                   '${isTa ? "பரிந்துரை:" : "Recommended:"} ${stage['descEn']}', 
                   style: TextStyle(fontSize: 12, color: currentDay >= dayTarget || isDone ? Colors.grey.shade700 : Colors.grey.shade400)
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WeatherProductPromoSection extends StatelessWidget {
  const _WeatherProductPromoSection();

  @override
  Widget build(BuildContext context) {
    final isTa = LocalizationService.isTamil;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.lightBlue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.lightBlue.shade100),
      ),
      child: Row(
        children: [
          Container(
             padding: const EdgeInsets.all(8),
             decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black.withOpacity(0.05))]),
             child: const Icon(Icons.umbrella, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isTa ? 'மழை எதிர்பார்க்கப்படுகிறது!' : 'Rain Expected Soon!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                Text(isTa ? 'பூஞ்சாணக்கல்லிகளை இப்போதே வாங்கவும்' : 'Protect your crops with Fungicides', style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
              ],
            ),
          ),
          TextButton(
             onPressed: () {},
             child: Text(isTa ? 'காண்க' : 'View', style: const TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}

void _showLandCalculator(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) {
       final isTa = LocalizationService.isTamil;
       double acres = 2.0;
       return StatefulBuilder(
          builder: (context, setState) {
             return Container(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
                child: Column(
                   mainAxisSize: MainAxisSize.min,
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      Row(
                         children: [
                            const Icon(Icons.calculate, color: Colors.purple, size: 28),
                            const SizedBox(width: 8),
                            Text(isTa ? 'ஸ்மார்ட் கணக்கீட்டாளர்' : 'Smart Product Calculator', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                         ],
                      ),
                      const SizedBox(height: 24),
                      Text(isTa ? 'உங்கள் நிலத்தின் அளவு (ஏக்கர்)' : 'Enter Land Size (Acres)', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Slider(
                         value: acres,
                         min: 0.5,
                         max: 10.0,
                         divisions: 19,
                         label: '$acres Acres',
                         activeColor: Colors.purple,
                         onChanged: (val) {
                            setState(() => acres = val);
                         },
                      ),
                      Center(child: Text('${acres.toStringAsFixed(1)} ${isTa ? 'ஏக்கர்' : 'Acres'}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                      const SizedBox(height: 24),
                      Container(
                         padding: const EdgeInsets.all(16),
                         decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                         child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                               Text(isTa ? 'தேவையான பொருட்கள் (நெல்):' : 'Estimated Requirement (Paddy):', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                               const Divider(),
                               _calcRow('Paddy Seeds', '${(acres * 8).toStringAsFixed(0)} kg'),
                               _calcRow('Urea Fertilizer', '${(acres * 1.5).toStringAsFixed(1)} Bags'),
                               _calcRow('Pesticide', '${(acres * 500).toStringAsFixed(0)} ml'),
                            ],
                         ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(isTa ? 'மூடு' : 'Done'))),
                      const SizedBox(height: 24),
                   ],
                ),
             );
          }
       );
    }
  );
}

Widget _calcRow(String item, String qty) {
   return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
         mainAxisAlignment: MainAxisAlignment.spaceBetween,
         children: [
            Text(item, style: TextStyle(color: Colors.grey.shade700)),
            Text(qty, style: const TextStyle(fontWeight: FontWeight.bold)),
         ],
      ),
   );
}

