import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import '../../auth/providers/auth_provider.dart' as app_auth;
import 'farmer_profile_setup_screen.dart';
import 'static_content_screen.dart'; // [NEW]
import '../orders/farmer_orders_screen.dart';

class FarmerProfileScreen extends StatelessWidget {
  const FarmerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // Removed unused isTa

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            LocalizationService.tr('profile_appbar_title'),
            style: GoogleFonts.notoSansTamil(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Text(
            LocalizationService.tr('profile_please_login_again'),
            style: GoogleFonts.notoSansTamil(fontSize: 14),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          LocalizationService.tr('profile_appbar_title'),
          style: GoogleFonts.notoSansTamil(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildUserHeader(user),
            const SizedBox(height: 32),
            _buildMenuCard(
               context, 
               icon: Icons.edit_location_alt_outlined, 
               title: LocalizationService.tr('profile_menu_edit'),
               onTap: () {
                 Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const FarmerProfileSetupScreen(mode: ProfileSetupMode.basic),
                  ),
                );
               }
            ),
             const SizedBox(height: 16),
            _buildMenuCard(
               context, 
               icon: Icons.location_on_outlined, 
               title: LocalizationService.tr('profile_menu_address'),
               onTap: () {
                 Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const FarmerProfileSetupScreen(mode: ProfileSetupMode.full),
                  ),
                );
               }
            ),
             const SizedBox(height: 16),
            _buildMenuCard(
               context, 
               icon: Icons.receipt_long_rounded, 
               title: LocalizationService.tr('profile_my_orders'),
               onTap: () {
                 Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const FarmerOrdersScreen(),
                  ),
                );
               }
            ),
             const SizedBox(height: 16),
            _buildMenuCard(
               context, 
               icon: Icons.language_rounded, 
               title: LocalizationService.tr('profile_language'),
               onTap: () => _showLanguageSheet(context),
            ),
             const SizedBox(height: 16),
            _buildMenuCard(
               context, 
               icon: Icons.help_outline_rounded, 
               title: LocalizationService.tr('profile_menu_help'),
               onTap: () {
                 Navigator.of(context).push(
                   MaterialPageRoute(
                     builder: (_) => StaticContentScreen(
                       titleKey: 'profile_menu_help',
                       contentKey: 'help_content',
                     ),
                   ),
                 );
               },
            ),
             const SizedBox(height: 16),
            _buildMenuCard(
               context, 
               icon: Icons.info_outline_rounded, 
               title: LocalizationService.tr('profile_menu_about'),
               onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: LocalizationService.tr('app_name'),
                    applicationVersion: '1.0.0',
                    applicationLegalese: '© 2026 SmartAgro Inc.',
                  );
               },
            ),
             const SizedBox(height: 16),
            _buildMenuCard(
               context, 
               icon: Icons.privacy_tip_outlined, 
               title: LocalizationService.tr('profile_menu_privacy'),
               onTap: () {
                 Navigator.of(context).push(
                   MaterialPageRoute(
                     builder: (_) => StaticContentScreen(
                       titleKey: 'profile_menu_privacy',
                       contentKey: 'privacy_content',
                     ),
                   ),
                 );
               },
            ),
            const SizedBox(height: 40),
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(User user) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        String? name;
        String? phone = user.phoneNumber;
        String role = 'farmer';

        if (snapshot.hasData && snapshot.data!.data() != null) {
          final data = snapshot.data!.data()!;
          name = data['name'] as String?;
          phone = data['phone'] as String? ?? phone;
          role = data['role'] as String? ?? role;
        }

        final displayName = name ?? phone ?? '';
        final roleLabel = role == 'owner'
            ? LocalizationService.tr('profile_role_owner')
            : LocalizationService.tr('profile_role_farmer');

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primaryLight,
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: 50,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              displayName,
              style: GoogleFonts.notoSansTamil(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                roleLabel.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (phone != null) ...[
               const SizedBox(height: 8),
               Text(
                phone,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMenuCard(BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
       onTap: onTap,
       borderRadius: BorderRadius.circular(20),
       child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
             color: Colors.white,
             borderRadius: BorderRadius.circular(20),
             boxShadow: [
                BoxShadow(
                   color: Colors.black.withOpacity(0.03),
                   blurRadius: 10,
                   offset: const Offset(0, 4)
                ),
             ],
          ),
          child: Row(
             children: [
                Container(
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                   ),
                   child: Icon(icon, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                   child: Text(
                      title,
                      style: GoogleFonts.notoSansTamil(
                         fontSize: 16,
                         fontWeight: FontWeight.w600,
                         color: AppColors.textPrimary
                      ),
                   ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Color(0xFFE0E0E0)),
             ],
          ),
       ),
    );
  }

  void _showLanguageSheet(BuildContext context) {
    final isTa = LocalizationService.isTamil;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text(
                    LocalizationService.tr('profile_language'),
                    style: GoogleFonts.notoSansTamil(
                       fontSize: 18,
                       fontWeight: FontWeight.bold
                    ),
                 ),
                 const SizedBox(height: 24),
                _languageOption(ctx, 'தமிழ்', 'ta', isTa),
                const SizedBox(height: 12),
                _languageOption(ctx, 'English', 'en', !isTa),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _languageOption(BuildContext ctx, String label, String code, bool isSelected) {
     return InkWell(
        onTap: () async {
           await LocalizationService.changeLocale(code);
           Navigator.of(ctx).pop();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
           padding: const EdgeInsets.all(16),
           decoration: BoxDecoration(
              border: Border.all(
                 color: isSelected ? AppColors.primary : Colors.grey.shade200,
                 width: isSelected ? 2 : 1
              ),
              borderRadius: BorderRadius.circular(16),
              color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white
           ),
           child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text(
                    label,
                    style: GoogleFonts.notoSansTamil(
                       fontSize: 16,
                       fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                       color: isSelected ? AppColors.primary : AppColors.textPrimary
                    ),
                 ),
                 if(isSelected)
                    const Icon(Icons.check_circle, color: AppColors.primary)
              ],
           ),
        ),
     );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: TextButton.icon(
        onPressed: () async {
          final auth = Provider.of<app_auth.AuthProvider>(context, listen: false);
          await auth.logout();
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        },
        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
        label: Text(
          LocalizationService.tr('profile_logout'),
          style: GoogleFonts.notoSansTamil(
             fontSize: 16,
             fontWeight: FontWeight.w600,
             color: Colors.redAccent
          ),
        ),
        style: TextButton.styleFrom(
          backgroundColor: Colors.redAccent.withOpacity(0.05),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
