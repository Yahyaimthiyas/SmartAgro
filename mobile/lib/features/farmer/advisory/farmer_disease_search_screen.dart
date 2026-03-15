import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import '../products/farmer_product_details_screen.dart';

class FarmerDiseaseSearchScreen extends StatefulWidget {
  const FarmerDiseaseSearchScreen({super.key});

  @override
  State<FarmerDiseaseSearchScreen> createState() => _FarmerDiseaseSearchScreenState();
}

class _FarmerDiseaseSearchScreenState extends State<FarmerDiseaseSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final isTa = LocalizationService.isTamil;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          decoration: InputDecoration(
            hintText: isTa ? 'நோய் அல்லது பயிர் தேடுக...' : 'Search disease or crop...',
            border: InputBorder.none,
            hintStyle: GoogleFonts.notoSansTamil(fontSize: 14, color: Colors.grey),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _query.isEmpty 
        ? _buildEmptyState(isTa)
        : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('common_diseases').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              
              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data();
                final disease = (data['diseaseName'] ?? '').toString().toLowerCase();
                final crop = (data['cropName'] ?? '').toString().toLowerCase();
                return disease.contains(_query) || crop.contains(_query);
              }).toList();

              if (docs.isEmpty) {
                return Center(child: Text(isTa ? 'முடிவுகள் எதுவும் இல்லை' : 'No results found'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final data = docs[i].data();
                  return _buildDiseaseCard(data, isTa);
                },
              );
            },
          ),
    );
  }

  Widget _buildEmptyState(bool isTa) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            isTa ? 'நோயைக் கண்டறிய தேடத் தொடங்கவும்' : 'Start searching for diseases',
            style: GoogleFonts.notoSansTamil(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseCard(Map<String, dynamic> data, bool isTa) {
    final products = List.from(data['products'] ?? []);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data['diseaseName'] ?? 'Disease',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red.shade900),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(data['cropName'] ?? 'Crop', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${isTa ? 'நிலை' : 'Level'}: ${data['level']}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const Divider(height: 24),
          Text(
            isTa ? 'ஆலோசனை:' : 'Advice:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(data['advice'] ?? '', style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 16),
          Text(
            isTa ? 'பரிந்துரைக்கப்பட்ட பொருட்கள்:' : 'Recommended Products:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          for (final p in products)
            Card(
              elevation: 0,
              color: Colors.blue.shade50,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                dense: true,
                title: Text(p['name_en'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: Text('${isTa ? 'அளவு' : 'Dosage'}: ${p['dosage']}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 12),
                onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => FarmerProductDetailsScreen(productId: p['productId'])));
                },
              ),
            ),
        ],
      ),
    );
  }
}
