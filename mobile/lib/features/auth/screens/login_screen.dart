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
              backgroundColor: AppColors.error,
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
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () {
               setState(() {
                  LocalizationService.toggleLanguage();
               });
            },
            icon: const Icon(Icons.language_rounded, size: 18),
            label: Text(isTa ? 'English' : 'தமிழ்', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              
              // App Branding
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.eco_rounded, color: AppColors.primary, size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                LocalizationService.tr('app_name'),
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                LocalizationService.tr('tagline'),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 60),

              // Welcome Text
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocalizationService.tr('welcome'),
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      LocalizationService.tr('enter_phone_subtitle'),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),

              // Phone Field
              _buildPhoneField(),
              
              const SizedBox(height: 48),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _getOtp,
                  child: Text(
                    LocalizationService.tr('get_otp'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              Text(
                isTa 
                  ? 'தொடர்வதன் மூலம், எங்கள் விதிமுறைகளை ஏற்கிறீர்கள்' 
                  : 'By continuing, you agree to our Terms of Service',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textPlaceholder,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Text('🇮🇳', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Text(
            '+91',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                counterText: "",
                hintText: "12345 67890",
                fillColor: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
