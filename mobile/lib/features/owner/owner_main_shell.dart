import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/colors.dart';
import '../../core/services/localization_service.dart';
import 'dashboard/owner_dashboard_screen.dart';
import 'orders/owner_orders_screen.dart';
import 'stock/owner_stock_screen.dart';
import 'farmers/owner_farmers_screen.dart';

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
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      });
      return const Scaffold();
    }

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.white,
          indicatorColor: AppColors.primary.withOpacity(0.15),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: const Icon(Icons.dashboard, color: AppColors.primary),
              label: LocalizationService.tr('owner_nav_dashboard'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.receipt_long_outlined),
              selectedIcon: const Icon(Icons.receipt_long, color: AppColors.primary),
              label: LocalizationService.tr('owner_nav_orders'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.inventory_2_outlined),
              selectedIcon: const Icon(Icons.inventory_2, color: AppColors.primary),
              label: LocalizationService.tr('owner_nav_stock'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.groups_outlined),
              selectedIcon: const Icon(Icons.groups, color: AppColors.primary),
              label: LocalizationService.tr('owner_nav_farmers'),
            ),
          ],
        ),
      ),
    );
  }
}

