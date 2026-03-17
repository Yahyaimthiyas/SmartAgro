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
      setState(() => _errorMessage = LocalizationService.tr('error_invalid_aadhar'));
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
        
        final msg = LocalizationService.tr('error_aadhar_limit_exceeded')
            .replaceAll('{remaining}', remaining)
            .replaceAll('{requested}', requestedStr);
        setState(() {
          _errorMessage = msg;
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
          _errorMessage = '${LocalizationService.tr('error_aadhar_check_failed')}: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _sendOtp() {
    final phone = _phoneController.text.trim();
    if (phone.length != 10 || !RegExp(r'^\d{10}$').hasMatch(phone)) {
      setState(() => _errorMessage = LocalizationService.tr('enter_phone_subtitle'));
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
        SnackBar(content: Text(LocalizationService.tr('msg_otp_sent_mock'))),
      );
    });
  }

  void _verifyOtp() {
    final otp = _otpController.text.trim();
    if (otp != '123456') {
      setState(() => _errorMessage = LocalizationService.tr('gate_error_incorrect_pin'));
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
          LocalizationService.tr('title_aadhar_verification'),
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
                          ? LocalizationService.tr('btn_check_limit')
                        : _currentStep == 2
                          ? LocalizationService.tr('get_otp')
                          : LocalizationService.tr('gate_title_verify'),
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
          LocalizationService.tr('label_aadhar_details_pest'),
          style: GoogleFonts.notoSansTamil(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          LocalizationService.tr('msg_aadhar_verify_desc'),
          style: GoogleFonts.notoSansTamil(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _aadharController,
          keyboardType: TextInputType.number,
          maxLength: 12,
          decoration: InputDecoration(
            hintText: 'xxxx xxxx xxxx',
            labelText: LocalizationService.tr('label_aadhar_number'),
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
          LocalizationService.tr('label_aadhar_linked_phone'),
          style: GoogleFonts.notoSansTamil(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          LocalizationService.tr('msg_aadhar_phone_desc').replaceAll('{aadhar}', _aadharController.text),
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
            labelText: LocalizationService.tr('label_phone_number'),
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
          LocalizationService.tr('enter_otp'),
          style: GoogleFonts.notoSansTamil(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          LocalizationService.tr('enter_otp_subtitle_phone').replaceAll('{phone}', _phoneController.text),
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
