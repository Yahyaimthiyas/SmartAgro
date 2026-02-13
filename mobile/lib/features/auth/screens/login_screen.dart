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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        }
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // For specific Tamil font usage throughout
    final isTa = LocalizationService.isTamil;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              // 1. Background Gradient Top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height * 0.45,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryDark,
                        AppColors.primary,
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.agriculture,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          LocalizationService.tr('app_name'),
                          style: GoogleFonts.notoSansTamil(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          LocalizationService.tr('tagline'),
                          style: GoogleFonts.notoSansTamil(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Content Card
              Positioned(
                top: MediaQuery.of(context).size.height * 0.40,
                left: 20,
                right: 20,
                bottom: 20,
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            LocalizationService.tr('welcome'),
                            textAlign: TextAlign.center,
                            style: isTa
                              ? GoogleFonts.notoSansTamil(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                )
                              : GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            LocalizationService.tr('enter_phone_subtitle'),
                            textAlign: TextAlign.center,
                            style: isTa
                              ? GoogleFonts.notoSansTamil(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                )
                              : GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                          ),
                          const SizedBox(height: 32),

                          // Phone Input Field
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7FA), // Very light greyish background
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.transparent),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '+91',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(width: 1.5, height: 30, color: Colors.grey[300]),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    maxLength: 10,
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.5,
                                    ),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                      counterText: "",
                                      hintText: "98765 43210",
                                      hintStyle: GoogleFonts.poppins(
                                        color: Colors.grey[400],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 32),

                          ElevatedButton(
                            onPressed: _getOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              elevation: 4,
                              shadowColor: AppColors.primary.withOpacity(0.4),
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  LocalizationService.tr('get_otp'),
                                  style: isTa
                                    ? GoogleFonts.notoSansTamil(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      )
                                    : GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(width: 12),
                                const Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                         // Help action
                      },
                      child: Text(
                        LocalizationService.tr('help_needed'),
                        style: isTa
                          ? GoogleFonts.notoSansTamil(
                              color: AppColors.textSecondary,
                              decoration: TextDecoration.underline,
                            )
                          : GoogleFonts.poppins(
                              color: AppColors.textSecondary,
                              decoration: TextDecoration.underline,
                            ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
