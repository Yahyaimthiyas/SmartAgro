import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import 'widgets/product_grid_card.dart';

class FarmerProductSearchScreen extends StatefulWidget {
  const FarmerProductSearchScreen({super.key});

  @override
  State<FarmerProductSearchScreen> createState() => _FarmerProductSearchScreenState();
}

class _FarmerProductSearchScreenState extends State<FarmerProductSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus the search field when entering the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTa = LocalizationService.isTamil;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F3F4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
            decoration: InputDecoration(
              hintText: isTa ? 'தயாரிப்புகளைத் தேடுங்கள்...' : 'Search for products...',
              hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
              suffixIcon: _searchQuery.isNotEmpty 
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ),
      body: _searchQuery.isEmpty
          ? _buildInitialState(isTa)
          : _buildSearchResults(isTa),
    );
  }

  Widget _buildInitialState(bool isTa) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            isTa ? 'தயாரிப்புகளைத் தேடத் தொடங்குங்கள்' : 'Type to search for products',
            style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(bool isTa) {
    // Note: Simple Firestore search using prefix matching
    // For a real production app, consider using Algolia or ElasticSearch for better fuzzy search.
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .snapshots(), // We filter locally for better responsiveness in this simple case
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        
        // Local filtering logic to support both Tamil and English searching
        final filteredDocs = docs.where((doc) {
          final data = doc.data();
          final nameEn = (data['name_en'] as String? ?? '').toLowerCase();
          final nameTa = (data['name_ta'] as String? ?? '').toLowerCase();
          final q = _searchQuery.toLowerCase();
          return nameEn.contains(q) || nameTa.contains(q);
        }).toList();

        if (filteredDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  isTa ? 'தயாரிப்புகள் எதுவும் கிடைக்கவில்லை' : 'No products found',
                  style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.68,
          ),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            return ProductGridCard(
              productId: filteredDocs[index].id,
              data: filteredDocs[index].data(),
            );
          },
        );
      },
    );
  }
}
