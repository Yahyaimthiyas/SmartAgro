import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/localization_service.dart';
import 'farmer_home_screen.dart';
import '../products/farmer_categories_screen.dart';
import '../advisory/farmer_advisory_hub_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../profile/farmer_profile_screen.dart';
import '../profile/farmer_profile_setup_screen.dart';

class FarmerMainShell extends StatefulWidget {
  const FarmerMainShell({super.key});

  @override
  State<FarmerMainShell> createState() => _FarmerMainShellState();
}

class _FarmerMainShellState extends State<FarmerMainShell> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = const [
      FarmerHomeScreen(),
      FarmerCategoriesScreen(),
      FarmerAdvisoryHubScreen(),
      FarmerProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Ensure a user is logged in; if not, send them back to login.
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Using addPostFrameCallback to avoid calling Navigator during build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      });
      return const Scaffold();
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
           return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final isBasicComplete = userData?['isProfileBasicComplete'] == true;
        // Also consider legacy users who might have a name but no flag. 
        // Simple check: if name is present, assume basic is done.
        final hasName = userData?['name'] != null && (userData!['name'] as String).isNotEmpty;

        if (!isBasicComplete && !hasName) {
           return const FarmerProfileSetupScreen(mode: ProfileSetupMode.basic);
        }

        return Scaffold(
          body: _pages[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home_outlined),
                label: LocalizationService.tr('nav_home'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.storefront_outlined),
                label: LocalizationService.tr('nav_shops'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.insights_outlined),
                label: LocalizationService.tr('nav_advisory'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline),
                label: LocalizationService.tr('nav_profile'),
              ),
            ],
          ),
        );
      }
    );
  }
}
