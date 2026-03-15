import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';

class AadharVerificationScreen extends StatefulWidget {
  final double requestedLiters;
  
  const AadharVerificationScreen({super.key, required this.requestedLiters});

  @override
  State<AadharVerificationScreen> createState() => _AadharVerificationScreenState();
}

class _AadharVerificationScreenState extends State<AadharVerificationScreen> {
  int _currentStep = 1; // 1: Aadhar, 2: Phone, 3: OTP
  final TextEditingController _aadharController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _verifyAadharLimit() async {
    final aadhar = _aadharController.text.trim();
    if (aadhar.length != 12 || !RegExp(r'^\d{12}$').hasMatch(aadhar)) {
      setState(() => _errorMessage = LocalizationService.isTamil ? 'சரியான 12-இலக்க ஆதார் எண் உள்ளிடவும்' : 'Enter a valid 12-digit Aadhar number');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 1. Fetch or create mock Aadhar Details
      final aadharDetailsRef = FirebaseFirestore.instance.collection('aadhar_details').doc(aadhar);
      var aadharDetailsDoc = await aadharDetailsRef.get();
      if (!aadharDetailsDoc.exists) {
        // Auto-create a sample Aadhar card data for test purposes
        await aadharDetailsRef.set({
          'name': 'Farmer Name',
          'dob': '01-01-1980',
          'gender': 'Male',
          'address': '123 Main St, Agri Village, TN',
          'phone': '9876543210',
          'createdAt': FieldValue.serverTimestamp(),
        });
        aadharDetailsDoc = await aadharDetailsRef.get();
      }
      
      final String linkedPhone = aadharDetailsDoc.data()?['phone'] ?? '9876543210';
      _phoneController.text = linkedPhone; // Pre-fill the correct phone number

      // 2. Enforce 20 Liter Limit
      final aadharDoc = await FirebaseFirestore.instance.collection('aadhar_limits').doc(aadhar).get();
      double totalPurchasedLiters = 0.0;
      if (aadharDoc.exists) {
         totalPurchasedLiters = (aadharDoc.data()?['totalLitersPurchased'] as num?)?.toDouble() ?? 0.0;
      }

      if (totalPurchasedLiters + widget.requestedLiters > 20.0) {
        final remaining = (20.0 - totalPurchasedLiters).clamp(0, 20.0).toStringAsFixed(1);
        final requestedStr = widget.requestedLiters.toStringAsFixed(1);
        setState(() {
          _errorMessage = LocalizationService.isTamil 
              ? 'வரம்பு மீறப்பட்டுள்ளது. உங்கள் கார்டில் $remaining மீதம் உள்ளது (கோரப்பட்டது $requestedStr L).' 
              : 'Per Aadhar limit exceeded. You have $remaining L left (Requested: $requestedStr L). Maximum limit is 20L.';
        });
        setState(() => _isLoading = false);
        return;
      }
      
      // Limit clear, move to OTP sending step
      setState(() {
        _currentStep = 2;
      });
      _sendOtp(); // Automatically send the OTP using the linked number
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error checking Aadhar limit: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _sendOtp() {
    final phone = _phoneController.text.trim();
    if (phone.length != 10 || !RegExp(r'^\d{10}$').hasMatch(phone)) {
      setState(() => _errorMessage = LocalizationService.isTamil ? 'சரியான தொலைபேசி எண் உள்ளிடவும்' : 'Enter a valid phone number');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // Simulate OTP sending delay
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _currentStep = 3;
        // Instruction to use 123456 as mock Aadhar OTP
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocalizationService.isTamil ? 'OTP அனுப்பப்பட்டது (Mock OTP: 123456)' : 'OTP Sent successfully (Mock OTP: 123456)')),
      );
    });
  }

  void _verifyOtp() {
    final otp = _otpController.text.trim();
    if (otp != '123456') {
      setState(() => _errorMessage = LocalizationService.isTamil ? 'தவறான OTP' : 'Invalid OTP validation failed');
      return;
    }

    // Success! Return the aadhar number to checkout screen
    Navigator.of(context).pop(_aadharController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          LocalizationService.isTamil ? 'ஆதார் சரிபார்ப்பு' : 'Aadhar Verification',
          style: GoogleFonts.notoSansTamil(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Indicator
              Row(
                children: [
                  Expanded(child: Container(height: 4, color: AppColors.primary,)),
                  const SizedBox(width: 8),
                  Expanded(child: Container(height: 4, color: _currentStep >= 2 ? AppColors.primary : Colors.grey.shade300,)),
                  const SizedBox(width: 8),
                  Expanded(child: Container(height: 4, color: _currentStep >= 3 ? AppColors.primary : Colors.grey.shade300,)),
                ],
              ),
              const SizedBox(height: 32),
              
              const Icon(Icons.fingerprint, size: 64, color: AppColors.primary),
              const SizedBox(height: 24),

              if (_currentStep == 1) _buildAadharStep(),
              if (_currentStep == 2) _buildPhoneStep(),
              if (_currentStep == 3) _buildOtpStep(),

              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200)
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: GoogleFonts.poppins(color: Colors.red.shade900, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const Spacer(),
              
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () {
                    if (_currentStep == 1) _verifyAadharLimit();
                    else if (_currentStep == 2) _sendOtp();
                    else if (_currentStep == 3) _verifyOtp();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : Text(
                        _currentStep == 1 
                          ? (LocalizationService.isTamil ? 'வரம்பை சரிபார்' : 'Check Limit')
                        : _currentStep == 2
                          ? (LocalizationService.isTamil ? 'OTP அனுப்பு' : 'Send OTP')
                          : (LocalizationService.isTamil ? 'சரிபார்' : 'Verify'),
                        style: GoogleFonts.notoSansTamil(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAadharStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocalizationService.isTamil ? 'பூச்சிக்கொல்லி வாங்குவதற்கான ஆதார் விவரங்கள்' : 'Aadhar Details for Pesticides',
          style: GoogleFonts.notoSansTamil(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          LocalizationService.isTamil 
              ? 'பூச்சிக்கொல்லி மருந்துகளின் கொள்முதல் வரம்பை சரிபார்க்க உங்கள் ஆதார் எண்ணை உள்ளிடவும்.' 
              : 'Enter your Aadhar number to verify purchase limits for pesticides.',
          style: GoogleFonts.notoSansTamil(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _aadharController,
          keyboardType: TextInputType.number,
          maxLength: 12,
          decoration: InputDecoration(
            hintText: 'xxxx xxxx xxxx',
            labelText: LocalizationService.isTamil ? 'ஆதார் எண்' : 'Aadhar Number',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.credit_card),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocalizationService.isTamil ? 'ஆதார் இணைக்கப்பட்ட தொலைபேசி எண்' : 'Aadhar Linked Mobile Number',
          style: GoogleFonts.notoSansTamil(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          LocalizationService.isTamil 
              ? 'உங்கள் ஆதாருடன் இணைக்கப்பட்ட 10-இலக்க எண்ணை உள்ளிடவும்.' 
              : 'Please enter the 10-digit mobile number linked to the Aadhar card - ${_aadharController.text}',
          style: GoogleFonts.notoSansTamil(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          readOnly: true, // Auto-fetched from Aadhar details collection
          decoration: InputDecoration(
            hintText: '9876543210',
            labelText: LocalizationService.isTamil ? 'தொலைபேசி எண்' : 'Phone Number',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.phone),
            prefixText: '+91 ',
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocalizationService.isTamil ? 'OTP ஐ உள்ளிடவும்' : 'Enter OTP',
          style: GoogleFonts.notoSansTamil(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          LocalizationService.isTamil 
              ? '+91 ${_phoneController.text} எண்ணிற்கு அனுப்பப்பட்ட 6-இலக்க OTP ஐ உள்ளிட்டவும்.' 
              : 'Enter the 6-digit OTP sent to +91 ${_phoneController.text}.',
          style: GoogleFonts.notoSansTamil(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(
            hintText: '123456',
            labelText: 'OTP',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.message),
          ),
        ),
      ],
    );
  }
}
