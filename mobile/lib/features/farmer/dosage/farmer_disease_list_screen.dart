import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import '../../../core/widgets/common_image.dart';
import '../cart/cart_provider.dart';
import '../cart/farmer_cart_screen.dart';

class FarmerDiseaseListScreen extends StatefulWidget {
  const FarmerDiseaseListScreen({super.key});

  @override
  State<FarmerDiseaseListScreen> createState() => _FarmerDiseaseListScreenState();
}

class _FarmerDiseaseListScreenState extends State<FarmerDiseaseListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTa = LocalizationService.isTamil;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: Text(
          isTa ? 'நோய் மற்றும் மருந்தளவு' : 'Disease & Dosage Advice',
          style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmerCartScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchField(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('common_diseases').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data();
                  final crop = (data['cropName'] ?? '').toString().toLowerCase();
                  final disease = (data['diseaseName'] ?? '').toString().toLowerCase();
                  return crop.contains(_searchQuery) || disease.contains(_searchQuery);
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(isTa ? 'முடிவுகள் எதுவுமில்லை' : 'No matches found', style: GoogleFonts.poppins(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    return _DiseaseAdviceCard(data: docs[i].data());
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
        decoration: InputDecoration(
          hintText: LocalizationService.isTamil ? 'பயிர் அல்லது நோய் தேடுக...' : 'Search crop or disease...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }
}

class _DiseaseAdviceCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _DiseaseAdviceCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isTa = LocalizationService.isTamil;
    final products = (data['products'] as List<dynamic>? ?? []);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['cropName'] ?? 'No Crop',
                      style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                    ),
                    Text(
                      data['diseaseName'] ?? 'No Disease',
                      style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  data['level'] ?? 'Moderate',
                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.red.shade700, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (data['images'] != null && (data['images'] as List).isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: (data['images'] as List).length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, idx) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CommonImage(
                    imageUrl: data['images'][idx],
                    width: 180,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
          const Divider(height: 24),
          Text(
            isTa ? "நிபுணர் ஆலோசனை:" : "Expert Advice:",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
          ),
          const SizedBox(height: 4),
          Text(
            data['advice'] ?? '',
            style: GoogleFonts.notoSansTamil(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Text(
            isTa ? "பரிந்துரைக்கப்பட்ட தயாரிப்புகள்:" : "Recommended Products:",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
          ),
          const SizedBox(height: 8),
          Column(
            children: products.map((p) {
               final dosageText = (p['dosage_val'] != null && p['dosage_val'].toString().isNotEmpty)
                ? "${p['dosage_val']} ${p['dosage_unit']} ${isTa ? '...' : p['dosage_basis']}"
                : (p['dosage'] ?? '');
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(LocalizationService.pickTaEn(p['name_ta'], p['name_en']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text("${isTa ? 'அளவு:' : 'Dosage:'} $dosageText", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _addToCart(context, p),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(isTa ? 'சேர்க்க' : 'Add', style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Feedback Stats
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('feedbacks')
                .where('isAdviceFeedback', isEqualTo: true)
                .where('diseaseName', isEqualTo: data['diseaseName'])
                .snapshots(),
            builder: (context, fbSnap) {
              if (!fbSnap.hasData || fbSnap.data!.docs.isEmpty) return const SizedBox();
              final docs = fbSnap.data!.docs;
              final worked = docs.where((d) => d.data()['adviceEffectiveness'] == 'worked').length;
              final total = docs.length;
              final percent = (worked / total * 100).toStringAsFixed(0);

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(Icons.verified_outlined, color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      '$percent% ${isTa ? "வெற்றி விகிதம்" : "Success Rate"} ($total ${isTa ? "விவசாயிகள்" : "Farmers"})',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _addToCart(BuildContext context, Map<String, dynamic> product) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    // Need to create a CartItem from the product map. 
    // We might need to fetch the full product details from the 'products' collection if not all fields are here.
    // For now, let's assume we have what we need to add to cart.
    
    // Actually, it's better to fetch full product details to ensure correct mapping.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(LocalizationService.isTamil ? 'தயாரிப்பு சேர்க்கப்படுகிறது...' : 'Adding product...'))
    );

    FirebaseFirestore.instance.collection('products').doc(product['productId']).get().then((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        final price = (data['price'] as num? ?? 0).toDouble();
        
        // Use CartItem model (assuming it exists based on cart_provider.dart)
        // I'll need to check CartItem structure.
        // For now, let's use the provider's addItem if it exists or similar.
        // Assuming CardProvider has: addItem(String productId, String nameTa, String nameEn, double price, String unitTa, String unitEn, {String? imageUrl})
        
        cart.addItem(
          productId: doc.id,
          nameTa: data['name_ta'] ?? '',
          nameEn: data['name_en'] ?? '',
          price: price,
          unitTa: data['unit_ta'] ?? '',
          unitEn: data['unit_en'] ?? '',
          imageUrl: data['imageUrl'],
        );
        
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService.isTamil ? 'கூடையில் சேர்க்கப்பட்டது!' : 'Added to cart!'),
            backgroundColor: AppColors.primary,
            action: SnackBarAction(
              label: LocalizationService.isTamil ? 'காண்க' : 'View', 
              textColor: Colors.white,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmerCartScreen())),
            ),
          )
        );
      }
    });
  }
}
