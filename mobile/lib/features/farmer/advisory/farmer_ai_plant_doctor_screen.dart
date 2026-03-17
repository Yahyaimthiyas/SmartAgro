import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'farmer_voice_advisory_screen.dart';
import 'farmer_disease_search_screen.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import '../../../core/services/gemini_advisory_service.dart';
import 'package:provider/provider.dart';
import '../cart/cart_provider.dart';
import '../products/farmer_product_details_screen.dart';
import '../products/widgets/product_grid_card.dart';
import '../../../core/widgets/common_image.dart';

class FarmerAiPlantDoctorScreen extends StatefulWidget {
  const FarmerAiPlantDoctorScreen({super.key});

  @override
  State<FarmerAiPlantDoctorScreen> createState() => _FarmerAiPlantDoctorScreenState();
}

class _FarmerAiPlantDoctorScreenState extends State<FarmerAiPlantDoctorScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;
  String? _errorMessage;
  
  List<DocumentSnapshot> _recommendedProducts = [];
  bool _isLoadingProducts = false;

  Map<String, bool> _readState = {};
  Map<String, bool> _deletedState = {};

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  Future<void> _loadStates() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('advisory_reads')
          .get();
      final read = <String, bool>{};
      final deleted = <String, bool>{};
      for (final d in snap.docs) {
        final data = d.data();
        read[d.id] = data['readAt'] != null;
        deleted[d.id] = data['deleted'] == true;
      }
      if (mounted) {
        setState(() { _readState = read; _deletedState = deleted; });
      }
    } catch (_) {}
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 768,
        maxHeight: 768,
        imageQuality: 75,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = pickedFile;
          _analysisResult = null;
          _errorMessage = null;
          _recommendedProducts = [];
          _isAnalyzing = true;
        });
        _analyzeImage(pickedFile);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _analyzeImage(XFile image) async {
    try {
      final productsSnapshot = await FirebaseFirestore.instance.collection('products').get();
      final List<Map<String, dynamic>> shopProducts = productsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name_en'] ?? data['name_ta'] ?? 'Unknown',
          'category': data['categoryId'] ?? 'General',
          'description': data['description_en'] ?? data['description_ta'] ?? '',
        };
      }).toList();

      final result = await GeminiAdvisoryService.analyzePlantImage(image, shopProducts);
      
      if (!mounted) return;
      
      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
      });

      if (result['isPlant'] == true && result['isHealthy'] == false) {
          final recommendedIds = List<String>.from(result['recommendedProductIds'] ?? []);
          _fetchRecommendedProducts(recommendedIds);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _fetchRecommendedProducts(List<String> productIds) async {
    if (productIds.isEmpty) return;
    setState(() => _isLoadingProducts = true);
    try {
       final querySnapshot = await FirebaseFirestore.instance
           .collection('products')
           .where(FieldPath.documentId, whereIn: productIds.take(10).toList())
           .get();

       setState(() {
          _recommendedProducts = querySnapshot.docs;
          _isLoadingProducts = false;
       });
    } catch (e) {
       setState(() => _isLoadingProducts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(LocalizationService.isTamil ? 'AI பயிர் டாக்டர்' : 'AI Plant Doctor'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmerDiseaseSearchScreen())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            _buildAiHeader(),
            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 32),
            if (_selectedImage != null) _buildImagePreview(),
            if (_isAnalyzing) _buildAnalyzingState(),
            if (_errorMessage != null) _buildErrorState(),
            if (_analysisResult != null && !_isAnalyzing) _buildAnalysisResults(),
            const SizedBox(height: 40),
            _buildAdvisorySection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAiHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.psychology_outlined, size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            LocalizationService.tr('ai_doctor_title'),
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            LocalizationService.tr('ai_doctor_subtitle'),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _pickImage(ImageSource.camera),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt_rounded, size: 20),
                SizedBox(width: 8),
                Text('Camera'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _pickImage(ImageSource.gallery),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              side: const BorderSide(color: AppColors.border),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library_rounded, size: 20),
                SizedBox(width: 8),
                Text('Gallery'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.file(File(_selectedImage!.path), height: 240, width: double.infinity, fit: BoxFit.cover),
    );
  }

  Widget _buildAnalyzingState() {
     return Padding(
       padding: const EdgeInsets.symmetric(vertical: 32),
       child: Column(
         children: [
           const CircularProgressIndicator(strokeWidth: 3),
           const SizedBox(height: 16),
           Text(LocalizationService.tr('ai_analyzing'), style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
         ],
       ),
     );
  }

  Widget _buildErrorState() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.shade100)),
      child: Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade900)),
    );
  }

  Widget _buildAnalysisResults() {
    final res = _analysisResult!;
    if (res['isPlant'] == false) {
      return Container(
        margin: const EdgeInsets.only(top: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(16)),
        child: Text(LocalizationService.tr('ai_error_no_crops'), textAlign: TextAlign.center, style: TextStyle(color: Colors.orange.shade900)),
      );
    }

    if (res['isHealthy'] == true) {
      return Container(
        margin: const EdgeInsets.only(top: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(16)),
        child: const Text("Your plant looks healthy!", textAlign: TextAlign.center, style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 24),
        _buildResultCard(
          Icons.coronavirus_outlined,
          LocalizationService.tr('diagnosis_title'),
          res['diseaseName'] ?? 'Disease Found',
          res['cause'],
          AppColors.googleRed,
        ),
        const SizedBox(height: 16),
        _buildResultCard(
          Icons.medical_services_outlined,
          LocalizationService.tr('remedy_title'),
          res['remedySuggestion'] ?? 'Treatments',
          "Dosage: ${res['dosage'] ?? 'N/A'}\nMethod: ${res['applicationMethod'] ?? 'N/A'}",
          AppColors.googleBlue,
        ),
        if (_recommendedProducts.isNotEmpty) _buildShopRecommendations(),
      ],
    );
  }

  Widget _buildResultCard(IconData icon, String title, String main, String? sub, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 24),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: accentColor)),
            ],
          ),
          const SizedBox(height: 12),
          Text(main, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          if (sub != null) ...[
            const SizedBox(height: 8),
            Text(sub, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
          ],
        ],
      ),
    );
  }

  Widget _buildShopRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(LocalizationService.isTamil ? 'அறிந்துரைக்கப்படும் பொருட்கள்' : 'Recommended Products', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _recommendedProducts.length,
            itemBuilder: (context, index) {
              final doc = _recommendedProducts[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: SizedBox(width: 160, child: ProductGridCard(productId: doc.id, data: doc.data() as Map<String, dynamic>)),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdvisorySection() {
     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Text(LocalizationService.tr('advisory_messages_appbar'), style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
         const SizedBox(height: 12),
         StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('advisory_messages').limit(3).snapshots(),
            builder: (context, snapshot) {
               final docs = snapshot.data?.docs ?? [];
               if (docs.isEmpty) return const SizedBox.shrink();
               return Column(
                  children: docs.map((d) => _buildMessageTile(d)).toList(),
               );
            },
         ),
       ],
     );
  }

  Widget _buildMessageTile(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final isTa = LocalizationService.isTamil;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.article_outlined, color: AppColors.primary),
        title: Text(isTa ? data['title_ta'] : data['title_en'], style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FarmerVoiceAdvisoryScreen(messageId: doc.id))),
      ),
    );
  }
}
class _ProductRank {
  final DocumentSnapshot doc;
  final double rating;
  _ProductRank(this.doc, this.rating);
}
