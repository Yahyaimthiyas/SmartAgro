import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';

class OwnerCreateCustomerScreen extends StatefulWidget {
  const OwnerCreateCustomerScreen({super.key});

  @override
  State<OwnerCreateCustomerScreen> createState() => _OwnerCreateCustomerScreenState();
}

class _OwnerCreateCustomerScreenState extends State<OwnerCreateCustomerScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController(); // [NEW]
  final _villageController = TextEditingController();
  final _landSizeController = TextEditingController();
  final _cropController = TextEditingController();
  bool _isLoading = false;

  void _createAccount() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final village = _villageController.text.trim();
    final landSize = _landSizeController.text.trim();
    final crop = _cropController.text.trim();

    if (name.isEmpty || phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid input. Please enter name and 10-digit phone number.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final phoneNumber = '+91$phone';

      // Check if user already exists with this phone
      final existingUser = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phoneNumber)
          .get();

      if (existingUser.docs.isNotEmpty) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A user with this phone number already exists.')),
        );
        return;
      }

      // Create pre-registration document
      await FirebaseFirestore.instance.collection('users').add({
        'name': name,
        'phone': phoneNumber,
        'village': village,
        'landSize': landSize,
        'cropType': crop,
        'role': 'farmer',
        'isPreRegistered': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer Registered Successfully!'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          LocalizationService.isTamil ? 'புதிய விவசாயியைச் சேர்க்க' : 'Add New Farmer',
          style: GoogleFonts.notoSansTamil(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              LocalizationService.isTamil ? 'விவசாயியின் விவரங்களை நிரப்பவும்:' : 'Fill in the farmer details:',
              style: GoogleFonts.notoSansTamil(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _nameController,
              label: LocalizationService.isTamil ? 'பெயர்' : 'Full Name',
              hint: 'e.g. John Doe',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: LocalizationService.isTamil ? 'மொபைல் எண்' : 'Phone Number',
              hint: '9876543210',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              prefixText: '+91 ',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _villageController,
              label: LocalizationService.isTamil ? 'கிராமம்' : 'Village',
              hint: 'e.g. Kattur',
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _landSizeController,
              label: LocalizationService.isTamil ? 'நில அளவு (ஏக்கர்)' : 'Land Size (Acre)',
              hint: 'e.g. 2.5',
              icon: Icons.landscape_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _cropController,
              label: LocalizationService.isTamil ? 'பயிர் வகை' : 'Crop Type',
              hint: 'e.g. Paddy, Tomato',
              icon: Icons.grass_outlined,
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        LocalizationService.isTamil ? 'பதிவு செய்' : 'Register Farmer',
                        style: GoogleFonts.notoSansTamil(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    String? prefixText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: Icon(icon),
        prefixText: prefixText,
        counterText: "",
      ),
    );
  }
}

