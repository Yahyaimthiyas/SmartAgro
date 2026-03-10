import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/colors.dart';
import '../../../core/widgets/common_image.dart';
import '../../../core/services/localization_service.dart';
import '../products/farmer_categories_screen.dart';
import '../products/farmer_product_details_screen.dart'; 
import '../orders/farmer_orders_screen.dart';
import '../orders/farmer_order_tracking_screen.dart'; 
import '../rebuy/farmer_rebuy_screen.dart';
import '../advisory/farmer_ai_plant_doctor_screen.dart';
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
                   _buildSectionHeader(LocalizationService.tr('home_special_offers')),
                  _buildBannerSection(),
                  const SizedBox(height: 32),
                  _buildSectionHeader(LocalizationService.tr('home_quick_actions')),
                  const SizedBox(height: 16),
                  _buildQuickActionsGrid(),
                   const SizedBox(height: 32),
                   const HomeWeatherWidget(), // Real widget
                   const SizedBox(height: 32),
                  _buildSectionHeader(LocalizationService.tr('home_advisory')),
                  const SizedBox(height: 16),
                  _buildAdvisorySection(),
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
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: LocalizationService.isTamil
              ? GoogleFonts.notoSansTamil(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                )
              : GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(User? user) {
    return SliverAppBar(
      expandedHeight: 110.0,
      floating: true,
      pinned: true,
      backgroundColor: AppColors.primary,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                 borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
            ),
            // Decorative circles
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
             Positioned(
              bottom: -20,
              left: -20,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
               padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
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
    final greetingPrefix = isTa
        ? LocalizationService.tr('home_greeting_ta_prefix')
        : LocalizationService.tr('home_greeting_en_prefix');

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
          ),
          child: const CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryLight,
            child: Icon(Icons.person, color: AppColors.primaryDark),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                greetingPrefix,
                style: GoogleFonts.notoSansTamil(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              Text(
                nameText,
                style: GoogleFonts.notoSansTamil(
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
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: StreamBuilder<List<AppNotification>>(
             stream: NotificationRepository().getUserNotifications(),
             builder: (context, snapshot) {
                int unreadCount = 0;
                if(snapshot.hasData) {
                   unreadCount = snapshot.data!.where((n) => !n.isRead).length;
                }

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const FarmerNotificationScreen(),
                          ),
                        );
                      },
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
             }
          ),
        ),
      ],
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
          icon: Icons.psychology_outlined,
          titleTa: LocalizationService.tr('home_ai_doctor'),
          titleEn: LocalizationService.tr('home_ai_doctor_sub'),
          color: const Color(0xFFFFF3E0), // Light Amber
          iconColor: const Color(0xFFFF8F00),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FarmerAiPlantDoctorScreen())),
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
    //final secondary = isTa ? titleEn : '';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
             BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    primary,
                    style: GoogleFonts.notoSansTamil(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                     ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                   const SizedBox(height: 4),
                   Container(
                     width: 20,
                     height: 4,
                     decoration: BoxDecoration(
                       color: iconColor.withOpacity(0.3),
                       borderRadius: BorderRadius.circular(2),
                     ),
                   )
                ],
              ),
            ),
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
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
             Colors.blue.shade700,
             Colors.blue.shade500,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
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
                         borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        LocalizationService.tr('label_weather_update'),
                        style: GoogleFonts.poppins(
                           fontSize: 10,
                           fontWeight: FontWeight.bold,
                           color: Colors.white,
                           letterSpacing: 1,
                        ),
                      ),
                   ),
                   const SizedBox(height: 12),
                   Text(
                   LocalizationService.tr('home_weather_today'),
                   style: isTa
                       ? GoogleFonts.notoSansTamil(
                           fontSize: 20,
                           color: Colors.white,
                           fontWeight: FontWeight.bold,
                         )
                       : GoogleFonts.poppins(
                           fontSize: 20,
                           color: Colors.white,
                           fontWeight: FontWeight.bold,
                         ),
                 ),
                 const SizedBox(height: 4),
                 Text(
                   subtitle,
                   style: isTa
                       ? GoogleFonts.notoSansTamil(
                           fontSize: 14,
                           color: Colors.white.withOpacity(0.9),
                         )
                       : GoogleFonts.poppins(
                           fontSize: 14,
                           color: Colors.white.withOpacity(0.9),
                         ),
                 ),
                ],
             ),
          ),
          Container(
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.3)),
             ),
             child: const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 40),
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
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FarmerAiPlantDoctorScreen()));
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
}
