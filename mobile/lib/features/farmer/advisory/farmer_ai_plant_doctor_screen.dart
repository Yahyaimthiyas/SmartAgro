import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/services/localization_service.dart';
import 'services/ai_service.dart';

class FarmerAIPlantDoctorScreen extends StatefulWidget {
  const FarmerAIPlantDoctorScreen({super.key});

  @override
  State<FarmerAIPlantDoctorScreen> createState() => _FarmerAIPlantDoctorScreenState();
}

class _FarmerAIPlantDoctorScreenState extends State<FarmerAIPlantDoctorScreen> with SingleTickerProviderStateMixin {
  File? _image;
  bool _isAnalyzing = false;
  DiagnosisResult? _result;
  final _aiService = AIService();
  late AnimationController _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(
       vsync: this,
       duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
        _result = null;
      });
      _analyze();
    }
  }

  Future<void> _analyze() async {
    setState(() => _isAnalyzing = true);
    try {
      final res = await _aiService.analyzeImage(_image!);
      setState(() => _result = res);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Analysis failed")));
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTa = LocalizationService.isTamil;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
           "AI Plant Doctor", // Localize later
           style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold, color: Colors.white)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Column(
        children: [
           // Image Area
           Expanded(
              flex: 4,
              child: Stack(
                 fit: StackFit.expand,
                 children: [
                    _image != null 
                       ? Image.file(_image!, fit: BoxFit.cover)
                       : Container(
                          color: Colors.grey.shade900,
                          child: Column(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                                const Icon(Icons.add_a_photo_outlined, color: Colors.white54, size: 64),
                                const SizedBox(height: 16),
                                Text(
                                   "Upload Crop Photo",
                                   style: GoogleFonts.poppins(color: Colors.white54, fontSize: 16),
                                )
                             ],
                          ),
                       ),
                    // Scanner Overlay
                    if (_isAnalyzing)
                       AnimatedBuilder(
                          animation: _scannerController,
                          builder: (context, child) {
                             return Positioned(
                                top: MediaQuery.of(context).size.height * 0.4 * _scannerController.value,
                                left: 0, right: 0,
                                child: Container(
                                   height: 4,
                                   decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      boxShadow: [
                                         BoxShadow(color: AppColors.primary, blurRadius: 10)
                                      ]
                                   ),
                                ),
                             );
                          },
                       ),
                    // Controls
                    Positioned(
                       bottom: 24,
                       left: 24, right: 24,
                       child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                             _TaskBtn(
                                icon: Icons.photo_library,
                                label: "Gallery",
                                onTap: () => _pickImage(ImageSource.gallery),
                             ),
                             _TaskBtn(
                                icon: Icons.camera_alt,
                                label: "Camera",
                                isPrimary: true,
                                onTap: () => _pickImage(ImageSource.camera),
                             ),
                          ],
                       ),
                    )
                 ],
              ),
           ),
           
           // Results Area
           Expanded(
              flex: 5,
              child: Container(
                 width: double.infinity,
                 decoration: const BoxDecoration(
                    color: Color(0xFFF4F7F6),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32))
                 ),
                 child: _isAnalyzing 
                    ? Center(
                       child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                             const CircularProgressIndicator(),
                             const SizedBox(height: 16),
                             Text(
                                "Analyzing Crop Health...",
                                style: GoogleFonts.poppins(color: AppColors.textSecondary),
                             )
                          ],
                       ),
                    )
                    : (_result == null 
                       ? Center(
                          child: Text(
                             "Take a photo to start diagnosis",
                             style: GoogleFonts.poppins(color: Colors.grey),
                          ),
                       )
                       : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                                Row(
                                   children: [
                                      Container(
                                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                         decoration: BoxDecoration(
                                            color: _result!.severity == 'high' ? Colors.red : Colors.orange,
                                            borderRadius: BorderRadius.circular(20)
                                         ),
                                         child: Text(
                                            (_result!.confidence * 100).toStringAsFixed(0) + "% Confidence",
                                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                         ),
                                      ),
                                      const Spacer(),
                                      const Icon(Icons.share, color: Colors.grey),
                                   ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                   isTa ? _result!.diseaseNameTa : _result!.diseaseNameEn,
                                   style: GoogleFonts.notoSansTamil(
                                      fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary
                                   ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                   isTa ? _result!.descriptionTa : _result!.descriptionEn,
                                   style: GoogleFonts.notoSansTamil(
                                      fontSize: 14, color: AppColors.textSecondary, height: 1.5
                                   ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                   "Recommended Treatment", // Localize
                                   style: GoogleFonts.notoSansTamil(
                                      fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary
                                   ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                   padding: const EdgeInsets.all(16),
                                   decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.blue.shade100)
                                   ),
                                   child: Row(
                                      children: [
                                         const Icon(Icons.medical_services_outlined, color: Colors.blue),
                                         const SizedBox(width: 12),
                                         Expanded(
                                            child: Text(
                                               isTa ? _result!.solutionTa : _result!.solutionEn,
                                               style: GoogleFonts.notoSansTamil(
                                                  fontSize: 14, color: Colors.blue.shade900, fontWeight: FontWeight.w500
                                               ),
                                            ),
                                         )
                                      ],
                                   ),
                                ),
                                const SizedBox(height: 24),
                                _ProductRecommendationRow(productIds: _result!.recommendedProductIds)
                             ],
                          ),
                       )
                    ),
              ),
           )
        ],
      ),
    );
  }
}

class _TaskBtn extends StatelessWidget {
   final IconData icon;
   final String label;
   final bool isPrimary;
   final VoidCallback onTap;

   const _TaskBtn({required this.icon, required this.label, this.isPrimary = false, required this.onTap});

   @override
   Widget build(BuildContext context) {
      return GestureDetector(
         onTap: onTap,
         child: Column(
            children: [
               Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                     color: isPrimary ? AppColors.primary : Colors.white24,
                     shape: BoxShape.circle,
                     boxShadow: isPrimary ? [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 10)] : null
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
               ),
               const SizedBox(height: 8),
               Text(label, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12))
            ],
         ),
      );
   }
}

class _ProductRecommendationRow extends StatelessWidget {
   final List<String> productIds;
   const _ProductRecommendationRow({required this.productIds});

   @override
   Widget build(BuildContext context) {
      // Mock Product Display
      return Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            Text(
               "Buy Medicines", 
               style: GoogleFonts.notoSansTamil(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
               height: 140,
               child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 2, // Mock 2 items
                  itemBuilder: (context, index) {
                     return Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                           color: Colors.white,
                           borderRadius: BorderRadius.circular(16)
                        ),
                        child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                              Expanded(
                                 child: Container(
                                    decoration: BoxDecoration(
                                       color: Colors.grey.shade100,
                                       borderRadius: BorderRadius.circular(12)
                                    ),
                                    child: const Center(child: Icon(Icons.inventory_2, color: AppColors.primary)),
                                 ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                 index == 0 ? "Tricyclazole" : "Neem Oil",
                                 style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                                 maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                 "₹450",
                                 style: GoogleFonts.poppins(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                              )
                           ],
                        ),
                     );
                  },
               ),
            )
         ],
      );
   }
}
