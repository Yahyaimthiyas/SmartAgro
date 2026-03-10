import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pinput/pinput.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';

class OwnerSecurityGateScreen extends StatefulWidget {
  const OwnerSecurityGateScreen({super.key});

  @override
  State<OwnerSecurityGateScreen> createState() => _OwnerSecurityGateScreenState();
}

class _OwnerSecurityGateScreenState extends State<OwnerSecurityGateScreen> with SingleTickerProviderStateMixin {
  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();
  final _pinController = TextEditingController();
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  bool _isPinSet = false;
  bool _isLoading = true;
  bool _isSetupMode = false;
  bool _biometricsEnabled = false;
  bool _showPinPad = true; // Default to showing PIN if Biometrics are off
  String? _tempPin; 

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _checkSecurityStatus();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _checkSecurityStatus() async {
    final pinEnabled = await _storage.read(key: 'pin_enabled');
    
    // [NEW] Bypass check: if owner explicitly disabled PIN, go straight to dashboard
    if (pinEnabled == 'false') {
      if (mounted) {
         _navigateToDashboard();
      }
      return;
    }

    final pin = await _storage.read(key: 'owner_pin');
    final bioEnabled = await _storage.read(key: 'biometrics_enabled') == 'true';
    
    setState(() {
      _isPinSet = pin != null;
      _isLoading = false;
      _isSetupMode = !_isPinSet; 
      _biometricsEnabled = bioEnabled;
      
      // If setup mode, always show PIN. 
      // If normal mode, show PIN only if bio is disabled.
      _showPinPad = _isSetupMode || !bioEnabled; 
    });

    if (_isPinSet && bioEnabled) {
      // Auto-trigger prompt
      Future.delayed(const Duration(milliseconds: 300), _authenticateBiometrics);
    }
  }

  Future<void> _authenticateBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (canCheck) {
        final didAuth = await _localAuth.authenticate(
          localizedReason: LocalizationService.tr('gate_verify_reason_scan'),
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
            useErrorDialogs: true,
          ),
        );
        if (didAuth) {
          _navigateToDashboard();
        }
      }
    } catch (e) {
      print("Biometric error: $e");
    }
  }

  void _handlePinSubmit(String pin) async {
    if (_isSetupMode) {
      if (_tempPin == null) {
        setState(() {
          _tempPin = pin;
          _pinController.clear();
        });
      } else {
        if (pin == _tempPin) {
          await _storage.write(key: 'owner_pin', value: pin);
          // Auto-enable biometrics if available, or ask
          _showBiometricSetupDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                LocalizationService.tr('gate_error_pin_mismatch'),
                style: GoogleFonts.notoSansTamil(),
              ),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _tempPin = null;
            _pinController.clear();
          });
        }
      }
    } else {
      final storedPin = await _storage.read(key: 'owner_pin');
      if (pin == storedPin) {
        _navigateToDashboard();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationService.tr('gate_error_incorrect_pin'),
              style: GoogleFonts.notoSansTamil(),
            ),
            backgroundColor: Colors.red,
          ),
        );
        _pinController.clear();
      }
    }
  }

  void _showBiometricSetupDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          LocalizationService.tr('gate_dialog_enable_bio_title'),
          style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold),
        ),
        content: Text(
          LocalizationService.tr('gate_dialog_enable_bio_msg'),
          style: GoogleFonts.notoSansTamil(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _storage.write(key: 'biometrics_enabled', value: 'false');
              Navigator.pop(context);
              _navigateToDashboard();
            },
            child: Text(LocalizationService.tr('gate_btn_not_now')),
          ),
          ElevatedButton(
            onPressed: () async {
              await _storage.write(key: 'biometrics_enabled', value: 'true');
              Navigator.pop(context);
              _navigateToDashboard();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(LocalizationService.tr('gate_btn_enable')),
          ),
        ],
      ),
    );
  }

  void _navigateToDashboard() {
    Navigator.pushReplacementNamed(context, '/owner-dashboard');
  }

  @override
  Widget build(BuildContext context) {
    // Determine title/subtitle based on state
    String title = LocalizationService.tr('gate_title_verify'); 
    String subtitle = LocalizationService.tr('gate_subtitle_verify');

    if (_isSetupMode) {
      title = _tempPin == null ? LocalizationService.tr('gate_title_create') : LocalizationService.tr('gate_title_confirm');
      subtitle = LocalizationService.tr('gate_subtitle_create');
    } else if (_isPinSet) {
       // Normal login mode
       if (!_showPinPad) {
          title = LocalizationService.tr('gate_title_welcome');
          subtitle = LocalizationService.tr('gate_subtitle_bio');
       } else {
          subtitle = LocalizationService.tr('gate_subtitle_pin');
       }
    }

    final defaultPinTheme = PinTheme(
      width: 60,
      height: 60,
      textStyle: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );

    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Off-white background
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 48),
                  // Lock Icon Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                       (!_isSetupMode && !_showPinPad) ? Icons.fingerprint : Icons.shield_outlined, 
                       size: 48, 
                       color: AppColors.primary
                    ),
                  ),
                  const SizedBox(height: 32),
                
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansTamil(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansTamil(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),
                
                  // LOGIC BRANCHING
                  
                  // 1. SETUP MODE (Always show PIN pad)
                  if (_isSetupMode) ...[
                     Pinput(
                      length: 4,
                      controller: _pinController,
                      obscureText: true,
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: defaultPinTheme.copyDecorationWith(
                        border: Border.all(color: AppColors.primary, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      onCompleted: _handlePinSubmit,
                    ),
                  ]
                  
                  // 2. LOGGED IN MODE - FINGERPRINT VIEW
                  else if (!_showPinPad) ...[
                     GestureDetector(
                        onTap: _authenticateBiometrics,
                        child: ScaleTransition(
                          scale: _pulseAnimation,
                          child: Container(
                            height: 120, 
                            width: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.2),
                                  blurRadius: 30, 
                                  spreadRadius: 5,
                                ),
                              ],
                              border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 2),
                            ),
                            child: const Icon(
                              Icons.fingerprint, 
                              size: 64, 
                              color: AppColors.primary
                            ),
                          ),
                        ),
                     ),
                     const SizedBox(height: 40),
                     TextButton(
                        onPressed: () {
                           setState(() {
                              _showPinPad = true;
                           });
                        },
                        child: Text(
                           LocalizationService.tr('gate_btn_use_pin'),
                           style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                           ),
                        ),
                     ),
                  ]

                  // 3. LOGGED IN MODE - PIN START
                  else ...[
                     Pinput(
                      length: 4,
                      controller: _pinController,
                      obscureText: true,
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: defaultPinTheme.copyDecorationWith(
                        border: Border.all(color: AppColors.primary, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      onCompleted: _handlePinSubmit,
                    ),
                    
                    // Show "Use Biometrics" if available
                    if (_biometricsEnabled) ...[
                       const SizedBox(height: 40),
                       TextButton.icon(
                          onPressed: () {
                             setState(() {
                                _showPinPad = false;
                             });
                             _authenticateBiometrics();
                          },
                          icon: const Icon(Icons.fingerprint),
                          label: Text(
                             LocalizationService.tr('gate_btn_use_bio'),
                             style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                             ),
                          ),
                          style: TextButton.styleFrom(
                             foregroundColor: AppColors.textSecondary,
                          ),
                       ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
