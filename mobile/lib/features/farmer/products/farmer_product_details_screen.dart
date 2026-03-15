import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../core/widgets/common_image.dart'; // [NEW]
import '../../../core/services/localization_service.dart';
import '../cart/cart_provider.dart';
import '../../../core/utils/price_utils.dart';

class FarmerProductDetailsScreen extends StatefulWidget {
  final String productId;
  final String? cropId;

  const FarmerProductDetailsScreen({
    super.key,
    required this.productId,
    this.cropId,
  });

  @override
  State<FarmerProductDetailsScreen> createState() => _FarmerProductDetailsScreenState();
}

class _FarmerProductDetailsScreenState extends State<FarmerProductDetailsScreen>
    with SingleTickerProviderStateMixin {
  int _quantity = 1;
  Map<String, dynamic>? _selectedVariant;
  
  // Cache the product data to prevent reloading on tab switches
  Map<String, dynamic>? _cachedProductData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProductData();
  }

  Future<void> _loadProductData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .get();
      
      if (mounted) {
        setState(() {
          _cachedProductData = doc.exists ? doc.data() : null;
          if (_cachedProductData != null) {
            final variants = _cachedProductData!['variants'] as List<dynamic>? ?? [];
            if (variants.isNotEmpty) {
              _selectedVariant = variants[0] as Map<String, dynamic>;
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTa = LocalizationService.isTamil;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cachedProductData == null
              ? Center(
                  child: Text(
                    LocalizationService.tr('msg_product_not_found'),
                    style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textSecondary),
                  ),
                )
              : _buildProductContent(_cachedProductData!, isTa),
    );
  }

  Widget _buildProductContent(Map<String, dynamic> data, bool isTa) {
    final nameTa = data['name_ta'] as String? ?? '';
    final nameEn = data['name_en'] as String? ?? '';
    final price = data['price'] as num? ?? 0;
    final unitTa = data['unit_ta'] as String? ?? '';
    final unitEn = data['unit_en'] as String? ?? '';
    final stock = data['stock'] as int? ?? 0;
    final imageUrl = data['imageUrl'] as String?;
    final descriptionTa = data['description_ta'] as String? ?? '';
    final descriptionEn = data['description_en'] as String? ?? '';

    String stockLabelTa;
    String stockLabelEn;
    Color stockColor;
    Color stockBgColor;
    
    if (stock <= 0) {
      stockLabelTa = LocalizationService.tr('stock_out_ta');
      stockLabelEn = LocalizationService.tr('stock_out_en');
      stockColor = Colors.red;
      stockBgColor = Colors.red.shade50;
    } else if (stock <= 3) {
      stockLabelTa = LocalizationService.tr('stock_low_ta');
      stockLabelEn = LocalizationService.tr('stock_low_en');
      stockColor = Colors.orange;
      stockBgColor = Colors.orange.shade50;
    } else {
      stockLabelTa = LocalizationService.tr('stock_in_ta');
      stockLabelEn = LocalizationService.tr('stock_in_en');
      stockColor = Colors.green;
      stockBgColor = Colors.green.shade50;
    }

    final displayName = LocalizationService.pickTaEn(nameTa, nameEn);
    final displayUnit = LocalizationService.pickTaEn(unitTa, unitEn);
    final stockText = isTa ? stockLabelTa : stockLabelEn;
    
    // [NEW] Privacy: Hide exact count, just show status
    final stockDisplay = stockText; 


    final maxQty = stock > 0 ? stock : 1;
    if (_quantity > maxQty) _quantity = maxQty;

    final salesCount = data['salesCount'] as int? ?? 0;
    final brand = data['brand'] as String? ?? '';
    final technicalName = data['technicalName'] as String? ?? '';
    final expertAdvice = data['expertAdvice'] as String? ?? '';
    final keyFeatures = data['keyFeatures'] as List<dynamic>? ?? [];
    final usageTable = data['usageTable'] as List<dynamic>? ?? [];
    final variants = data['variants'] as List<dynamic>? ?? [];

    final currentPrice = _selectedVariant != null ? (_selectedVariant!['price'] as num) : PriceUtils.calculateFinalPrice(data);
    final currentMRP = _selectedVariant != null ? (_selectedVariant!['mrp'] as num) : price;
    final currentUnit = _selectedVariant != null ? "${_selectedVariant!['size']} ${_selectedVariant!['unit']}" : displayUnit;

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
             SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                 icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                 onPressed: () => Navigator.of(context).pop(),
                 style: IconButton.styleFrom(
                   backgroundColor: AppColors.primary.withOpacity(0.4),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                 ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    imageUrl != null && imageUrl.isNotEmpty
                        ? CommonImage(imageUrl: imageUrl, fit: BoxFit.cover)
                        : Container(
                            color: Colors.grey[100],
                            child: const Icon(Icons.image_outlined, size: 80, color: Colors.grey),
                          ),
                    if (salesCount >= 10)
                      Positioned(
                        top: 100,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade700,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_fire_department, color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                isTa ? 'அதிக விற்பனை' : 'Hot Selling',
                                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (brand.isNotEmpty)
                      Text(
                        brand.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 1.5,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      displayName,
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRatingAndStock(data, isTa, stockDisplay, stockColor, stockBgColor),
                    const SizedBox(height: 24),
                    _buildPricingSection(currentPrice, currentMRP, isTa),
                    const SizedBox(height: 16),
                    if (variants.isNotEmpty) _buildVariantSelector(variants, isTa),
                    const SizedBox(height: 24),
                    _buildSocialProofing(data, isTa),
                    const SizedBox(height: 32),
                    _buildInfoTable(data, isTa),
                    const SizedBox(height: 32),
                    if (technicalName.isNotEmpty) _buildCheaperAlternatives(technicalName, currentPrice, isTa),
                    const SizedBox(height: 32),
                    _buildDescription(isTa ? descriptionTa : descriptionEn, isTa),
                    const SizedBox(height: 32),
                    _buildReviewsSection(widget.productId, isTa),
                    const SizedBox(height: 32),
                    if (keyFeatures.isNotEmpty) _buildKeyFeaturesSection(keyFeatures, isTa),
                    const SizedBox(height: 32),
                    if (usageTable.isNotEmpty) _buildUsageTable(usageTable, isTa),
                    const SizedBox(height: 32),
                    if (expertAdvice.isNotEmpty) _buildExpertAdviceSection(expertAdvice, isTa),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
        
        // [MODERNIZED] Bottom Bar
        Positioned(
           left: 0, 
           right: 0, 
           bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                   BoxShadow(
                     color: Colors.black.withOpacity(0.12),
                     blurRadius: 30,
                     offset: const Offset(0, -10),
                   ),
                ],
              ),
              child: SafeArea(
                 child: Row(
                   children: [
                     // Quantity Selector
                     Container(
                       decoration: BoxDecoration(
                         color: Colors.grey[100],
                         borderRadius: BorderRadius.circular(16),
                         border: Border.all(color: Colors.grey[200]!),
                       ),
                       padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                       child: Row(
                         children: [
                           _qtyButton(
                             icon: Icons.remove, 
                             onTap: () {
                               if (_quantity > 1) setState(() => _quantity--);
                             }
                           ),
                           SizedBox(
                             width: 40,
                             child: Text(
                               '$_quantity',
                               textAlign: TextAlign.center,
                               style: GoogleFonts.poppins(
                                 fontSize: 18, 
                                 fontWeight: FontWeight.bold
                               ),
                             ),
                           ),
                           _qtyButton(
                             icon: Icons.add, 
                             onTap: () {
                                // Note: Max stock check is done in build(), but good to check here too if possible
                                setState(() => _quantity++); 
                             }
                           ),
                         ],
                       ),
                     ),
                     const SizedBox(width: 16),
                     
                     // Add to Cart Button
                     Expanded(
                       child: SizedBox(
                         height: 56,
                         child: ElevatedButton(
                           onPressed: stock <= 0
                               ? null
                               : () {
                                   context.read<CartProvider>().addItem(
                                         productId: widget.productId,
                                         nameTa: nameTa,
                                         nameEn: nameEn,
                                          price: currentPrice.toDouble(),
                                          unitTa: currentUnit,
                                          unitEn: currentUnit,
                                         imageUrl: imageUrl,
                                         quantity: _quantity,
                                       );
                                   ScaffoldMessenger.of(context).showSnackBar(
                                     SnackBar(
                                       content: Text(
                                         LocalizationService.tr('snackbar_added_to_cart'),
                                         style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.w600),
                                       ),
                                       backgroundColor: Colors.green.shade800,
                                       behavior: SnackBarBehavior.floating,
                                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                       margin: const EdgeInsets.all(16),
                                     ),
                                   );
                                 },
                           style: ElevatedButton.styleFrom(
                             backgroundColor: AppColors.primary,
                             foregroundColor: Colors.white,
                             elevation: 4,
                             shadowColor: AppColors.primary.withOpacity(0.4),
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                           ),
                           child: Text(
                             LocalizationService.tr('btn_add_to_cart'),
                             style: GoogleFonts.notoSansTamil(
                               fontSize: 18,
                               fontWeight: FontWeight.bold,
                             ),
                           ),
                         ),
                       ),
                     ),
                   ],
                 ),
              ),
           ),
        ),
      ],
    );
  }


  Widget _buildRatingAndStock(Map<String, dynamic> data, bool isTa, String stockDisplay, Color stockColor, Color stockBgColor) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('feedbacks')
          .where('productId', isEqualTo: widget.productId)
          .snapshots(),
      builder: (context, snapshot) {
        double avgRating = 0.0;
        int reviewCount = 0;
        
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
           reviewCount = snapshot.data!.docs.length;
           double total = 0;
           for (var doc in snapshot.data!.docs) {
              total += (doc.data()['rating'] as num? ?? 0).toDouble();
           }
           avgRating = total / reviewCount;
        }

        return Row(
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  reviewCount > 0 ? avgRating.toStringAsFixed(1) : '0.0', 
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)
                ),
                const SizedBox(width: 4),
                Text(
                  '($reviewCount ${isTa ? "மதிப்பீடுகள்" : "Reviews"})', 
                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13)
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: stockBgColor, borderRadius: BorderRadius.circular(8)),
              child: Text(stockDisplay, style: GoogleFonts.notoSansTamil(fontSize: 12, fontWeight: FontWeight.bold, color: stockColor)),
            ),
          ],
        );
      }
    );
  }

  Widget _buildPricingSection(num currentPrice, num currentMRP, bool isTa) {
    final savings = currentMRP - currentPrice;
    final offPercent = currentMRP > 0 ? ((savings / currentMRP) * 100).toInt() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('₹${currentPrice.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(width: 12),
            Text('₹${currentMRP.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 18, decoration: TextDecoration.lineThrough, color: Colors.grey)),
            const SizedBox(width: 12),
            if (offPercent > 0)
              Text('$offPercent% OFF', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
          ],
        ),
        if (savings > 0)
          Text('Save ₹${savings.toStringAsFixed(0)}', style: GoogleFonts.poppins(color: Colors.green.shade700, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Inclusive of all taxes', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildVariantSelector(List<dynamic> variants, bool isTa) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isTa ? 'அளவு:' : 'Size:', style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: variants.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final v = variants[index] as Map<String, dynamic>;
              final isSelected = _selectedVariant == v;
              return InkWell(
                onTap: () => setState(() => _selectedVariant = v),
                child: Container(
                  width: 120,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300, width: isSelected ? 2 : 1),
                    color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("${v['size']} ${v['unit']}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text("₹${v['price']}", style: GoogleFonts.poppins(fontSize: 14, color: AppColors.primary)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSocialProofing(Map<String, dynamic> data, bool isTa) {
    final salesCount = data['salesCount'] as int? ?? 0;
    if (salesCount < 5) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const Icon(Icons.flash_on, color: Colors.amber),
          const SizedBox(width: 12),
          Expanded(child: Text(isTa ? '$salesCount+ விவசாயிகள் இதனை வாங்கியுள்ளனர்' : '$salesCount+ farmers bought this recently', style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildInfoTable(Map<String, dynamic> data, bool isTa) {
    final rows = [
      {'label': 'Brand', 'value': data['brand'] ?? '-'},
      {'label': 'Category', 'value': data['categoryId'] ?? '-'},
      {'label': 'Technical', 'value': data['technicalName'] ?? '-'},
      {'label': 'Classification', 'value': data['classification'] ?? '-'},
      {'label': 'Toxicity', 'value': data['toxicity'] ?? '-'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Overview', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        Table(
          border: TableBorder.all(color: Colors.grey.shade200),
          children: rows.map((r) => TableRow(
            children: [
              Padding(padding: const EdgeInsets.all(12), child: Text(r['label']!, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.blueGrey))),
              Padding(padding: const EdgeInsets.all(12), child: Text(r['value']!.toString(), style: GoogleFonts.poppins())),
            ],
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildCheaperAlternatives(String technicalName, num currentPrice, bool isTa) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('technicalName', isEqualTo: technicalName)
          .where('price', isLessThan: currentPrice)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox();
        final alternatives = snapshot.data!.docs;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isTa ? 'அதே தரம், குறைந்த விலை!' : 'Same Chemical, Get Same Result', style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange.shade800)),
            const SizedBox(height: 16),
            ...alternatives.map((alt) {
              final altData = alt.data();
              final altPrice = PriceUtils.calculateFinalPrice(altData);
              final savingPer = (((currentPrice - altPrice) / currentPrice) * 100).toInt();
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: CommonImage(imageUrl: altData['imageUrl'], width: 60, height: 60),
                  title: Text(LocalizationService.pickTaEn(altData['name_ta'], altData['name_en'])),
                  subtitle: Text("Save $savingPer% Cheaper", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  trailing: Text("₹${altPrice.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => FarmerProductDetailsScreen(productId: alt.id))),
                ),
              );
            }).toList(),
          ],
        );
      }
    );
  }

  Widget _buildDescription(String desc, bool isTa) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isTa ? 'விளக்கம்' : 'Product Description', style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        Text(desc, style: GoogleFonts.poppins(height: 1.6, color: Colors.black87)),
      ],
    );
  }

  Widget _buildKeyFeaturesSection(List<dynamic> features, bool isTa) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(isTa ? 'சிறப்பம்சங்கள்' : 'Key Features', style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        ...features.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(f.toString(), style: GoogleFonts.poppins())),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildUsageTable(List<dynamic> usage, bool isTa) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isTa ? 'பயன்படுத்தும் முறை' : 'Usage and Crops', style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            border: TableBorder.all(color: Colors.grey.shade200),
            defaultColumnWidth: const IntrinsicColumnWidth(),
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade100),
                children: [
                  _headerCell('Crops'), _headerCell('Target Pest'), _headerCell('Dosage/Acre'), _headerCell('Waiting'),
                ],
              ),
              ...usage.map((u) {
                final m = u as Map<String, dynamic>;
                return TableRow(
                  children: [
                    _cell(m['crop'] ?? '-'), _cell(m['pest'] ?? '-'), _cell(m['dosageAcre'] ?? '-'), _cell(m['waiting'] ?? '-'),
                  ],
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _headerCell(String t) => Padding(padding: const EdgeInsets.all(12), child: Text(t, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12)));
  Widget _cell(String t) => Padding(padding: const EdgeInsets.all(12), child: Text(t.toString(), style: GoogleFonts.poppins(fontSize: 12)));

  Widget _buildExpertAdviceSection(String advice, bool isTa) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
               const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.person, color: Colors.white)),
               const SizedBox(width: 12),
               Text(isTa ? 'நிபுணர் ஆலோசனை' : 'Expert Advice', style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
            ],
          ),
          const SizedBox(height: 12),
          Text('"$advice"', style: GoogleFonts.poppins(fontStyle: FontStyle.italic, color: Colors.blueGrey.shade800)),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(String productId, bool isTa) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isTa ? 'வாடிக்கையாளர் மதிப்பீடுகள்' : 'Customer Reviews', 
          style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold, fontSize: 18)
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('feedbacks')
              .where('productId', isEqualTo: productId)
              .orderBy('createdAt', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Center(
                  child: Text(
                    isTa ? 'மதிப்பீடுகள் எதுவும் இல்லை' : 'No original reviews yet.',
                    style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
                  ),
                ),
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final fb = doc.data();
                final rating = fb['rating'] as int? ?? 5;
                final comment = fb['comment'] as String? ?? '';
                final userName = fb['userName'] as String? ?? 'Farmer';
                final imageUrl = fb['imageUrl'] as String?;
                final ownerReply = fb['ownerReply'] as String?;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                child: Text(userName.substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              Text(userName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                            ],
                          ),
                          Row(
                            children: List.generate(5, (index) => Icon(
                              index < rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 14,
                            )),
                          ),
                        ],
                      ),
                      if (comment.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(comment, style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87)),
                      ],
                      if (imageUrl != null) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CommonImage(imageUrl: imageUrl, height: 120, width: double.infinity, fit: BoxFit.cover),
                        ),
                      ],
                      if (ownerReply != null) ...[
                         const SizedBox(height: 12),
                         Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                            child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                  Text(isTa ? 'ஆசிரியர் பதில்:' : 'Owner Reply:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blue)),
                                  const SizedBox(height: 4),
                                  Text(ownerReply, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                               ],
                            ),
                         ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _qtyButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
