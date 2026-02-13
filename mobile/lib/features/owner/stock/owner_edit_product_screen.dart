import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import 'dart:convert'; // [NEW]
import '../../../core/widgets/common_image.dart'; // [NEW]

class OwnerEditProductScreen extends StatefulWidget {
  final String? productId;

  const OwnerEditProductScreen({super.key, this.productId});

  @override
  State<OwnerEditProductScreen> createState() => _OwnerEditProductScreenState();
}

class _OwnerEditProductScreenState extends State<OwnerEditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameTaController = TextEditingController();
  final _nameEnController = TextEditingController();
  final _priceController = TextEditingController();
  final _unitTaController = TextEditingController();
  final _unitEnController = TextEditingController();
  final _stockController = TextEditingController();
  final _offerController = TextEditingController();
  final _descriptionTaController = TextEditingController();
  final _descriptionEnController = TextEditingController();
  final _dosageTaController = TextEditingController();
  final _dosageEnController = TextEditingController();
  final _safetyTaController = TextEditingController();
  final _safetyEnController = TextEditingController();

  // [NEW] Offer State
  bool _isOfferActive = false;
  String _offerType = 'percentage'; // or 'flat'
  final _offerValueController = TextEditingController();

  bool _loading = false;
  bool _saving = false;
  String? _selectedCategoryId;
  String? _existingImageUrl;
  XFile? _pickedImage;

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) {
      _loadProduct();
    }
  }

  @override
  void dispose() {
    _nameTaController.dispose();
    _nameEnController.dispose();
    _priceController.dispose();
    _unitTaController.dispose();
    _unitEnController.dispose();
    _stockController.dispose();
    _offerController.dispose();
    _descriptionTaController.dispose();
    _descriptionEnController.dispose();
    _dosageTaController.dispose();
    _dosageEnController.dispose();
    _safetyTaController.dispose();
    _safetyEnController.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    setState(() {
      _loading = true;
    });
    try {
      final doc = await FirebaseFirestore.instance.collection('products').doc(widget.productId).get();
      if (!doc.exists) {
        setState(() {
          _loading = false;
        });
        return;
      }
      final data = doc.data()!;
      _nameTaController.text = data['name_ta'] as String? ?? '';
      _nameEnController.text = data['name_en'] as String? ?? '';
      _priceController.text = (data['price'] as num? ?? 0).toString();
      _unitTaController.text = data['unit_ta'] as String? ?? '';
      _unitEnController.text = data['unit_en'] as String? ?? '';
      _stockController.text = (data['stock'] as num? ?? 0).toInt().toString();
      final offer = data['offerPercent'] as num?;
      if (offer != null) {
        _offerController.text = offer.toString();
      }
      
      // [NEW] Load Offer Data
      _isOfferActive = data['isOfferActive'] as bool? ?? false;
      _offerType = data['offerType'] as String? ?? 'percentage';
      _offerValueController.text = (data['offerValue'] as num? ?? 0).toString();
      _descriptionTaController.text = data['description_ta'] as String? ?? '';
      _descriptionEnController.text = data['description_en'] as String? ?? '';
      _dosageTaController.text = data['dosage_ta'] as String? ?? '';
      _dosageEnController.text = data['dosage_en'] as String? ?? '';
      _safetyTaController.text = data['safety_ta'] as String? ?? '';
      _safetyEnController.text = data['safety_en'] as String? ?? '';
      _selectedCategoryId = data['categoryId'] as String?;
      _existingImageUrl = data['imageUrl'] as String?;
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.productId != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Lighter background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          LocalizationService.tr(isEdit ? 'owner_stock_edit_product_title' : 'owner_stock_add_product_title'),
          style: GoogleFonts.notoSansTamil(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // Extra bottom padding for floating bar
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Basic Info
                      _buildSectionTitle(LocalizationService.tr('header_basic_info')),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: _sectionDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildImagePicker(),
                            const SizedBox(height: 24),
                            _buildTextField(
                              controller: _nameTaController,
                              labelKey: 'owner_stock_field_name_ta',
                              keyboardType: TextInputType.text,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _nameEnController,
                              labelKey: 'owner_stock_field_name_en',
                              keyboardType: TextInputType.text,
                            ),
                            const SizedBox(height: 16),
                            _buildCategoryDropdown(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Section 2: Pricing & Stock
                      _buildSectionTitle(LocalizationService.tr('header_pricing_stock')),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: _sectionDecoration(),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _priceController,
                                    labelKey: 'owner_stock_field_price',
                                    keyboardType: TextInputType.number,
                                    prefixText: '₹ ',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _stockController,
                                    labelKey: 'owner_stock_field_stock',
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _unitTaController,
                                    labelKey: 'owner_stock_field_unit_ta',
                                    keyboardType: TextInputType.text,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _unitEnController,
                                    labelKey: 'owner_stock_field_unit_en',
                                    keyboardType: TextInputType.text,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Section 3: Offers
                      _buildSectionTitle(LocalizationService.tr('header_promotions')),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: _sectionDecoration(
                          color: Colors.blue.withOpacity(0.02),
                          borderColor: Colors.blue.withOpacity(0.15)
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        LocalizationService.tr('label_special_offer'),
                                        style: GoogleFonts.notoSansTamil(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        LocalizationService.tr('msg_offer_desc'),
                                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.blueGrey),
                                      )
                                    ],
                                  ),
                                ),
                                Transform.scale(
                                  scale: 0.8,
                                  child: Switch(
                                    value: _isOfferActive,
                                    onChanged: (val) {
                                      setState(() {
                                        _isOfferActive = val;
                                      });
                                    },
                                    activeColor: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            if (_isOfferActive) ...[
                              const SizedBox(height: 20),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildRadioOption("${LocalizationService.tr('label_percentage')} (%)", 'percentage'),
                                    ),
                                    Expanded(
                                      child: _buildRadioOption("${LocalizationService.tr('label_flat_price')} (₹)", 'flat'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildTextField(
                                controller: _offerValueController,
                                labelKey: _offerType == 'percentage' ? 'label_offer_percentage' : 'label_offer_price',
                                keyboardType: TextInputType.number,
                                prefixText: _offerType == 'percentage' ? '' : '₹ ',
                                suffixText: _offerType == 'percentage' ? '%' : '',
                              ),
                              const SizedBox(height: 16),
                              if (_priceController.text.isNotEmpty && _offerValueController.text.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.green.withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.verified_outlined, size: 20, color: Colors.green),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _getOfferPreviewText(),
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green.shade800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Section 4: Details
                      _buildSectionTitle(LocalizationService.tr('header_product_details')),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: _sectionDecoration(),
                        child: Column(
                          children: [
                            _buildMultilineField(
                              controller: _descriptionTaController,
                              labelKey: 'owner_stock_field_description_ta',
                            ),
                            const SizedBox(height: 16),
                            _buildMultilineField(
                              controller: _descriptionEnController,
                              labelKey: 'owner_stock_field_description_en',
                            ),
                            const SizedBox(height: 16),
                            _buildMultilineField(
                              controller: _dosageTaController,
                              labelKey: 'owner_stock_field_dosage_ta',
                            ),
                            const SizedBox(height: 16),
                            _buildMultilineField(
                              controller: _dosageEnController,
                              labelKey: 'owner_stock_field_dosage_en',
                            ),
                            const SizedBox(height: 16),
                            _buildMultilineField(
                              controller: _safetyTaController,
                              labelKey: 'owner_stock_field_safety_ta',
                            ),
                            const SizedBox(height: 16),
                            _buildMultilineField(
                              controller: _safetyEnController,
                              labelKey: 'owner_stock_field_safety_en',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      // Sticky Bottom Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _saving ? null : _onSavePressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      LocalizationService.tr('owner_stock_btn_save'),
                      style: GoogleFonts.notoSansTamil(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary, // Darker text
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  BoxDecoration _sectionDecoration({Color? color, Color? borderColor}) {
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: borderColor ?? Colors.transparent),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF64748B).withOpacity(0.08), // Softer shadow
          blurRadius: 24,
          offset: const Offset(0, 8),
        )
      ],
    );
  }

  Widget _buildRadioOption(String title, String value) {
    final isSelected = _offerType == value;
    return InkWell(
      onTap: () => setState(() => _offerType = value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: GoogleFonts.notoSansTamil(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    final hasImage = _pickedImage != null || (_existingImageUrl != null && _existingImageUrl!.isNotEmpty);
    return Row(
      children: [
        // Image Preview
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: hasImage 
              ? CommonImage(
                  imageUrl: _pickedImage != null ? 'data:image/jpeg;base64,${base64Encode(File(_pickedImage!.path).readAsBytesSync())}' : _existingImageUrl, 
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(16),
                )
              : Icon(Icons.add_photo_alternate_rounded, size: 32, color: Colors.grey[300]),
        ),
        const SizedBox(width: 20),
        
        // Action Button - Wrapped in Expanded to prevent overflow
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocalizationService.tr('owner_stock_field_image'),
                style: GoogleFonts.notoSansTamil(
                  fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.upload_file_rounded, size: 18),
                  label: Text(
                    LocalizationService.tr('owner_stock_btn_pick_image'),
                    style: GoogleFonts.notoSansTamil(fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis, // Ensure text truncation
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // [NEW] Helper to calculate preview
  String _getOfferPreviewText() {
    final originalPrice = double.tryParse(_priceController.text) ?? 0;
    final offerVal = double.tryParse(_offerValueController.text) ?? 0;
    
    if (originalPrice <= 0) return '';

    double finalPrice = originalPrice;
    if (_offerType == 'percentage') {
      final discount = (originalPrice * offerVal) / 100;
      finalPrice = originalPrice - discount;
    } else {
      finalPrice = offerVal; // Flat price
    }

    if (finalPrice < 0) finalPrice = 0;

    return "${LocalizationService.tr('msg_offer_preview')} ₹$originalPrice -> ₹${finalPrice.toStringAsFixed(0)}";
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelKey,
    TextInputType? keyboardType,
    String? hintKey,
    String? prefixText,
    String? suffixText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: LocalizationService.tr(labelKey),
        hintText: hintKey != null ? LocalizationService.tr(hintKey) : null,
        prefixText: prefixText,
        suffixText: suffixText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildMultilineField({
    required TextEditingController controller,
    required String labelKey,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: LocalizationService.tr(labelKey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('categories').orderBy('sortOrder', descending: false).snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        return InputDecorator(
          decoration: InputDecoration(
            labelText: LocalizationService.tr('owner_stock_field_category'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedCategoryId,
              hint: Text(
                LocalizationService.tr('owner_stock_field_category_hint'),
                style: GoogleFonts.notoSansTamil(fontSize: 13, color: AppColors.textSecondary),
              ),
              items: [
                for (final doc in docs)
                  DropdownMenuItem(
                    value: doc.id,
                    child: Text(
                      '${doc.data()['name_ta'] ?? ''} / ${doc.data()['name_en'] ?? ''}',
                      style: GoogleFonts.notoSansTamil(fontSize: 13),
                    ),
                  ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      setState(() {
        _pickedImage = image;
      });
    }
  }

  Future<void> _onSavePressed() async {
    final nameTa = _nameTaController.text.trim();
    final priceStr = _priceController.text.trim();
    final unitTa = _unitTaController.text.trim();
    final stockStr = _stockController.text.trim();

    if (nameTa.isEmpty || priceStr.isEmpty || unitTa.isEmpty || stockStr.isEmpty || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService.tr('owner_stock_validation_required')),
        ),
      );
      return;
    }

    final price = double.tryParse(priceStr);
    final stock = int.tryParse(stockStr);
    if (price == null || stock == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService.tr('owner_stock_validation_number')),
        ),
      );
      return;
    }

    final offerStr = _offerController.text.trim();
    num? offerPercent;
    if (offerStr.isNotEmpty) {
      offerPercent = num.tryParse(offerStr);
    }

    setState(() {
      _saving = true;
    });

    try {
      final collection = FirebaseFirestore.instance.collection('products');
      final docRef = widget.productId != null ? collection.doc(widget.productId) : collection.doc();

      String? imageUrl = _existingImageUrl;
      if (_pickedImage != null) {
        // [NEW] Local Base64 Encoding (No Firebase Storage needed)
        final bytes = await File(_pickedImage!.path).readAsBytes();
        final base64String = base64Encode(bytes);
        imageUrl = 'data:image/jpeg;base64,$base64String';
      }

      final data = <String, dynamic>{
        'name_ta': _nameTaController.text.trim(),
        'name_en': _nameEnController.text.trim(),
        'price': price,
        'unit_ta': _unitTaController.text.trim(),
        'unit_en': _unitEnController.text.trim(),
        'stock': stock,
        'categoryId': _selectedCategoryId,
        'shopId': 'default_shop',
        'description_ta': _descriptionTaController.text.trim(),
        'description_en': _descriptionEnController.text.trim(),
        'dosage_ta': _dosageTaController.text.trim(),
        'dosage_en': _dosageEnController.text.trim(),
        'safety_ta': _safetyTaController.text.trim(),
        'safety_en': _safetyEnController.text.trim(),
      };

      if (offerPercent != null) {
        data['offerPercent'] = offerPercent; // Backwards compatibility if needed
      }

      // [NEW] Integrated Offer Logic
      data['isOfferActive'] = _isOfferActive;
      data['offerType'] = _offerType; // 'percentage' or 'flat'
      data['offerValue'] = double.tryParse(_offerValueController.text.trim()) ?? 0.0;


      if (imageUrl != null && imageUrl.isNotEmpty) {
        data['imageUrl'] = imageUrl;
      }

      if (widget.productId == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        await docRef.set(data);
      } else {
        data['updatedAt'] = FieldValue.serverTimestamp();
        await docRef.update(data);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService.tr('owner_stock_save_success')),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService.tr('owner_stock_save_failed')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }
}

