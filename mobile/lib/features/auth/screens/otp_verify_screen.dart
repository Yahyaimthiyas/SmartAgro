import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';

class OtpVerifyScreen extends StatefulWidget {
  const OtpVerifyScreen({super.key});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final TextEditingController _otpController = TextEditingController();
  Timer? _timer;
  int _remainingSeconds = 120; // 2 minutes

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = 120;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        setState(() {
          _remainingSeconds = 0;
        });
        timer.cancel();
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  void _verify() async {
    if (_otpController.text.length == 6) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final success = await auth.verifyOtp(_otpController.text);
      
      if (!mounted) return;
      
      if (success) {
        final role = await auth.getUserRole();
        if (!mounted) return;
        if (role == 'owner') {
          Navigator.pushNamedAndRemoveUntil(context, '/owner-secure', (route) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid OTP")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final minutesStr = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final secondsStr = (_remainingSeconds % 60).toString().padLeft(2, '0');

    final defaultPinTheme = PinTheme(
      width: 50,
      height: 50,
      textStyle: GoogleFonts.poppins(fontSize: 20, color: Color.fromRGBO(30, 60, 87, 1), fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        border: Border.all(color: Color.fromRGBO(234, 239, 243, 1)),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: AppColors.primary),
      borderRadius: BorderRadius.circular(8),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: Color.fromRGBO(234, 239, 243, 1),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          LocalizationService.tr('otp_verify'),
          style: GoogleFonts.notoSansTamil(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                LocalizationService.tr('enter_otp'),
                style: GoogleFonts.notoSansTamil(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                LocalizationService.tr('enter_otp_subtitle'),
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansTamil(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // OTP Fields
              Pinput(
                length: 6,
                controller: _otpController,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                submittedPinTheme: submittedPinTheme,
                onCompleted: (pin) => _verify(),
              ),
              const SizedBox(height: 24),

              // Explicit Verify button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Verify OTP',
                    style: GoogleFonts.notoSansTamil(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              
              // Timer
              Text(
                LocalizationService.tr('time_remaining'),
                style: GoogleFonts.notoSansTamil(fontSize: 14, color: Colors.black),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTimerBox(minutesStr),
                  const SizedBox(width: 8),
                  Text(':', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  _buildTimerBox(secondsStr),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 50, child: Text(LocalizationService.tr('minutes'), textAlign: TextAlign.center, style: GoogleFonts.notoSansTamil(fontSize: 10))),
                  const SizedBox(width: 20),
                  SizedBox(width: 50, child: Text(LocalizationService.tr('seconds'), textAlign: TextAlign.center, style: GoogleFonts.notoSansTamil(fontSize: 10))),
                ],
              ),
              
              const SizedBox(height: 60),
              
              Text(
                LocalizationService.tr('otp_not_received'),
                style: GoogleFonts.notoSansTamil(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Resend Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _remainingSeconds == 0
                      ? () async {
                          _startTimer();
                          final auth = Provider.of<AuthProvider>(context, listen: false);
                          await auth.resendOtp(
                            (verificationId) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('OTP resent successfully')),
                              );
                            },
                            (error) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error)),
                              );
                            },
                          );
                        }
                      : null,
                  icon: const Icon(Icons.refresh, color: Colors.black),
                  label: Text(
                    LocalizationService.tr('resend_otp'),
                    style: GoogleFonts.notoSansTamil(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerBox(String value) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Center(
        child: Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
