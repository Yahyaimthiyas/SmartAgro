import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      // Simulate splash delay
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.checkLoginStatus();

      if (!authProvider.isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/language');
        return;
      }

      final role = await authProvider.getUserRole();
      if (!mounted) return;

      if (role == 'owner') {
        Navigator.pushReplacementNamed(context, '/owner-secure');
      } else if (role == 'farmer') {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Role is null or unknown (network error or data issue)
        setState(() {
          _isLoading = false;
          _errorMessage = "Unable to verify user role. Please check your internet connection and try again.";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "An error occurred: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Elements
          Positioned(
            top: -50,
            right: -50,
            child: Opacity(
              opacity: 0.2,
              child: Icon(Icons.terrain, size: 300, color: AppColors.primaryLight),
            ),
          ),
          
          // Center Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.store_mall_directory, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 24),
                Text(
                  LocalizationService.tr('app_name'),
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  LocalizationService.tr('tagline'),
                  style: GoogleFonts.notoSansTamil(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                
                // Error / Limit Retry UI
                if (_errorMessage != null) ...[
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _checkAuth,
                    child: const Text("Retry"),
                  ),
                  TextButton(
                    onPressed: () {
                      final auth = Provider.of<AuthProvider>(context, listen: false);
                      auth.logout(); // Reset state
                      Navigator.pushReplacementNamed(context, '/language');
                    },
                    child: const Text("Logout & Reset"),
                  ),
                ],
              ],
            ),
          ),
          
          // Bottom Loading
          if (_isLoading)
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    LocalizationService.tr('loading'),
                    style: GoogleFonts.notoSansTamil(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(
                    width: 200,
                    child: LinearProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      backgroundColor: AppColors.surface,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
