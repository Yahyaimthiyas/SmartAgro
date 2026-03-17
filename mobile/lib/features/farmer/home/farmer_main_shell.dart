import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/localization_service.dart';
import 'farmer_home_screen.dart';
import '../products/farmer_categories_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../profile/farmer_profile_screen.dart';
import '../profile/farmer_profile_setup_screen.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../auth/providers/auth_provider.dart' as app_auth;

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
      FarmerProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);

    if (user == null) {
      if (authProvider.isLoggedIn) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/login');
      });
      return const Scaffold();
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text("Connection Error: ${snapshot.error}")),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final isBasicComplete = userData?['isProfileBasicComplete'] == true;
        
        if (!isBasicComplete && userData?['name'] == null) {
          return const FarmerProfileSetupScreen(mode: ProfileSetupMode.basic);
        }

        return Scaffold(
          body: _pages[_currentIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) => setState(() => _currentIndex = index),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home_rounded),
                label: LocalizationService.tr('nav_home'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.shopping_bag_outlined),
                selectedIcon: const Icon(Icons.shopping_bag_rounded),
                label: LocalizationService.tr('nav_shops'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline_rounded),
                selectedIcon: const Icon(Icons.person_rounded),
                label: LocalizationService.tr('nav_profile'),
              ),
            ],
          ),
        );
      }
    );
  }
}
