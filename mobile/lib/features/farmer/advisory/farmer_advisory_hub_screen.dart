import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import '../crops/farmer_my_crops_screen.dart';
import 'farmer_advisory_messages_screen.dart';
import '../alerts/farmer_alerts_screen.dart';
import 'farmer_ai_plant_doctor_screen.dart';

class FarmerAdvisoryHubScreen extends StatelessWidget {
  const FarmerAdvisoryHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            LocalizationService.tr('home_advisory'),
            style: GoogleFonts.notoSansTamil(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold),
            unselectedLabelStyle: GoogleFonts.notoSansTamil(fontWeight: FontWeight.normal),
            tabs: [
              Tab(text: LocalizationService.tr('home_my_crops')),
              Tab(text: LocalizationService.tr('advisory_messages_appbar')),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            FarmerMyCropsScreen(),
            FarmerAdvisoryMessagesScreen(),
          ],
        ),
      ),
    );
  }
}

// Temporary imports for the tool to work


