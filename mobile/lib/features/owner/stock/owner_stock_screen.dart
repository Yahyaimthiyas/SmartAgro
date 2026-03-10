import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import '../../../core/widgets/common_image.dart'; // [NEW]
import 'owner_bulk_upload_screen.dart';
import 'owner_edit_product_screen.dart';

class OwnerStockScreen extends StatefulWidget {
  const OwnerStockScreen({super.key});

  @override
  State<OwnerStockScreen> createState() => _OwnerStockScreenState();
}

class _OwnerStockScreenState extends State<OwnerStockScreen> {
  String _searchQuery = '';
  String _filter = 'all'; // all, low, out

  @override
  Widget build(BuildContext context) {
    final isTa = LocalizationService.isTamil;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: Text(
          LocalizationService.tr('owner_title_stock'),
          style: GoogleFonts.notoSansTamil(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_rounded),
            tooltip: 'Bulk Upload CSV',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OwnerBulkUploadScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('products').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDocs = snapshot.data?.docs ?? [];
                
                // Filter Logic
                final filteredDocs = allDocs.where((doc) {
                   final data = doc.data();
                   final nameTa = (data['name_ta'] as String? ?? '').toLowerCase();
                   final nameEn = (data['name_en'] as String? ?? '').toLowerCase();
                   final stock = data['stock'] as int? ?? 0;
                   
                   // Search
                   if (_searchQuery.isNotEmpty) {
                      if (!nameTa.contains(_searchQuery) && !nameEn.contains(_searchQuery)) {
                         return false;
                      }
                   }

                   // Filter chips
                   if (_filter == 'low') return stock > 0 && stock <= 5;
                   if (_filter == 'out') return stock <= 0;

                   return true;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: filteredDocs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return _ProductStockCard(
                      docId: filteredDocs[index].id,
                      data: filteredDocs[index].data(),
                      isTa: isTa,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const OwnerEditProductScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_circle_outline, color: Colors.white),
        label: Text(
           LocalizationService.tr('btn_add'),
           style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        children: [
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            decoration: InputDecoration(
              hintText: LocalizationService.tr('search_hint'),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: "All Items", 
                  isSelected: _filter == 'all', 
                  onTap: () => setState(() => _filter = 'all')
                ),
                const SizedBox(width: 8),
                _FilterChip(
                   label: "Low Stock (< 5)", 
                   isSelected: _filter == 'low',
                   color: Colors.orange, 
                   onTap: () => setState(() => _filter = 'low')
                ),
                const SizedBox(width: 8),
                _FilterChip(
                   label: "Out of Stock", 
                   isSelected: _filter == 'out', 
                   color: Colors.red,
                   onTap: () => setState(() => _filter = 'out')
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                 color: Colors.grey.shade100,
                 shape: BoxShape.circle,
              ),
              child: Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
           ),
           const SizedBox(height: 16),
           Text(
             "No products found",
             style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textSecondary),
           ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _FilterChip({
     required this.label, 
     required this.isSelected, 
     required this.onTap,
     this.color = AppColors.primary
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
             color: isSelected ? color : Colors.grey.shade300
          ),
          boxShadow: isSelected ? [
             BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))
          ] : null
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ProductStockCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final bool isTa;

  const _ProductStockCard({required this.docId, required this.data, required this.isTa});

  @override
  Widget build(BuildContext context) {
    final nameTa = data['name_ta'] as String? ?? '';
    final nameEn = data['name_en'] as String? ?? '';
    final price = data['price'] as num? ?? 0;
    final unitTa = data['unit_ta'] as String? ?? '';
    final unitEn = data['unit_en'] as String? ?? '';
    final stock = data['stock'] as int? ?? 0;
    final imageUrl = data['imageUrl'] as String?;
    final needsManualUpdate = data['needsManualUpdate'] as bool? ?? false;
    
    // [NEW] Offer info
    final isOfferActive = data['isOfferActive'] as bool? ?? false;
    final offerVal = (data['offerValue'] as num? ?? 0).toDouble();
    final offerType = data['offerType'] as String? ?? 'percentage';

    final displayName = LocalizationService.pickTaEn(nameTa, nameEn);
    final displayUnit = LocalizationService.pickTaEn(unitTa, unitEn);
    
    Color stockColor;
    String statusText;
    if (stock <= 0) {
      stockColor = Colors.red;
      statusText = "Out of Stock";
    } else if (stock <= 5) {
      stockColor = Colors.orange;
      statusText = "Low Stock";
    } else {
      stockColor = Colors.green;
      statusText = "In Stock";
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // Rounded consistent
        boxShadow: [
           BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6)
           )
        ]
      ),
      padding: const EdgeInsets.all(12), // Tighter padding
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                   width: 90,
                   height: 90,
                   color: const Color(0xFFF5F5F5),
                   child: imageUrl != null && imageUrl.isNotEmpty
                      ? CommonImage(imageUrl: imageUrl, fit: BoxFit.cover)
                      : Icon(Icons.image_not_supported, color: Colors.grey.shade400, size: 32),
                ),
              ),
              if (isOfferActive)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Text(
                      offerType == 'percentage' ? '${offerVal.toInt()}% OFF' : 'SALE',
                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                displayName,
                                style: isTa 
                                   ? GoogleFonts.notoSansTamil(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1A1C1E))
                                   : GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1A1C1E)),
                                maxLines: 1, 
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (needsManualUpdate || nameTa.isEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.orange.shade200),
                                ),
                                child: Text(
                                  "⚠️ Info",
                                  style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (stock <= 5)
                      Container(
                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                         decoration: BoxDecoration(
                            color: stockColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6)
                         ),
                         child: Text(
                            statusText,
                            style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: stockColor),
                         ),
                      )
                   ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '₹$price / $displayUnit',
                      style: GoogleFonts.notoSansTamil(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        decoration: isOfferActive ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (isOfferActive) ...[
                      const SizedBox(width: 6),
                      Text(
                         _getOfferPrice(price, offerType, offerVal),
                         style: GoogleFonts.notoSansTamil(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                         ),
                      ),
                    ]
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                      // Read-only stock display
                      Expanded(
                        child: Container(
                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                           decoration: BoxDecoration(
                              color: stockColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: stockColor.withOpacity(0.3), width: 1.5)
                           ),
                           child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                 Icon(Icons.inventory_2_outlined, size: 18, color: stockColor),
                                 const SizedBox(width: 6),
                                 Flexible(
                                   child: Text(
                                      'Stock: $stock',
                                      style: GoogleFonts.poppins(
                                         fontWeight: FontWeight.bold, 
                                         fontSize: 14,
                                         color: stockColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                   ),
                                 ),
                              ],
                           ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Edit button
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => OwnerEditProductScreen(productId: docId),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.white),
                        label: Text(
                           'Edit',
                           style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                           ),
                        ),
                        style: ElevatedButton.styleFrom(
                           backgroundColor: AppColors.primary,
                           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                           shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                           ),
                           elevation: 0,
                        ),
                      )
                   ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getOfferPrice(num price, String type, double val) {
    double finalPrice = price.toDouble();
    if (type == 'percentage') {
       finalPrice = price - (price * val / 100);
    } else {
       finalPrice = val;
    }
    return '₹${finalPrice.toStringAsFixed(0)}';
  }
}
