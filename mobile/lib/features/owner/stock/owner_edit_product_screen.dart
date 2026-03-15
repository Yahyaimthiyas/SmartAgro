import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import '../../../core/utils/price_utils.dart';
import '../../../core/widgets/common_image.dart';

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
  final _qrIdController = TextEditingController();
  final _dosagePerCentTaController = TextEditingController();
  final _dosagePerCentEnController = TextEditingController();
  final _expiryDateController = TextEditingController(); 
  DateTime? _selectedExpiryDate;

  final _brandController = TextEditingController();
  final _subCategoryController = TextEditingController();
  final _cropUsedForController = TextEditingController();
  final _targetPestController = TextEditingController();
  final _applicationMethodController = TextEditingController();
  final _varietyNameController = TextEditingController();
  final _growingConditionsController = TextEditingController();
  final _benefitsController = TextEditingController();
  final _technicalNameController = TextEditingController();
  final _compositionController = TextEditingController();
  final _classificationController = TextEditingController();
  final _toxicityController = TextEditingController();
  final _modeOfEntryController = TextEditingController();
  final _modeOfActionController = TextEditingController();
  final _expertAdviceController = TextEditingController();
  final _batchNumberController = TextEditingController(); // [NEW]
  final _purchasePriceController = TextEditingController(); // [NEW]

  final List<TextEditingController> _featureControllers = [];
  final List<Map<String, TextEditingController>> _usageTableRows = [];
  final List<Map<String, TextEditingController>> _variantRows = [];

  String? _selectedSubCategory;

  final Map<String, List<String>> _subCategoriesMap = {
    'seeds': [
      'Field Crop Seeds', 'Vegetable Seeds', 'Fruit Seeds', 'Flower Seeds', 
      'Fodder Seeds', 'Hybrid Seeds', 'Organic Seeds', 'Tissue Culture Plants'
    ],
    'fertilizers': [
      'Chemical Fertilizers', 'Bio Fertilizers', 'Organic Fertilizers', 
      'Micronutrient Fertilizers', 'Water Soluble Fertilizers'
    ],
    'pesticides': [
      'Insecticides', 'Systemic Insecticides', 'Contact Insecticides', 'Biological Insecticides'
    ],
    'fungicides': [
      'Contact Fungicides', 'Systemic Fungicides', 'Combination Fungicides'
    ],
    'bactericides': [
      'Antibiotic bactericides', 'Copper-based bactericides'
    ],
    'herbicides': [
      'Selective Herbicides', 'Non-selective Herbicides', 'Pre-emergence Herbicides', 'Post-emergence Herbicides'
    ],
    'pgr': [
      'Growth promoters', 'Growth inhibitors', 'Plant hormones', 'Flowering stimulants', 'Yield boosters'
    ],
    'biopesticides': [
      'Neem-based pesticides', 'Microbial pesticides', 'Botanical pesticides', 'Fungal biocontrol agents'
    ],
  };

  final List<String> _popularBrands = [
    'Syngenta', 'Mahyco', 'Bayer CropScience', 'Rasi Seeds', 'Advanta Seeds', 'Kaveri Seeds',
    'IFFCO', 'KRIBHCO', 'TATA Rallis', 'Coromandel', 'Sumitomo', 'UPL', 'Dhanuka'
  ];

  // [NEW] Offer State
  bool _isOfferActive = false;
  String _offerType = 'percentage'; // or 'flat'
  final _offerValueController = TextEditingController();
  DateTime? _offerStart;
  DateTime? _offerEnd;
  final _offerStartController = TextEditingController();
  final _offerEndController = TextEditingController();

  bool _loading = false;
  bool _saving = false;
  String? _selectedCategoryId;
  String? _existingImageUrl;
  XFile? _pickedImage;

  // Track entry method
  String _entryMethod = 'type'; // 'qr', 'file', 'type'

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
    _qrIdController.dispose();
    _dosagePerCentEnController.dispose();
    _brandController.dispose();
    _subCategoryController.dispose();
    _cropUsedForController.dispose();
    _targetPestController.dispose();
    _applicationMethodController.dispose();
    _varietyNameController.dispose();
    _growingConditionsController.dispose();
    _benefitsController.dispose();
    _technicalNameController.dispose();
    _compositionController.dispose();
    _classificationController.dispose();
    _toxicityController.dispose();
    _modeOfEntryController.dispose();
    _modeOfActionController.dispose();
    _expertAdviceController.dispose();
    for (var c in _featureControllers) {
      c.dispose();
    }
    for (var row in _usageTableRows) {
      row.values.forEach((c) => c.dispose());
    }
    for (var row in _variantRows) {
      row.values.forEach((c) => c.dispose());
    }
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
      
      final startTs = data['offerStart'] as Timestamp?;
      if (startTs != null) {
        _offerStart = startTs.toDate();
        _offerStartController.text = DateFormat('dd/MM/yyyy HH:mm').format(_offerStart!);
      }
      
      final endTs = data['offerEnd'] as Timestamp?;
      if (endTs != null) {
        _offerEnd = endTs.toDate();
        _offerEndController.text = DateFormat('dd/MM/yyyy HH:mm').format(_offerEnd!);
      }
      _descriptionTaController.text = data['description_ta'] as String? ?? '';
      _descriptionEnController.text = data['description_en'] as String? ?? '';
      _dosageTaController.text = data['dosage_ta'] as String? ?? '';
      _dosageEnController.text = data['dosage_en'] as String? ?? '';
      _safetyTaController.text = data['safety_ta'] as String? ?? '';
      _safetyEnController.text = data['safety_en'] as String? ?? '';
      _qrIdController.text = data['qrId'] as String? ?? '';
      _dosagePerCentTaController.text = data['dosage_per_cent_ta'] as String? ?? '';
      _dosagePerCentEnController.text = data['dosage_per_cent_en'] as String? ?? '';
      _selectedCategoryId = data['categoryId'] as String?;
      _selectedSubCategory = data['subCategory'] as String?;
      _brandController.text = data['brand'] as String? ?? '';
      _cropUsedForController.text = data['cropUsedFor'] as String? ?? '';
      _targetPestController.text = data['pestControlled'] as String? ?? '';
      _applicationMethodController.text = data['applicationMethod'] as String? ?? '';
      _varietyNameController.text = data['varietyName'] as String? ?? '';
      _growingConditionsController.text = data['growingConditions'] as String? ?? '';
      _benefitsController.text = data['benefits'] as String? ?? '';
      _technicalNameController.text = data['technicalName'] as String? ?? '';
      _compositionController.text = data['composition'] as String? ?? '';
      _classificationController.text = data['classification'] as String? ?? '';
      _toxicityController.text = data['toxicity'] as String? ?? '';
      _modeOfEntryController.text = data['modeOfEntry'] as String? ?? '';
      _modeOfActionController.text = data['modeOfAction'] as String? ?? '';
      _expertAdviceController.text = data['expertAdvice'] as String? ?? '';

      final features = data['keyFeatures'] as List<dynamic>? ?? [];
      _featureControllers.clear();
      for (var f in features) {
        _featureControllers.add(TextEditingController(text: f.toString()));
      }

      final usage = data['usageTable'] as List<dynamic>? ?? [];
      _usageTableRows.clear();
      for (var u in usage) {
        final map = u as Map<String, dynamic>;
        _usageTableRows.add({
          'crop': TextEditingController(text: map['crop']?.toString() ?? ''),
          'pest': TextEditingController(text: map['pest']?.toString() ?? ''),
          'dosageAcre': TextEditingController(text: map['dosageAcre']?.toString() ?? ''),
          'dilution': TextEditingController(text: map['dilution']?.toString() ?? ''),
          'dosageWater': TextEditingController(text: map['dosageWater']?.toString() ?? ''),
          'waiting': TextEditingController(text: map['waiting']?.toString() ?? ''),
        });
      }

      final variants = data['variants'] as List<dynamic>? ?? [];
      _variantRows.clear();
      for (var v in variants) {
        final map = v as Map<String, dynamic>;
        _variantRows.add({
          'size': TextEditingController(text: map['size']?.toString() ?? ''),
          'price': TextEditingController(text: map['price']?.toString() ?? ''),
          'mrp': TextEditingController(text: map['mrp']?.toString() ?? ''),
          'unit': TextEditingController(text: map['unit']?.toString() ?? ''),
        });
      }
      
      _existingImageUrl = data['imageUrl'] as String?;
      
      _batchNumberController.text = data['batchNumber'] as String? ?? ''; // [NEW]
      _purchasePriceController.text = (data['purchasePrice'] as num? ?? 0).toString(); // [NEW]

      final expiryTs = data['expiryDate'] as Timestamp?;
      if (expiryTs != null) {
        _selectedExpiryDate = expiryTs.toDate();
        _expiryDateController.text = "${_selectedExpiryDate!.day}/${_selectedExpiryDate!.month}/${_selectedExpiryDate!.year}";
      }
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
                      // entry Method Options
                      if (widget.productId == null)
                      _buildEntryMethodOptions(),

                      const SizedBox(height: 12),

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
                            const SizedBox(height: 16),
                            _buildSubCategoryDropdown(),
                            const SizedBox(height: 16),
                            _buildBrandField(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      const SizedBox(height: 32),
                      
                      // Section 2: Technical Info
                      _buildSectionTitle('Technical Specifications'),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: _sectionDecoration(),
                        child: Column(
                          children: [
                            _buildTextField(controller: _technicalNameController, labelKey: 'Technical Name (e.g. Chlorantraniliprole)', keyboardType: TextInputType.text),
                            const SizedBox(height: 16),
                            _buildTextField(controller: _compositionController, labelKey: 'Composition (e.g. 18.5% SC)', keyboardType: TextInputType.text),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: _buildTextField(controller: _classificationController, labelKey: 'Classification', keyboardType: TextInputType.text)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildTextField(controller: _toxicityController, labelKey: 'Toxicity (Color)', keyboardType: TextInputType.text)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(controller: _modeOfEntryController, labelKey: 'Mode of Entry', keyboardType: TextInputType.text),
                            const SizedBox(height: 16),
                            _buildMultilineField(controller: _modeOfActionController, labelKey: 'Mode of Action'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Section 3: Detailed Usage Table
                      _buildSectionTitle('Usage Instructions (Crop-wise)'),
                      _buildUsageTableEditor(),
                      const SizedBox(height: 32),

                      // Section 4: Key Features & Expert Advice
                      _buildSectionTitle('Product Highlights'),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: _sectionDecoration(),
                        child: Column(
                          children: [
                            _buildKeyFeaturesEditor(),
                            const SizedBox(height: 24),
                            _buildMultilineField(controller: _expertAdviceController, labelKey: 'Expert Advice / Agronomist Quote'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Section 5: Variants (Sizes & Multipacks)
                      _buildSectionTitle('Sizes & Pricing Variants'),
                      _buildVariantsEditor(),
                      const SizedBox(height: 32),
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
                                    controller: _purchasePriceController,
                                    labelKey: LocalizationService.isTamil ? 'வாங்கிய விலை' : 'Purchase Price',
                                    keyboardType: TextInputType.number,
                                    prefixText: '₹ ',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _stockController,
                                    labelKey: 'owner_stock_field_stock',
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _batchNumberController,
                                    labelKey: LocalizationService.isTamil ? 'பேட்ச் எண்' : 'Batch Number',
                                    keyboardType: TextInputType.text,
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

                      // [NEW] Section 2.5: Expiry Info
                      _buildSectionTitle(LocalizationService.isTamil ? 'காலாவதி விவரங்கள்' : 'Expiry Details'),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: _sectionDecoration(),
                        child: TextFormField(
                          controller: _expiryDateController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: LocalizationService.isTamil ? 'காலாவதி தேதி (விருப்பம்)' : 'Expiry Date (Optional)',
                            hintText: 'DD/MM/YYYY',
                            suffixIcon: const Icon(Icons.calendar_today, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedExpiryDate ?? DateTime.now().add(const Duration(days: 365)),
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now().add(const Duration(days: 3650)),
                            );
                            if (picked != null) {
                              setState(() {
                                _selectedExpiryDate = picked;
                                _expiryDateController.text = DateFormat('dd/MM/yyyy').format(picked);
                              });
                            }
                          },
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
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildDateTimePicker(
                                        context: context,
                                        controller: _offerStartController,
                                        label: LocalizationService.isTamil ? 'தொடக்க தேதி மற்றும் நேரம்' : 'Start Date & Time',
                                        onPicked: (d) => setState(() {
                                          _offerStart = d;
                                          _offerStartController.text = DateFormat('dd/MM/yyyy HH:mm').format(d);
                                        }),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildDateTimePicker(
                                        context: context,
                                        controller: _offerEndController,
                                        label: LocalizationService.isTamil ? 'முடிவு தேதி மற்றும் நேரம்' : 'End Date & Time',
                                        onPicked: (d) => setState(() {
                                          _offerEnd = d;
                                          _offerEndController.text = DateFormat('dd/MM/yyyy HH:mm').format(d);
                                        }),
                                      ),
                                    ),
                                  ],
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
                            const SizedBox(height: 32),
                            _buildSectionTitle(LocalizationService.isTamil ? 'QR மற்றும் அளவு விவரங்கள்' : 'QR & Dosage Details'),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _qrIdController,
                                    labelKey: LocalizationService.isTamil ? 'QR ஐடி' : 'QR ID',
                                    keyboardType: TextInputType.text,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: _scanQRCodeForId,
                                  icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                                  tooltip: LocalizationService.isTamil ? 'QR ஸ்கேன் செய்' : 'Scan QR',
                                )
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _dosagePerCentTaController,
                              labelKey: LocalizationService.isTamil ? 'அளவு (சென்ட் ஒன்றுக்கு) - தமிழ்' : 'Dosage (per cent) - Tamil',
                              keyboardType: TextInputType.text,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _dosagePerCentEnController,
                              labelKey: LocalizationService.isTamil ? 'அளவு (சென்ட் ஒன்றுக்கு) - ஆங்கிலம்' : 'Dosage (per cent) - English',
                              keyboardType: TextInputType.text,
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

  Widget _buildEntryMethodOptions() {
    final isTa = LocalizationService.isTamil;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(isTa ? 'சேர்க்கும் முறை' : 'Entry Method'),
        Row(
          children: [
            _entryMethodCard(
              icon: Icons.qr_code_scanner,
              label: isTa ? 'QR ஸ்கேன்' : 'QR Scan',
              onTap: () {
                setState(() => _entryMethod = 'qr');
                _scanQRCodeForProductInfo();
              },
              isActive: _entryMethod == 'qr',
            ),
            const SizedBox(width: 8),
            _entryMethodCard(
              icon: Icons.upload_file,
              label: isTa ? 'கோப்பு பதிவேற்றம்' : 'File Upload',
              onTap: () {
                setState(() => _entryMethod = 'file');
                _pickAndParseProductFile();
              },
              isActive: _entryMethod == 'file',
            ),
            const SizedBox(width: 8),
            _entryMethodCard(
              icon: Icons.edit_note,
              label: isTa ? 'தட்டச்சு செய்' : 'By Type',
              onTap: () => setState(() => _entryMethod = 'type'),
              isActive: _entryMethod == 'type',
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _entryMethodCard({required IconData icon, required String label, required VoidCallback onTap, bool isActive = false}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isActive ? AppColors.primary : Colors.grey.shade200),
            boxShadow: [
              if (!isActive)
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: isActive ? Colors.white : AppColors.primary, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.notoSansTamil(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndParseProductFile() async {
    final isTa = LocalizationService.isTamil;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        _fillFormWithData(data);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isTa ? 'கோப்பு விவரங்கள் நிரப்பப்பட்டன' : 'File details populated')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isTa ? 'கோப்பை படிக்க முடியவில்லை' : 'Error reading file')),
      );
    }
  }

  void _fillFormWithData(Map<String, dynamic> data) {
    setState(() {
      _entryMethod = 'type';
      if (data.containsKey('name_ta')) _nameTaController.text = data['name_ta'].toString();
      if (data.containsKey('name_en')) _nameEnController.text = data['name_en'].toString();
      if (data.containsKey('price')) _priceController.text = data['price'].toString();
      if (data.containsKey('unit_ta')) _unitTaController.text = data['unit_ta'].toString();
      if (data.containsKey('unit_en')) _unitEnController.text = data['unit_en'].toString();
      if (data.containsKey('description_ta')) _descriptionTaController.text = data['description_ta'].toString();
      if (data.containsKey('description_en')) _descriptionEnController.text = data['description_en'].toString();
      if (data.containsKey('dosage_ta')) _dosageTaController.text = data['dosage_ta'].toString();
      if (data.containsKey('dosage_en')) _dosageEnController.text = data['dosage_en'].toString();
      if (data.containsKey('safety_ta')) _safetyTaController.text = data['safety_ta'].toString();
      if (data.containsKey('safety_en')) _safetyEnController.text = data['safety_en'].toString();
      if (data.containsKey('qrId')) _qrIdController.text = data['qrId'].toString();
      if (data.containsKey('categoryId')) _selectedCategoryId = data['categoryId'].toString();
      if (data.containsKey('subCategory')) _selectedSubCategory = data['subCategory'].toString();
      if (data.containsKey('brand')) _brandController.text = data['brand'].toString();
      if (data.containsKey('cropUsedFor')) _cropUsedForController.text = data['cropUsedFor'].toString();
      if (data.containsKey('pestControlled')) _targetPestController.text = data['pestControlled'].toString();
      if (data.containsKey('applicationMethod')) _applicationMethodController.text = data['applicationMethod'].toString();
    });
  }

  // [NEW] Helper to calculate preview
  String _getOfferPreviewText() {
    final originalPrice = double.tryParse(_priceController.text) ?? 0;
    if (originalPrice <= 0) return '';

    // Create a temporary data map for PriceUtils
    final tempItem = {
      'price': originalPrice,
      'isOfferActive': _isOfferActive,
      'offerType': _offerType,
      'offerValue': double.tryParse(_offerValueController.text) ?? 0,
      'offerStart': _offerStart != null ? Timestamp.fromDate(_offerStart!) : null,
      'offerEnd': _offerEnd != null ? Timestamp.fromDate(_offerEnd!) : null,
    };

    final finalPrice = PriceUtils.calculateFinalPrice(tempItem);
    final actuallyActive = PriceUtils.isOfferActuallyActive(tempItem);

    if (!actuallyActive && _isOfferActive) {
      return LocalizationService.isTamil 
        ? 'தற்போது ஆஃபர் செயலில் இல்லை (காலக்கெடு காரணமாக)' 
        : 'Offer is not active for the selected period';
    }

    return "${LocalizationService.tr('msg_offer_preview')} ₹$originalPrice -> ₹${finalPrice.toStringAsFixed(0)}";
  }

  Future<void> _scanQRCodeForProductInfo() async {
    final isTa = LocalizationService.isTamil;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(isTa ? 'தயாரிப்பு விவரங்களுக்கு ஸ்கேன் செய்யவும்' : 'Scan for Product Details', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: MobileScanner(
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty) {
                      final code = barcodes.first.rawValue;
                      if (code != null) {
                        try {
                          final data = jsonDecode(code) as Map<String, dynamic>;
                          _fillFormWithData(data);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(isTa ? 'விவரங்கள் வெற்றிகரமாக நிரப்பப்பட்டன' : 'Details filled successfully')),
                          );
                        } catch (e) {
                          // [NEW] Fallback: If not JSON, it's just a QR ID
                          setState(() {
                            _qrIdController.text = code;
                            _entryMethod = 'type';
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(isTa ? 'QR ஐடி கண்டுபிடிக்கப்பட்டது' : 'QR ID captured')),
                          );
                        }
                      }
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelKey,
    TextInputType? keyboardType,
    String? hintKey,
    String? prefixText,
    String? suffixText,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: LocalizationService.tr(labelKey),
        hintText: hintKey != null ? LocalizationService.tr(hintKey) : hint,
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

  Widget _buildDateTimePicker({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required Function(DateTime) onPicked,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 3650)),
        );
        if (date != null) {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );
          if (time != null) {
            final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
            onPicked(dt);
          }
        }
      },
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      LocalizationService.isTamil ? (doc.data()['name_ta'] ?? doc.data()['name_en'] ?? '') : (doc.data()['name_en'] ?? doc.data()['name_ta'] ?? ''),
                      style: GoogleFonts.notoSansTamil(fontSize: 13),
                    ),
                  ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                  _selectedSubCategory = null; // Reset subcategory when category changes
                });
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubCategoryDropdown() {
    final isTa = LocalizationService.isTamil;
    final subs = _selectedCategoryId != null ? _subCategoriesMap[_selectedCategoryId] : null;

    return DropdownButtonFormField<String>(
      value: _selectedSubCategory,
      decoration: InputDecoration(
        labelText: isTa ? 'துணை வகை' : 'Sub-Category',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: (subs ?? []).map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
      onChanged: (val) => setState(() => _selectedSubCategory = val),
      validator: (val) => val == null && subs != null && subs.isNotEmpty ? 'Required' : null,
    );
  }

  Widget _buildBrandField() {
    final isTa = LocalizationService.isTamil;
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _popularBrands.contains(_brandController.text) ? _brandController.text : null,
          decoration: InputDecoration(
            labelText: isTa ? 'நிறுவனம் / பிராண்ட்' : 'Company / Brand',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          items: _popularBrands.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
          onChanged: (val) => setState(() => _brandController.text = val ?? ''),
          hint: Text(isTa ? 'பிராண்டைத் தேர்ந்தெடுக்கவும்' : 'Select a Brand'),
        ),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _brandController,
          labelKey: isTa ? 'அல்லது புதிய பிராண்ட்' : 'Or Type Brand Name',
          keyboardType: TextInputType.text,
        ),
      ],
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

  Future<void> _scanQRCodeForId() async {
    final isTa = LocalizationService.isTamil;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(isTa ? 'தயாரிப்பு QR ஐ ஸ்கேன் செய்யவும்' : 'Scan Product QR', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: MobileScanner(
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty) {
                      final code = barcodes.first.rawValue;
                      if (code != null) {
                        setState(() {
                          _qrIdController.text = code;
                        });
                        Navigator.pop(ctx);
                      }
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
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
        'purchasePrice': double.tryParse(_purchasePriceController.text.trim()) ?? 0.0, // [NEW]
        'batchNumber': _batchNumberController.text.trim(), // [NEW]
        'categoryId': _selectedCategoryId,
        'shopId': 'default_shop',
        'description_ta': _descriptionTaController.text.trim(),
        'description_en': _descriptionEnController.text.trim(),
        'dosage_ta': _dosageTaController.text.trim(),
        'dosage_en': _dosageEnController.text.trim(),
        'safety_ta': _safetyTaController.text.trim(),
        'safety_en': _safetyEnController.text.trim(),
        'qrId': _qrIdController.text.trim(),
        'dosage_per_cent_ta': _dosagePerCentTaController.text.trim(),
        'dosage_per_cent_en': _dosagePerCentEnController.text.trim(),
        'subCategory': _selectedSubCategory,
        'brand': _brandController.text.trim(),
        'cropUsedFor': _cropUsedForController.text.trim(),
        'pestControlled': _targetPestController.text.trim(),
        'applicationMethod': _applicationMethodController.text.trim(),
        'varietyName': _varietyNameController.text.trim(),
        'growingConditions': _growingConditionsController.text.trim(),
        'benefits': _benefitsController.text.trim(),
        'technicalName': _technicalNameController.text.trim(),
        'composition': _compositionController.text.trim(),
        'classification': _classificationController.text.trim(),
        'toxicity': _toxicityController.text.trim(),
        'modeOfEntry': _modeOfEntryController.text.trim(),
        'modeOfAction': _modeOfActionController.text.trim(),
        'expertAdvice': _expertAdviceController.text.trim(),
        'keyFeatures': _featureControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList(),
        'usageTable': _usageTableRows.map((row) => {
          'crop': row['crop']!.text.trim(),
          'pest': row['pest']!.text.trim(),
          'dosageAcre': row['dosageAcre']!.text.trim(),
          'dilution': row['dilution']!.text.trim(),
          'dosageWater': row['dosageWater']!.text.trim(),
          'waiting': row['waiting']!.text.trim(),
        }).toList(),
        'variants': _variantRows.map((row) => {
          'size': row['size']!.text.trim(),
          'price': double.tryParse(row['price']!.text.trim()) ?? 0.0,
          'mrp': double.tryParse(row['mrp']!.text.trim()) ?? 0.0,
          'unit': row['unit']!.text.trim(),
        }).toList(),
        'expiryDate': _selectedExpiryDate != null ? Timestamp.fromDate(_selectedExpiryDate!) : null,
      };

      if (offerPercent != null) {
        data['offerPercent'] = offerPercent; // Backwards compatibility if needed
      }

      // [NEW] Integrated Offer Logic
      data['isOfferActive'] = _isOfferActive;
      data['offerType'] = _offerType; // 'percentage' or 'flat'
      data['offerValue'] = double.tryParse(_offerValueController.text.trim()) ?? 0.0;
      data['offerStart'] = _offerStart != null ? Timestamp.fromDate(_offerStart!) : null;
      data['offerEnd'] = _offerEnd != null ? Timestamp.fromDate(_offerEnd!) : null;


      if (imageUrl != null && imageUrl.isNotEmpty) {
        data['imageUrl'] = imageUrl;
      }

      // [NEW] Clear missing info badge when saved manually
      data['needsManualUpdate'] = false;

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
  Widget _buildKeyFeaturesEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Key Features', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
              onPressed: () => setState(() => _featureControllers.add(TextEditingController())),
            ),
          ],
        ),
        ...List.generate(_featureControllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _featureControllers[index],
                    decoration: InputDecoration(
                      hintText: 'e.g. Controls broad spectrum of pests',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () => setState(() => _featureControllers.removeAt(index)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildUsageTableEditor() {
    return Container(
      decoration: _sectionDecoration(),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Usage Table', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              TextButton.icon(
                onPressed: () => setState(() => _usageTableRows.add({
                  'crop': TextEditingController(),
                  'pest': TextEditingController(),
                  'dosageAcre': TextEditingController(),
                  'dilution': TextEditingController(),
                  'dosageWater': TextEditingController(),
                  'waiting': TextEditingController(),
                })),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Row'),
              ),
            ],
          ),
          const Divider(),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 20,
              columns: const [
                DataColumn(label: Text('Crop')),
                DataColumn(label: Text('Pest')),
                DataColumn(label: Text('Dosage/Acre')),
                DataColumn(label: Text('Dilution')),
                DataColumn(label: Text('Waiting')),
                DataColumn(label: Text('')),
              ],
              rows: List.generate(_usageTableRows.length, (index) {
                final row = _usageTableRows[index];
                return DataRow(cells: [
                  DataCell(_miniField(row['crop']!)),
                  DataCell(_miniField(row['pest']!)),
                  DataCell(_miniField(row['dosageAcre']!)),
                  DataCell(_miniField(row['dilution']!)),
                  DataCell(_miniField(row['waiting']!)),
                  DataCell(IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                    onPressed: () => setState(() => _usageTableRows.removeAt(index)),
                  )),
                ]);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantsEditor() {
    return Container(
      decoration: _sectionDecoration(),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Variants & Pricing', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              TextButton.icon(
                onPressed: () => setState(() => _variantRows.add({
                  'size': TextEditingController(),
                  'price': TextEditingController(),
                  'mrp': TextEditingController(),
                  'unit': TextEditingController(),
                })),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Variant'),
              ),
            ],
          ),
          const Divider(),
          ...List.generate(_variantRows.length, (index) {
            final row = _variantRows[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: 0,
                color: Colors.grey.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildTextField(controller: row['size']!, labelKey: 'Size / Pack', keyboardType: TextInputType.text)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildTextField(controller: row['unit']!, labelKey: 'Unit', keyboardType: TextInputType.text)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => setState(() => _variantRows.removeAt(index)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(controller: row['price']!, labelKey: 'Sell Price', keyboardType: TextInputType.number, prefixText: '₹')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildTextField(controller: row['mrp']!, labelKey: 'MRP', keyboardType: TextInputType.number, prefixText: '₹')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _miniField(TextEditingController c) {
    return SizedBox(
      width: 100,
      child: TextField(
        controller: c,
        decoration: const InputDecoration(isDense: true, border: InputBorder.none),
      ),
    );
  }
}

