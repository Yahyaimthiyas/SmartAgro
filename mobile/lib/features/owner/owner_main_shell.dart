import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/colors.dart';
import '../../core/services/localization_service.dart';
import 'dashboard/owner_dashboard_screen.dart';
import 'orders/owner_orders_screen.dart';
import 'stock/owner_stock_screen.dart';
import 'farmers/owner_farmers_screen.dart';
import 'feedback/owner_feedback_list_screen.dart';
import 'package:provider/provider.dart';
import '../auth/providers/auth_provider.dart' as app_auth;

class OwnerMainShell extends StatefulWidget {
  const OwnerMainShell({super.key});

  @override
  State<OwnerMainShell> createState() => _OwnerMainShellState();
}

class _OwnerMainShellState extends State<OwnerMainShell> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = const [
      OwnerDashboardScreen(),
      OwnerOrdersScreen(),
      OwnerStockScreen(),
      OwnerFarmersScreen(),
      OwnerFeedbackListScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);

    if (user == null) {
      if (authProvider.isLoggedIn) {
        // If the provider says we are logged in but Firebase isn't ready, wait a bit
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/login');
      });
      return const Scaffold();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: AppColors.surface,
        elevation: 10,
        indicatorColor: const Color(0xFFE0F2FE),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard_rounded, color: Color(0xFF0EA5E9)),
            label: LocalizationService.tr('owner_nav_dashboard'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long_rounded, color: Color(0xFF0EA5E9)),
            label: LocalizationService.tr('owner_nav_orders'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.inventory_2_outlined),
            selectedIcon: const Icon(Icons.inventory_2_rounded, color: Color(0xFF0EA5E9)),
            label: LocalizationService.tr('owner_nav_stock'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.groups_outlined),
            selectedIcon: const Icon(Icons.groups_rounded, color: Color(0xFF0EA5E9)),
            label: LocalizationService.tr('owner_nav_farmers'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.rate_review_outlined),
            selectedIcon: const Icon(Icons.rate_review_rounded, color: Color(0xFF0EA5E9)),
            label: LocalizationService.isTamil ? 'கருத்துக்கள்' : 'Feedbacks',
          ),
        ],
      ),
    );
  }
}

