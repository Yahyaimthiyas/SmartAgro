import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import '../../../core/services/storage_service.dart';

class FarmerAddCropScreen extends StatefulWidget {
  const FarmerAddCropScreen({super.key});

  @override
  State<FarmerAddCropScreen> createState() => _FarmerAddCropScreenState();
}

class _FarmerAddCropScreenState extends State<FarmerAddCropScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCropId;
  final TextEditingController _areaController = TextEditingController();
  String _areaUnit = 'acres';
  DateTime? _sowingDate;
  bool _saving = false;

  static const List<String> _cropIds = [
    'rice',
    'cotton',
    'sugarcane',
    'groundnut',
    'vegetables',
  ];

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _sowingDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      builder: (context, child) {
         return Theme(
            data: Theme.of(context).copyWith(
               colorScheme: const ColorScheme.light(primary: AppColors.primary),
               textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                     foregroundColor: AppColors.primary,
                     textStyle: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold)
                  )
               )
            ),
            child: child!,
         );
      }
    );
    if (picked != null) {
      setState(() => _sowingDate = picked);
    }
  }

  File? _image; // [NEW] Image file
  final _picker = ImagePicker(); // [NEW]

  // [NEW] Pick Image
  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (_saving) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocalizationService.tr('error_login_again'))),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    if (_sowingDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocalizationService.tr('crop_error_sowing_date_required'))),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final area = double.tryParse(_areaController.text.trim()) ?? 0;
      String? imageUrl;

      // [NEW] Upload Image
      if (_image != null) {
        imageUrl = await StorageService.uploadImage(_image!, 'crops');
      }

      await FirebaseFirestore.instance.collection('crops').add({
        'userId': user.uid,
        'cropTypeId': _selectedCropId,
        'area': area,
        'areaUnit': _areaUnit,
        'sowingDate': Timestamp.fromDate(_sowingDate!),
        'imageUrl': imageUrl, // [NEW] Save URL
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${LocalizationService.tr('crop_error_save_failed')}: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _labelForCrop(String id) {
    return LocalizationService.tr('crop_${id}_label');
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return LocalizationService.tr('crop_field_sowing_date_hint');
    }
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          LocalizationService.tr('crop_add_appbar'),
          style: GoogleFonts.notoSansTamil(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocalizationService.tr('crop_add_heading'),
                  style: GoogleFonts.notoSansTamil(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  LocalizationService.tr('crop_add_subtitle'),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                
                // [NEW] Image Picker
                Center(
                   child: InkWell(
                      onTap: _pickImage,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                         width: double.infinity,
                         height: 200,
                         decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade300, width: 2, style: BorderStyle.solid),
                            image: _image != null 
                               ? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover)
                               : null
                         ),
                         child: _image == null 
                            ? Column(
                               mainAxisAlignment: MainAxisAlignment.center,
                               children: [
                                  Icon(Icons.add_a_photo_outlined, size: 40, color: AppColors.primary.withOpacity(0.6)),
                                  const SizedBox(height: 8),
                                  Text(
                                     "Add Crop Photo", 
                                     style: GoogleFonts.poppins(color: Colors.grey.shade500, fontWeight: FontWeight.w600)
                                  )
                               ],
                            )
                            : null,
                      ),
                   ),
                ),
                
                const SizedBox(height: 32),
                
                // Crop Type Dropdown
                _buildLabel(LocalizationService.tr('crop_field_crop_type_label')),
                const SizedBox(height: 8),
                Container(
                   padding: const EdgeInsets.symmetric(horizontal: 0),
                   decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200)
                   ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedCropId,
                    items: _cropIds
                        .map(
                          (id) => DropdownMenuItem<String>(
                            value: id,
                            child: Text(
                              _labelForCrop(id),
                              style: GoogleFonts.notoSansTamil(fontSize: 14),
                            ),
                          ),
                        )
                        .toList(),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    onChanged: (value) {
                      setState(() => _selectedCropId = value);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return LocalizationService.tr('crop_error_crop_type_required');
                      }
                      return null;
                    },
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Area Input
                _buildLabel(LocalizationService.tr('crop_field_area_label')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Container(
                         height: 56,
                         padding: const EdgeInsets.symmetric(horizontal: 0),
                         decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                               BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4)
                               )
                            ]
                         ),
                        child: TextFormField(
                          controller: _areaController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: '0.0',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0), // Centered vertically in 56px
                            hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400)
                          ),
                          validator: (value) {
                            final v = double.tryParse(value?.trim() ?? '');
                            if (v == null || v <= 0) {
                              return LocalizationService.tr('crop_error_area_required');
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                       flex: 5,
                       child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                             color: Colors.grey.shade50,
                             borderRadius: BorderRadius.circular(16),
                             border: Border.all(color: Colors.grey.shade300)
                          ),
                          child: Row(
                             children: [
                                _unitButton('acres', LocalizationService.tr('crop_unit_acres')),
                                Container(width: 1, height: 32, color: Colors.grey.shade300),
                                _unitButton('hectares', LocalizationService.tr('crop_unit_hectares')),
                             ],
                          ),
                       ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Date Picker
                _buildLabel(LocalizationService.tr('crop_field_sowing_date_label')),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                     decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200)
                     ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(_sowingDate),
                          style: GoogleFonts.poppins(
                             fontSize: 14,
                             color: _sowingDate == null ? Colors.grey : AppColors.textPrimary
                          ),
                        ),
                        const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.1))
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.tips_and_updates_outlined, size: 24, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              LocalizationService.tr('crop_info_why_important_title'),
                              style: GoogleFonts.notoSansTamil(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              LocalizationService.tr('crop_info_why_important_body'),
                              style: GoogleFonts.notoSansTamil(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.5
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
         padding: const EdgeInsets.all(20),
         decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
               BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4)
               )
            ]
         ),
         child: SafeArea(
           child: SizedBox(
             width: double.infinity,
             height: 56,
             child: ElevatedButton(
               onPressed: _saving ? null : _save,
               style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
               ),
               child: _saving
                   ? const SizedBox(
                       width: 24,
                       height: 24,
                       child: CircularProgressIndicator(
                         strokeWidth: 2.5,
                         color: Colors.white,
                       ),
                     )
                   : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         const Icon(Icons.check_circle_outline, color: Colors.white),
                         const SizedBox(width: 8),
                         Text(
                          LocalizationService.tr('crop_btn_save'),
                          style: GoogleFonts.notoSansTamil(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white
                          ),
                        ),
                      ],
                   ),
             ),
           ),
         ),
      ),
    );
  }
  
  Widget _buildLabel(String text) {
     return Text(
        text,
        style: GoogleFonts.notoSansTamil(
           fontSize: 14,
           fontWeight: FontWeight.bold,
           color: AppColors.textPrimary
        ),
     );
  }
  
  Widget _unitButton(String value, String label) {
     final isSelected = _areaUnit == value;
     return Expanded(
        child: InkWell(
           onTap: () => setState(() => _areaUnit = value),
           child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                 color: isSelected ? Colors.white : Colors.transparent,
                 borderRadius: BorderRadius.circular(14),
                 boxShadow: isSelected ? [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                 ] : null,
              ),
              margin: const EdgeInsets.all(4),
              child: Text(
                 label,
                 style: GoogleFonts.notoSansTamil(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary
                 ),
              ),
           ),
        ),
     );
  }
}

