import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import 'farmer_add_crop_screen.dart';
import 'farmer_crop_details_screen.dart';

class FarmerMyCropsScreen extends StatefulWidget {
  const FarmerMyCropsScreen({super.key});

  @override
  State<FarmerMyCropsScreen> createState() => _FarmerMyCropsScreenState();
}

class _FarmerMyCropsScreenState extends State<FarmerMyCropsScreen> {
  
  String _labelForCrop(String id) {
    return LocalizationService.tr('crop_${id}_label');
  }

  String _unitLabel(String unit) {
    if (unit == 'hectares') {
      return LocalizationService.tr('crop_unit_hectares');
    }
    return LocalizationService.tr('crop_unit_acres');
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('crops')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = List<DocumentSnapshot<Map<String, dynamic>>>.from(snapshot.data?.docs ?? []);
          docs.sort((a, b) {
             final t1 = a.data()?['sowingDate'] as Timestamp?;
             final t2 = b.data()?['sowingDate'] as Timestamp?;
             if (t1 == null || t2 == null) return 0;
             return t2.compareTo(t1); 
          });

          if (docs.isEmpty) {
            return _buildEmptyState();
          }

          double totalArea = 0;
          for (var d in docs) {
             totalArea += (d.data()?['area'] as num?)?.toDouble() ?? 0;
          }

          return CustomScrollView(
             slivers: [
                SliverAppBar(
                   expandedHeight: 0,
                   pinned: true,
                   backgroundColor: const Color(0xFFF4F7F6),
                   elevation: 0,
                   title: Text(
                      LocalizationService.tr('mycrops_appbar'),
                      style: GoogleFonts.notoSansTamil(
                         color: AppColors.textPrimary,
                         fontWeight: FontWeight.bold
                      ),
                   ),
                   centerTitle: true,
                   iconTheme: const IconThemeData(color: AppColors.textPrimary),
                ),
                SliverToBoxAdapter(
                   child: _buildDashboardHeader(docs.length, totalArea),
                ),
                SliverPadding(
                   padding: const EdgeInsets.all(20),
                   sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                         (context, index) {
                            final doc = docs[index];
                            final data = doc.data();
                            final cropTypeId = data?['cropTypeId'] as String? ?? '';
                            final area = (data?['area'] as num?)?.toDouble() ?? 0;
                            final areaUnit = (data?['areaUnit'] as String?) ?? 'acres';
                            final ts = data?['sowingDate'] as Timestamp?;
                            final sowingDate = ts?.toDate();
                            final daysOld = sowingDate != null ? DateTime.now().difference(sowingDate).inDays : 0;

                            return _buildPremiumCropCard(
                              cropId: doc.id,
                              cropTypeId: cropTypeId,
                              area: area,
                              areaUnit: areaUnit,
                              daysOld: daysOld,
                            );
                         },
                         childCount: docs.length,
                      ),
                   ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)) // Fab Space
             ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FarmerAddCropScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          LocalizationService.tr('mycrops_btn_add_crop'),
          style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildDashboardHeader(int count, double area) {
     return Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
           gradient: const LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight
           ),
           borderRadius: BorderRadius.circular(24),
           boxShadow: [
              BoxShadow(
                 color: const Color(0xFF2E7D32).withOpacity(0.3),
                 blurRadius: 15,
                 offset: const Offset(0, 8)
              )
           ]
        ),
        child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
              Text(
                 "Farm Overview", // Localize later
                 style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500
                 ),
              ),
              const SizedBox(height: 16),
              Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                    _StatColumn("Active Crops", "$count"),
                    _StatColumn("Total Area", "${area.toStringAsFixed(1)} Ac"), // Simplified unit
                    _StatColumn("Health", "Good"),
                 ],
              )
           ],
        ),
     );
  }

  Widget _buildPremiumCropCard({
    required String cropId,
    required String cropTypeId,
    required double area,
    required String areaUnit,
    required int daysOld,
  }) {
    final cropLabel = _labelForCrop(cropTypeId.isEmpty ? 'rice' : cropTypeId);
    
    // Growth Progress Logic (Mock: Assuming 120 days is full cycle)
    double progress = (daysOld / 120).clamp(0.0, 1.0);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FarmerCropDetailsScreen(cropId: cropId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
           color: Colors.white,
           borderRadius: BorderRadius.circular(24),
           boxShadow: [
              BoxShadow(
                 color: Colors.black.withOpacity(0.04),
                 blurRadius: 12,
                 offset: const Offset(0, 6)
              )
           ]
        ),
        child: Column(
           children: [
              // Header Image Area
              Container(
                 padding: const EdgeInsets.all(20),
                 decoration: BoxDecoration(
                    color: Colors.green.shade50.withOpacity(0.5),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24))
                 ),
                 child: Row(
                    children: [
                       Container(
                          width: 56, height: 56,
                          decoration: const BoxDecoration(
                             color: Colors.white,
                             shape: BoxShape.circle,
                          ),
                          child: const Center(child: Icon(Icons.grass, color: AppColors.primary, size: 28)),
                       ),
                       const SizedBox(width: 16),
                       Expanded(
                          child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                                Text(
                                   cropLabel,
                                   style: GoogleFonts.notoSansTamil(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary
                                   ),
                                ),
                                Text(
                                   "${area.toStringAsFixed(1)} ${_unitLabel(areaUnit)}",
                                   style: GoogleFonts.notoSansTamil(
                                      fontSize: 14,
                                      color: AppColors.textSecondary
                                   ),
                                )
                             ],
                          ),
                       ),
                       Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                             color: Colors.white,
                             borderRadius: BorderRadius.circular(20)
                          ),
                          child: Row(
                             children: [
                                const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text(
                                   "Day $daysOld",
                                   style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.primary),
                                )
                             ],
                          ),
                       )
                    ],
                 ),
              ),
              
              // Progress Section
              Padding(
                 padding: const EdgeInsets.all(20),
                 child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             Text("Growth Stage", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                             Text("${(progress * 100).toInt()}%", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                       ),
                       const SizedBox(height: 8),
                       ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                             value: progress,
                             backgroundColor: Colors.grey.shade100,
                             color: AppColors.primary,
                             minHeight: 8,
                          ),
                       ),
                       const SizedBox(height: 20),
                       Row(
                          children: [
                             Expanded(
                                child: OutlinedButton(
                                   onPressed: () {}, // Future feature
                                   style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      side: BorderSide(color: Colors.grey.shade300)
                                   ),
                                   child: Text("Log Activity", style: GoogleFonts.notoSansTamil(fontSize: 12, color: AppColors.textPrimary)),
                                ),
                             ),
                             const SizedBox(width: 12),
                             Expanded(
                                child: ElevatedButton(
                                   onPressed: () {
                                      Navigator.of(context).push(
                                         MaterialPageRoute(
                                            builder: (_) => FarmerCropDetailsScreen(cropId: cropId),
                                         ),
                                      );
                                   },
                                   style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      elevation: 0
                                   ),
                                   child: Text("View Plan", style: GoogleFonts.notoSansTamil(fontSize: 12, color: Colors.white)),
                                ),
                             ),
                          ],
                       )
                    ],
                 ),
              )
           ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
     return Center(
        child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
              Icon(Icons.eco_outlined, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 24),
              Text(
                 LocalizationService.tr('mycrops_empty_title'),
                 style: GoogleFonts.notoSansTamil(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                 LocalizationService.tr('mycrops_empty_subtitle'),
                 style: GoogleFonts.poppins(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              FloatingActionButton.extended(
                 onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const FarmerAddCropScreen()),
                    );
                 },
                 backgroundColor: AppColors.primary,
                 icon: const Icon(Icons.add, color: Colors.white),
                 label: Text(LocalizationService.tr('mycrops_btn_add_crop'), style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold, color: Colors.white)),
              )
           ],
        ),
     );
  }
}

class _StatColumn extends StatelessWidget {
   final String label;
   final String value;
   const _StatColumn(this.label, this.value);

   @override
   Widget build(BuildContext context) {
      return Column(
         children: [
            Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70))
         ],
      );
   }
}
