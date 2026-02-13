import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/storage_service.dart';

enum ProfileSetupMode {
  basic,      // Only Name required (Photo optional), Location optional/skippable
  full        // Address required (for Order/Advisory)
}

class FarmerProfileSetupScreen extends StatefulWidget {
  final ProfileSetupMode mode;

  const FarmerProfileSetupScreen({super.key, this.mode = ProfileSetupMode.basic});

  @override
  State<FarmerProfileSetupScreen> createState() => _FarmerProfileSetupScreenState();
}

class _FarmerProfileSetupScreenState extends State<FarmerProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  
  File? _imageFile;
  bool _isLoading = false;
  bool _isLocationLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchExistingData();
  }

  Future<void> _fetchExistingData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            _nameController.text = data['name'] ?? '';
            // Pre-fill address if available
            final addr = data['address'] as Map<String, dynamic>?;
            if (addr != null) {
              _streetController.text = addr['street'] ?? '';
              _cityController.text = addr['city'] ?? '';
              _districtController.text = addr['district'] ?? '';
              _stateController.text = addr['state'] ?? '';
            }
          });
        }
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocationLoading = true);
    try {
      final pos = await LocationService.determinePosition();
      final address = await LocationService.getAddressFromLatLng(pos.latitude, pos.longitude);
      
      setState(() {
        _streetController.text = address['street'] ?? '';
        _cityController.text = address['city'] ?? '';
        _districtController.text = address['district'] ?? '';
        _stateController.text = address['state'] ?? '';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocalizationService.tr('profile_setup_loc_success'))),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLocationLoading = false);
    }
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    // In 'full' mode, validate address fields manually if needed
    if (widget.mode == ProfileSetupMode.full) {
      if (_cityController.text.isEmpty || _districtController.text.isEmpty || _stateController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(LocalizationService.tr('profile_setup_error_address'))),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String? imageUrl;
      if (_imageFile != null) {
         imageUrl = await StorageService.uploadImage(_imageFile!, 'profiles');
      }
      
      final Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        if (imageUrl != null) 'profileImage': imageUrl, // [NEW] Save URL
        'isProfileBasicComplete': true, // Mark basic profile as done
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Only save address if entered
      if (_cityController.text.isNotEmpty) {
        updateData['address'] = {
           'street': _streetController.text.trim(),
           'city': _cityController.text.trim(),
           'district': _districtController.text.trim(),
           'state': _stateController.text.trim(),
        };
        updateData['hasAddress'] = true;
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        updateData,
        SetOptions(merge: true),
      );

      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        } else {
           Navigator.of(context).pushReplacementNamed('/home');
        }
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBasic = widget.mode == ProfileSetupMode.basic;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isBasic 
             ? LocalizationService.tr('profile_setup_title_basic') 
             : LocalizationService.tr('profile_setup_title_full'),
          style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: !isBasic, // Initial setup shouldn't be skippable/backable
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isBasic) ...[
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                          child: _imageFile == null
                              ? const Icon(Icons.person, size: 50, color: Colors.grey)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  Text(
                    "${LocalizationService.tr('profile_setup_name_label')} *",
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    validator: (v) => v == null || v.isEmpty ? LocalizationService.tr('profile_setup_error_name') : null,
                    decoration: InputDecoration(
                      hintText: LocalizationService.tr('profile_setup_name_hint'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
                
                Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                      Text(
                        isBasic 
                           ? LocalizationService.tr('profile_setup_location_optional') 
                           : "${LocalizationService.tr('profile_setup_delivery_label')} *",
                         style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: _isLocationLoading ? null : _useCurrentLocation,
                        icon: _isLocationLoading 
                           ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                           : const Icon(Icons.my_location, size: 18),
                        label: Text(
                           LocalizationService.tr('profile_setup_use_location'), 
                           style: GoogleFonts.poppins(fontSize: 12)
                        ),
                      )
                   ],
                ),
                const SizedBox(height: 16),
                
                _buildTextField(LocalizationService.tr('profile_setup_street'), _streetController),
                const SizedBox(height: 12),
                Row(
                   children: [
                     Expanded(child: _buildTextField(LocalizationService.tr('profile_setup_city'), _cityController)),
                     const SizedBox(width: 12),
                     Expanded(child: _buildTextField(LocalizationService.tr('profile_setup_district'), _districtController)),
                   ],
                ),
                const SizedBox(height: 12),
                _buildTextField(LocalizationService.tr('profile_setup_state'), _stateController),

                const SizedBox(height: 40),
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveAndContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            isBasic 
                               ? LocalizationService.tr('profile_setup_save') 
                               : LocalizationService.tr('profile_setup_confirm'),
                            style: GoogleFonts.notoSansTamil(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                
                if (isBasic) ...[
                   const SizedBox(height: 16),
                   Center(
                     child: TextButton(
                       onPressed: () {
                          // Allow skipping location if basic mode (But Name is still validated by saveAndContinue)
                          if (_nameController.text.isNotEmpty) {
                             _saveAndContinue();
                          } else {
                             ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(LocalizationService.tr('profile_setup_error_name')))
                             );
                          }
                       },
                       child: Text(
                          LocalizationService.tr('profile_setup_skip'), 
                          style: GoogleFonts.poppins(color: Colors.grey)
                       ),
                     ),
                   )
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
