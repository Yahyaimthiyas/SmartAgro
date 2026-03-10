import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'farmer_voice_advisory_screen.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import '../../../core/services/gemini_advisory_service.dart';
import 'package:provider/provider.dart';
import '../cart/cart_provider.dart';
import '../products/farmer_product_details_screen.dart';
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
  
  // Products fetched based on remedy suggestion
  List<DocumentSnapshot> _recommendedProducts = [];
  bool _isLoadingProducts = false;

  // Advisory Messages State
  Map<String, bool> _readState = {};
  Map<String, bool> _deletedState = {};

  @override
  void initState() {
    super.initState();
    _loadReadState();
  }

  Future<void> _loadReadState() async {
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
        setState(() {
          _readState = read;
          _deletedState = deleted;
        });
      }
    } catch (_) {}
  }

  Future<void> _markRead(String messageId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('advisory_reads')
          .doc(messageId)
          .set({
        'readAt': FieldValue.serverTimestamp(),
        'deleted': false,
      }, SetOptions(merge: true));
      if (mounted) {
        setState(() {
          _readState[messageId] = true;
          _deletedState[messageId] = false;
        });
      }
    } catch (_) {}
  }

  Future<void> _hideMessage(String messageId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('advisory_reads')
          .doc(messageId)
          .set({
        'deleted': true,
        'readAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) {
        setState(() {
          _deletedState[messageId] = true;
          _readState[messageId] = true;
        });
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
        });
        _analyzeImage(pickedFile);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _analyzeImage(XFile image) async {
    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          LocalizationService.tr('home_advisory'),
          style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAiDoctorHeader(),
            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 32),
            _buildImagePreview(),
            if (_isAnalyzing) _buildAnalyzingState(),
            if (_errorMessage != null) _buildErrorState(),
            if (_analysisResult != null && !_isAnalyzing) _buildAnalysisResults(),
            const SizedBox(height: 48),
            _buildAdvisoryMessagesSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAiDoctorHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.psychology_outlined, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            LocalizationService.tr('ai_doctor_title'),
            style: GoogleFonts.notoSansTamil(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            LocalizationService.tr('ai_doctor_subtitle'),
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansTamil(
              fontSize: 14,
              color: const Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isAnalyzing ? null : () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: Text(LocalizationService.tr('btn_take_photo')),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isAnalyzing ? null : () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: Text(LocalizationService.tr('btn_upload_gallery')),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImage == null) return const SizedBox.shrink();
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.file(
            File(_selectedImage!.path),
            height: 250,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAnalyzingState() {
    return Column(
      children: [
        const Center(child: CircularProgressIndicator()),
        const SizedBox(height: 16),
        Center(
          child: Text(
            LocalizationService.tr('ai_analyzing'),
            style: GoogleFonts.notoSansTamil(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade400, size: 48),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansTamil(
              color: Colors.red.shade800,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _selectedImage == null ? null : () => _analyzeImage(_selectedImage!),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                LocalizationService.tr('btn_retry_analysis') ?? 'Retry Analysis',
                style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvisoryMessagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.forum_outlined, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              LocalizationService.tr('advisory_messages_appbar'),
              style: GoogleFonts.notoSansTamil(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('advisory_messages')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: LinearProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];
            final visible = docs.where((d) => _deletedState[d.id] != true).toList();

            if (visible.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    LocalizationService.tr('advisory_messages_empty'),
                    style: GoogleFonts.notoSansTamil(color: AppColors.textSecondary),
                  ),
                ),
              );
            }

            return Column(
              children: visible.map((doc) {
                final data = doc.data();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildAdvisoryMessageTile(doc.id, data),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAdvisoryMessageTile(String id, Map<String, dynamic> data) {
    final titleTa = data['title_ta'] as String? ?? '';
    final titleEn = data['title_en'] as String? ?? '';
    final summaryTa = data['summary_ta'] as String? ?? '';
    final type = data['type'] as String? ?? 'general';
    final ts = data['createdAt'] as Timestamp?;
    final created = ts?.toDate();
    final isRead = _readState[id] == true;

    Color typeColor;
    IconData typeIcon;
    switch (type) {
      case 'pest':
        typeColor = Colors.redAccent;
        typeIcon = Icons.bug_report_rounded;
        break;
      case 'weather':
        typeColor = Colors.blueAccent;
        typeIcon = Icons.wb_sunny_rounded;
        break;
      default:
        typeColor = AppColors.primary;
        typeIcon = Icons.article_rounded;
    }

    return InkWell(
      onTap: () {
        _markRead(id);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => FarmerVoiceAdvisoryScreen(messageId: id)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFF0F9FF),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(typeIcon, size: 12, color: typeColor),
                                const SizedBox(width: 4),
                                Text(
                                  type.toUpperCase(),
                                  style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: typeColor),
                                ),
                              ],
                            ),
                          ),
                          if (created != null)
                            Text(
                              '${created.day}/${created.month}',
                              style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        LocalizationService.isTamil ? titleTa : titleEn,
                        style: GoogleFonts.notoSansTamil(
                          fontSize: 15,
                          fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        summaryTa,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.notoSansTamil(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisResults() {
    final res = _analysisResult!;
    
    if (res['isPlant'] == false) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange),
            const SizedBox(height: 12),
            Text(
              LocalizationService.tr('ai_error_no_crops'),
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansTamil(fontSize: 16, color: Colors.orange.shade900),
            ),
          ],
        ),
      );
    }

    if (res['isHealthy'] == true) {
       return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
            const SizedBox(height: 12),
            Text(
              "Your plant appears to be healthy! No diseases detected.",
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansTamil(fontSize: 16, color: Colors.green.shade900),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
             color: Colors.red.shade50,
             borderRadius: BorderRadius.circular(16),
             border: Border.all(color: Colors.red.shade100)
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.coronavirus_outlined, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    LocalizationService.tr('diagnosis_title'),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.red.shade900),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                res['diseaseName'] ?? 'Unknown Disease',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red.shade900),
              ),
              const SizedBox(height: 8),
              Text(
                res['cause'] ?? '',
                style: GoogleFonts.notoSansTamil(fontSize: 14, color: Colors.red.shade800),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
             color: Colors.blue.shade50,
             borderRadius: BorderRadius.circular(16),
             border: Border.all(color: Colors.blue.shade100)
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.medical_services_outlined, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    LocalizationService.tr('remedy_title'),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                res['remedySuggestion'] ?? 'General Care',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
              ),
              const SizedBox(height: 16),
              
              _buildDetailRow(Icons.science_outlined, "Dosage", res['dosage']),
              _buildDetailRow(Icons.layers_outlined, LocalizationService.tr('label_application_method'), res['applicationMethod']),
              _buildDetailRow(Icons.access_time_outlined, LocalizationService.tr('label_best_time'), res['bestTime']),
              _buildDetailRow(Icons.gpp_maybe_outlined, LocalizationService.tr('label_safety_precautions'), res['safetyPrecautions'], isUrgent: true),
            ],
          ),
        ),

        const SizedBox(height: 16),

        if (res['expertTips'] != null && res['expertTips'].toString().isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
               color: AppColors.primaryLight.withOpacity(0.2),
               borderRadius: BorderRadius.circular(16),
               border: Border.all(color: AppColors.primary.withOpacity(0.3))
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.stars, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocalizationService.tr('label_expert_tips'),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        res['expertTips'],
                        style: GoogleFonts.notoSansTamil(fontSize: 14, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 32),
        
        if (_isLoadingProducts) ...[
           const Center(child: CircularProgressIndicator()),
        ] else if (_recommendedProducts.isNotEmpty) ...[
           _buildShopRecommendations(),
        ] else if (!_isLoadingProducts && _analysisResult != null && _analysisResult!['isPlant'] == true && _analysisResult!['isHealthy'] == false) ...[
           Container(
             padding: const EdgeInsets.all(16),
             margin: const EdgeInsets.only(top: 16),
             decoration: BoxDecoration(
               color: Colors.grey.shade100,
               borderRadius: BorderRadius.circular(16),
               border: Border.all(color: Colors.grey.shade300)
             ),
             child: Column(
               children: [
                 Icon(Icons.inventory_2_outlined, color: Colors.grey.shade600, size: 32),
                 const SizedBox(height: 8),
                 const Text(
                   "No specific products for this disease found in the shop's current inventory. Please consult a local agricultural expert.",
                   textAlign: TextAlign.center,
                   style: TextStyle(fontSize: 14, color: Colors.black54),
                 ),
               ],
             ),
           ),
        ]
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String? value, {bool isUrgent = false}) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: isUrgent ? Colors.red : Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12, 
                  fontWeight: FontWeight.bold, 
                  color: isUrgent ? Colors.red : Colors.blue.shade800
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 24.0),
            child: Text(
              value,
              style: GoogleFonts.notoSansTamil(
                fontSize: 14, 
                color: isUrgent ? Colors.red.shade900 : AppColors.textPrimary,
                fontWeight: isUrgent ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocalizationService.tr('shop_recommendations'),
          style: GoogleFonts.notoSansTamil(
            fontSize: 18, 
            fontWeight: FontWeight.bold, 
            color: AppColors.textPrimary
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _recommendedProducts.length,
            itemBuilder: (context, index) {
              final doc = _recommendedProducts[index];
              final data = doc.data() as Map<String, dynamic>;
              
              final isTa = LocalizationService.isTamil;
              final name = isTa ? (data['name_ta'] ?? data['name_en']) : (data['name_en'] ?? data['name_ta']);
              final price = (data['price'] ?? 0).toDouble();
              final imageUrl = data['imageUrl'] as String?;
              final unitTa = data['unit_ta'] ?? '';
              final unitEn = data['unit_en'] ?? '';
              final stock = data['stock'] as int? ?? 0;

              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                         Navigator.push(
                           context,
                           MaterialPageRoute(builder: (_) => FarmerProductDetailsScreen(productId: doc.id, cropId: null)),
                         );
                      },
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: imageUrl != null && imageUrl.isNotEmpty 
                          ? CommonImage(imageUrl: imageUrl, width: 160, height: 110, fit: BoxFit.cover)
                          : Container(width: 160, height: 110, color: Colors.grey.shade200, child: const Icon(Icons.image, color: Colors.grey)),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "₹$price",
                              style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: stock <= 0 ? null : () {
                                  context.read<CartProvider>().addItem(
                                    productId: doc.id,
                                    nameTa: data['name_ta'] ?? '',
                                    nameEn: data['name_en'] ?? '',
                                    price: price,
                                    unitTa: unitTa,
                                    unitEn: unitEn,
                                    imageUrl: imageUrl,
                                    quantity: 1,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(LocalizationService.tr('snackbar_added_to_cart')),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                                child: Text(
                                  LocalizationService.tr('btn_add_to_cart'),
                                  style: GoogleFonts.notoSansTamil(fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
