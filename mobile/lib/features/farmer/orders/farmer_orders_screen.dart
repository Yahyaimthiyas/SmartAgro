import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import '../../../core/widgets/common_image.dart';
import 'farmer_order_tracking_screen.dart';

class FarmerOrdersScreen extends StatefulWidget {
  const FarmerOrdersScreen({super.key});

  @override
  State<FarmerOrdersScreen> createState() => _FarmerOrdersScreenState();
}

class _FarmerOrdersScreenState extends State<FarmerOrdersScreen> {
  String _selectedFilter = 'all'; // all, active, completed, cancelled

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isTa = LocalizationService.isTamil;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(LocalizationService.tr('title_my_orders'))),
        body: Center(child: Text(LocalizationService.tr('error_login_again'))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isTa ? 'எனது ஆர்டர்கள்' : 'My Orders',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilterBar(isTa),
          Expanded(child: _buildOrdersList(user.uid, isTa)),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isTa) {
    final filters = [
      {'id': 'all', 'label': isTa ? 'அனைத்தும்' : 'All'},
      {'id': 'active', 'label': isTa ? 'செயலில்' : 'Active'},
      {'id': 'completed', 'label': isTa ? 'முடிந்தது' : 'Completed'},
      {'id': 'cancelled', 'label': isTa ? 'ரத்து செய்யப்பட்டது' : 'Cancelled'},
    ];

    return Container(
      height: 60,
      color: Colors.white,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final f = filters[index];
          final isSelected = _selectedFilter == f['id'];
          return InkWell(
            onTap: () => setState(() => _selectedFilter = f['id']!),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : const Color(0xFFF1F3F4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                f['label']!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrdersList(String uid, bool isTa) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snapshot.data?.docs ?? [];
        
        // Local filtering and sorting
        var docs = allDocs.where((doc) {
          final data = doc.data();
          final status = data['status'] as String? ?? 'reserved';
          
          if (_selectedFilter == 'all') return true;
          if (_selectedFilter == 'active') return status == 'reserved' || status == 'ready';
          if (_selectedFilter == 'completed') return status == 'picked';
          if (_selectedFilter == 'cancelled') return status == 'cancelled';
          return true;
        }).toList();

        docs.sort((a, b) {
          final t1 = a.data()['createdAt'] as Timestamp?;
          final t2 = b.data()['createdAt'] as Timestamp?;
          if (t1 == null || t2 == null) return 0;
          return t2.compareTo(t1);
        });

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  isTa ? 'ஆர்டர்கள் எதுவும் இல்லை' : 'No orders found',
                  style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) => _buildOrderCard(docs[index], isTa),
        );
      },
    );
  }

  Widget _buildOrderCard(DocumentSnapshot<Map<String, dynamic>> doc, bool isTa) {
    final data = doc.data()!;
    final id = doc.id;
    final status = data['status'] as String? ?? 'reserved';
    final total = data['totalAmount'] as num? ?? 0;
    final items = data['items'] as List<dynamic>? ?? [];
    final firstItem = items.isNotEmpty ? items.first : null;
    final String? imageUrl = firstItem != null ? firstItem['imageUrl'] : null;
    final String itemName = firstItem != null ? (isTa ? (firstItem['name_ta'] ?? '') : (firstItem['name_en'] ?? '')) : 'Order';
    
    final ts = data['createdAt'] as Timestamp?;
    final date = ts != null ? ts.toDate() : DateTime.now();
    final statusMeta = _getStatusMeta(status, isTa);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image Thumbnail with +X badge if multiple items
                Stack(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: (imageUrl != null && imageUrl.isNotEmpty)
                            ? CommonImage(imageUrl: imageUrl, fit: BoxFit.cover)
                            : Icon(Icons.shopping_basket_outlined, color: Colors.grey.shade400, size: 30),
                      ),
                    ),
                    if (items.length > 1)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: Text(
                            '+${items.length - 1}',
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                // Order Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusMeta.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              statusMeta.label.toUpperCase(),
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: statusMeta.color),
                            ),
                          ),
                          Text(
                            '₹${total.toStringAsFixed(0)}',
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        items.length > 1 ? '$itemName + ${items.length - 1} more' : itemName,
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF222222)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: #${id.substring(id.length - 8).toUpperCase()}',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${date.day}/${date.month}/${date.year} · ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F3F4)),
          // Action Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isTa ? 'விவரங்களைக் காண்க' : 'View Details',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FarmerOrderTrackingScreen(orderId: id))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: status == 'picked' ? const Color(0xFFF1F3F4) : AppColors.primary.withOpacity(0.1),
                    foregroundColor: status == 'picked' ? Colors.grey.shade700 : AppColors.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    isTa ? 'ஆர்டரைத் தொடரவும்' : 'Track Order',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _StatusMeta _getStatusMeta(String status, bool isTa) {
    switch (status) {
      case 'ready':
        return _StatusMeta(isTa ? 'தயார்' : 'Ready', Colors.orange);
      case 'picked':
        return _StatusMeta(isTa ? 'சேகரிக்கப்பட்டது' : 'Picked Up', Colors.green);
      case 'cancelled':
        return _StatusMeta(isTa ? 'ரத்து செய்யப்பட்டது' : 'Cancelled', Colors.red);
      default:
        return _StatusMeta(isTa ? 'வைக்கப்பட்டது' : 'Placed', Colors.blue);
    }
  }
}

class _StatusMeta {
  final String label;
  final Color color;
  _StatusMeta(this.label, this.color);
}
