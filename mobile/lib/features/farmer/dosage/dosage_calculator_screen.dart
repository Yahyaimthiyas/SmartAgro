import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import '../cart/cart_provider.dart';

class DosageCalculatorScreen extends StatefulWidget {
  final String productId;
  final String? cropId;

  const DosageCalculatorScreen({super.key, required this.productId, this.cropId});

  @override
  State<DosageCalculatorScreen> createState() => _DosageCalculatorScreenState();
}

class _DosageCalculatorScreenState extends State<DosageCalculatorScreen> {
  final TextEditingController _areaController = TextEditingController();
  String _areaUnit = 'acres';

  bool _loading = true;
  bool _adding = false;

  String _productNameTa = '';
  String _productNameEn = '';
  num _price = 0;
  String _unitTa = '';
  String _unitEn = '';
  String? _imageUrl;

  double? _ratePerAcre; // in rateUnit per acre
  String _rateUnit = 'kg';
  double? _packSize; // in packUnit
  String _packUnit = 'kg';

  static const double _hectareToAcre = 2.471; // approx

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    try {
      final prodSnap = await FirebaseFirestore.instance.collection('products').doc(widget.productId).get();
      if (!prodSnap.exists) {
        setState(() => _loading = false);
        return;
      }
      final p = prodSnap.data()!;

      _productNameTa = p['name_ta'] as String? ?? '';
      _productNameEn = p['name_en'] as String? ?? '';
      _price = p['price'] as num? ?? 0;
      _unitTa = p['unit_ta'] as String? ?? '';
      _unitEn = p['unit_en'] as String? ?? '';
      _imageUrl = p['imageUrl'] as String?;

      _ratePerAcre = (p['dosageRatePerAcre'] as num?)?.toDouble();
      _rateUnit = (p['dosageRateUnit'] as String?) ?? (_unitEn.isNotEmpty ? _unitEn : 'kg');
      _packSize = (p['dosagePackSize'] as num?)?.toDouble();
      _packUnit = (p['dosagePackUnit'] as String?) ?? _rateUnit;

      if (widget.cropId != null) {
        final cropSnap = await FirebaseFirestore.instance.collection('crops').doc(widget.cropId!).get();
        if (cropSnap.exists) {
          final c = cropSnap.data()!;
          final area = (c['area'] as num?)?.toDouble();
          final unit = (c['areaUnit'] as String?) ?? 'acres';
          if (area != null && area > 0) {
            _areaController.text = area.toStringAsFixed(1);
          }
          _areaUnit = unit;
        }
      }
    } catch (_) {
      // Fail silently; UI will show zero values.
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  double get _areaValue {
    final v = double.tryParse(_areaController.text.trim());
    if (v == null || v <= 0) return 0;
    return v;
  }

  double get _areaInAcres {
    final a = _areaValue;
    if (a <= 0) return 0;
    return _areaUnit == 'hectares' ? a * _hectareToAcre : a;
  }

  double get _requiredQuantity {
    if (_ratePerAcre == null || _ratePerAcre! <= 0) return 0;
    final areaAcres = _areaInAcres;
    if (areaAcres <= 0) return 0;
    return areaAcres * _ratePerAcre!;
  }

  int get _bagsNeeded {
    if (_packSize == null || _packSize! <= 0) return 0;
    final req = _requiredQuantity;
    if (req <= 0) return 0;
    return (req / _packSize!).ceil();
  }

  Future<void> _addToCart() async {
    if (_bagsNeeded <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService.tr('dosage_calc_error_invalid_area')),
        ),
      );
      return;
    }

    setState(() => _adding = true);
    try {
      context.read<CartProvider>().addItem(
            productId: widget.productId,
            nameTa: _productNameTa,
            nameEn: _productNameEn,
            price: _price,
            unitTa: _unitTa,
            unitEn: _unitEn,
            imageUrl: _imageUrl,
            quantity: _bagsNeeded,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService.tr('snackbar_added_to_cart')),
        ),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => _adding = false);
      }
    }
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
          LocalizationService.tr('dosage_calc_appbar'),
          style: GoogleFonts.notoSansTamil(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                   // Product Header
                   Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                         color: Colors.white,
                         borderRadius: BorderRadius.circular(20),
                         border: Border.all(color: Colors.grey.shade200)
                      ),
                      child: Row(
                         children: [
                            Container(
                               width: 48,
                               height: 48,
                               decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12)
                               ),
                               child: const Icon(Icons.science_rounded, color: AppColors.primary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                               child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                     Text(
                                        _productNameTa,
                                        style: GoogleFonts.notoSansTamil(
                                           fontSize: 16,
                                           fontWeight: FontWeight.bold,
                                           color: AppColors.textPrimary
                                        ),
                                     ),
                                     if (_ratePerAcre != null && _ratePerAcre! > 0) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                           '${LocalizationService.tr('dosage_calc_rate_label')}: ${_ratePerAcre!.toStringAsFixed(1)} $_rateUnit/acre',
                                           style: GoogleFonts.notoSansTamil(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                     ]
                                  ],
                               ),
                            )
                         ],
                      ),
                   ),
                   const SizedBox(height: 32),
                   
                   // Calculator Section
                   Text(
                    LocalizationService.tr('dosage_calc_land_area_label'),
                    style: GoogleFonts.notoSansTamil(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Container(
                     decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                           BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10)
                           )
                        ]
                     ),
                     padding: const EdgeInsets.all(20),
                     child: Column(
                        children: [
                           // Input Row
                           Row(
                            children: [
                              Expanded(
                                child: Container(
                                   padding: const EdgeInsets.symmetric(horizontal: 16),
                                   decoration: BoxDecoration(
                                      color: const Color(0xFFF8F9FA),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade200)
                                   ),
                                  child: TextField(
                                    controller: _areaController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
                                    decoration: const InputDecoration(
                                      hintText: '0.0',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                             padding: const EdgeInsets.all(4),
                             decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(12)
                             ),
                             child: Row(
                                children: [
                                   _unitButton('acres', LocalizationService.tr('dosage_calc_unit_acres')),
                                   _unitButton('hectares', LocalizationService.tr('dosage_calc_unit_hectares')),
                                ],
                             ),
                          )
                        ],
                     ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Result Card
                  _buildResultCard(),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _adding || _bagsNeeded <= 0 ? null : _addToCart,
              style: ElevatedButton.styleFrom(
                 backgroundColor: AppColors.primary,
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                 elevation: 4
              ),
              child: _adding
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      LocalizationService.tr('dosage_calc_btn_add_to_cart'),
                      style: GoogleFonts.notoSansTamil(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
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
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                 color: isSelected ? Colors.white : Colors.transparent,
                 borderRadius: BorderRadius.circular(10),
                 boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : []
              ),
              child: Text(
                 label,
                 style: GoogleFonts.notoSansTamil(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? AppColors.textPrimary : AppColors.textSecondary
                 ),
              ),
           ),
        ),
     );
  }

  Widget _buildResultCard() {
    final requiredQty = _requiredQuantity;
    final bags = _bagsNeeded;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
           colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
           begin: Alignment.topLeft,
           end: Alignment.bottomRight
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
           BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10)
           )
        ]
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
                const Icon(Icons.shopping_bag_outlined, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                Text(
                  LocalizationService.tr('dosage_calc_required_label'),
                  style: GoogleFonts.notoSansTamil(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
             ],
          ),
          const SizedBox(height: 16),
          Text(
            requiredQty > 0
                ? '${requiredQty.toStringAsFixed(1)} $_rateUnit'
                : '-',
            style: GoogleFonts.notoSansTamil(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1
            ),
          ),
          const SizedBox(height: 8),
          Container(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
             decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20)
             ),
             child: Text(
               bags > 0
                   ? '$bags ${LocalizationService.tr('dosage_calc_bags_suffix')}'
                   : LocalizationService.tr('dosage_calc_bags_suffix'),
               style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
             ),
          ),
        ],
      ),
    );
  }
}

