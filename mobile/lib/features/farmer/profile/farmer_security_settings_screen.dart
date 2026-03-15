import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';

class FarmerSecuritySettingsScreen extends StatefulWidget {
  const FarmerSecuritySettingsScreen({super.key});

  @override
  State<FarmerSecuritySettingsScreen> createState() => _FarmerSecuritySettingsScreenState();
}

class _FarmerSecuritySettingsScreenState extends State<FarmerSecuritySettingsScreen> {
  final _newPasswordController = TextEditingController();
  final _newPhoneController = TextEditingController();
  final _otpController = TextEditingController();
  
  String? _currentUserPhone;
  bool _isLoading = false;
  
  // States to track flow
  bool _isPasswordChangeMode = false;
  bool _isPhoneChangeMode = false;
  String? _verificationId;
  
  @override
  void initState() {
    super.initState();
    _fetchCurrentUserData();
  }

  Future<void> _fetchCurrentUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final phone = doc.data()?['phone'] as String?;
        if (phone != null) {
          setState(() {
            _currentUserPhone = phone.replaceAll('+91', '');
          });
        }
      }
    }
  }

  void _sendOtp() async {
    if (_currentUserPhone == null) return;
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+91$_currentUserPhone',
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OTP Failed: ${e.message}')));
        },
        codeSent: (String vid, int? resendToken) {
          setState(() {
            _verificationId = vid;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP Sent!')));
        },
        codeAutoRetrievalTimeout: (String vid) {
          _verificationId = vid;
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _verifyOtpAndProceed() async {
    if (_verificationId == null || _otpController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Create credential and re-authenticate or verify
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text.trim(),
      );

      // Verify without actually signing out by re-authenticating if phone matches
      // Or we just rely on Firebase's credential validation
      await FirebaseAuth.instance.signInWithCredential(credential); // This is safe. If same user, it merges/refreshes tokens.

      if (_isPasswordChangeMode) {
        if (_newPasswordController.text.length < 6) throw Exception('Password too short');
        await FirebaseAuth.instance.currentUser?.updatePassword(_newPasswordController.text.trim());
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password Changed Successfully!')));
      } else if (_isPhoneChangeMode) {
        if (_newPhoneController.text.length != 10) throw Exception('Invalid new phone');
        final newPhone = '+91${_newPhoneController.text.trim()}';
        await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).update({
          'phone': newPhone,
        });
        setState(() => _currentUserPhone = _newPhoneController.text.trim());
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone Number Changed Successfully!')));
      }

      // Reset
      setState(() {
         _verificationId = null;
         _isPasswordChangeMode = false;
         _isPhoneChangeMode = false;
         _otpController.clear();
         _newPasswordController.clear();
         _newPhoneController.clear();
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          LocalizationService.isTamil ? 'பாதுகாப்பு & கணக்கு' : 'Security Settings',
          style: GoogleFonts.notoSansTamil(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_verificationId == null) ...[
               _buildOption(
                 title: LocalizationService.isTamil ? 'மொபைல் எண்ணை மாற்றவும்' : 'Change Phone Number',
                 icon: Icons.phone_android,
                 onTap: () {
                   setState(() {
                     _isPhoneChangeMode = true;
                     _isPasswordChangeMode = false;
                   });
                   _sendOtp();
                 }
               ),
               
               if (_isLoading) const Padding(
                 padding: EdgeInsets.all(32.0),
                 child: Center(child: CircularProgressIndicator()),
               )
            ] else ...[
               Text(
                 LocalizationService.isTamil 
                    ? '$_currentUserPhone எண்ணிற்கு அனுப்பப்பட்ட OTP ஐ உள்ளிடவும்' 
                    : 'Enter OTP sent to recently connected phone number.',
                 style: GoogleFonts.notoSansTamil(fontSize: 16),
               ),
               const SizedBox(height: 16),
               TextField(
                 controller: _otpController,
                 keyboardType: TextInputType.number,
                 decoration: const InputDecoration(labelText: 'OTP', border: OutlineInputBorder()),
               ),
               const SizedBox(height: 16),
               
               if (_isPasswordChangeMode)
                 TextField(
                   controller: _newPasswordController,
                   obscureText: true,
                   decoration: InputDecoration(
                     labelText: LocalizationService.isTamil ? 'புதிய கடவுச்சொல்' : 'New Password', 
                     border: const OutlineInputBorder(),
                   ),
                 ),
                 
               if (_isPhoneChangeMode)
                 TextField(
                   controller: _newPhoneController,
                   keyboardType: TextInputType.phone,
                   maxLength: 10,
                   decoration: InputDecoration(
                     labelText: LocalizationService.isTamil ? 'புதிய மொபைல் எண்' : 'New Phone', 
                     border: const OutlineInputBorder(),
                   ),
                 ),
                 
               const SizedBox(height: 24),
               ElevatedButton(
                 onPressed: _isLoading ? null : _verifyOtpAndProceed,
                 style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size.fromHeight(50)),
                 child: _isLoading 
                   ? const CircularProgressIndicator(color: Colors.white) 
                   : const Text('Verify & Update', style: TextStyle(color: Colors.white, fontSize: 16)),
               )
            ]
          ],
        ),
      )
    );
  }

  Widget _buildOption({required String title, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: GoogleFonts.notoSansTamil(fontSize: 16, fontWeight: FontWeight.bold))),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
