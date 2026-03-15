import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();

  void _getOtp() {
    if (_phoneController.text.length == 10) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      auth.verifyPhone(
        _phoneController.text,
        (verificationId) {
          if (!mounted) return;
          Navigator.pushNamed(context, '/otp');
        },
        (error) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      );
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
            content: Text(LocalizationService.isTamil ? 'செல்லுபடியாகும் எண்ணை உள்ளிடவும்' : 'Please enter a valid phone number'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.warning,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
         )
       );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTa = LocalizationService.isTamil;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Premium Background with Gradient & Pattern
          _buildBackground(size),

          // 2. Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.1),
                  
                  // App Branding
                  _buildBranding(isTa),
                  
                  SizedBox(height: size.height * 0.08),

                  // Login Form Card
                  _buildLoginCard(isTa),
                  
                  const SizedBox(height: 32),
                  
                  // Secondary Actions
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      LocalizationService.tr('help_needed'),
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(Size size) {
    return Positioned.fill(
      child: Stack(
        children: [
          // Primary Deep Green Block
          Container(
            height: size.height * 0.55,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, Color(0xFF00332B)],
              ),
            ),
          ),
          // Decorative Circles
          Positioned(
            top: -100,
            right: -100,
            child: CircleAvatar(
              radius: 200,
              backgroundColor: Colors.white.withOpacity(0.05),
            ),
          ),
          Positioned(
            top: 200,
            left: -50,
            child: CircleAvatar(
              radius: 100,
              backgroundColor: Colors.white.withOpacity(0.03),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranding(bool isTa) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: const Icon(
            Icons.eco_rounded,
            size: 64,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          LocalizationService.tr('app_name'),
          style: GoogleFonts.outfit(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          LocalizationService.tr('tagline'),
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white.withOpacity(0.8),
            letterSpacing: 2,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(bool isTa) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            LocalizationService.tr('welcome'),
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            LocalizationService.tr('enter_phone_subtitle'),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),

          // Custom Input Field
          Text(
            (isTa ? 'தொலைபேசி எண்' : 'Phone Number').toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildPhoneField(),
          
          const SizedBox(height: 40),

          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _getOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: AppColors.primary.withOpacity(0.4),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    LocalizationService.tr('get_otp'),
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Positioned(
                    right: 0,
                    child: Icon(Icons.arrow_forward_ios_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Text(
            '🇮🇳',
            style: TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 12),
          Text(
            '+91',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 24, color: AppColors.borderLight),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
                contentPadding: EdgeInsets.zero,
                counterText: "",
                hintText: "00000 00000",
                hintStyle: GoogleFonts.inter(
                  color: AppColors.textPlaceholder,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
