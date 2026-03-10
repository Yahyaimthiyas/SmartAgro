import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';

class OwnerSettingsScreen extends StatefulWidget {
  const OwnerSettingsScreen({super.key});

  @override
  State<OwnerSettingsScreen> createState() => _OwnerSettingsScreenState();
}

class _OwnerSettingsScreenState extends State<OwnerSettingsScreen> {
  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();
  bool _biometricsEnabled = false;
  bool _pinEnabled = true; // [NEW] Track PIN security state

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final bio = await _storage.read(key: 'biometrics_enabled');
    final pin = await _storage.read(key: 'pin_enabled'); // [NEW] Read pin state
    
    setState(() {
      _biometricsEnabled = bio == 'true';
      _pinEnabled = pin == null || pin == 'true'; // Default to true if not set
    });
  }

  Future<void> _toggleBiometrics(bool value) async {
    // 1. Check hardware support
    final canCheck = await _localAuth.canCheckBiometrics;
    if (!canCheck) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocalizationService.tr('settings_bio_unavailable'))),
      );
      return;
    }

    // 2. Verify Identity
    try {
      final didAuth = await _localAuth.authenticate(
        localizedReason: value ? 'Verify to enable biometrics' : 'Verify to disable biometrics',
        options: const AuthenticationOptions(stickyAuth: true),
      );

      if (didAuth) {
        await _storage.write(key: 'biometrics_enabled', value: value.toString());
        setState(() {
          _biometricsEnabled = value;
        });
      }
    } catch (e) {
      print("Auth error: $e");
    }
  }

  // [NEW] Toggle PIN Security
  Future<void> _togglePin(bool value) async {
    if (value) {
      // User is enabling PIN security
      await _storage.write(key: 'pin_enabled', value: 'true');
      await _storage.delete(key: 'owner_pin'); // Force setup of new PIN
      
      setState(() => _pinEnabled = true);
      
      if (!mounted) return;
      // Navigate to security gate to set up the new PIN immediately
      Navigator.pushNamedAndRemoveUntil(context, '/owner-secure', (route) => false);
    } else {
      // User is disabling PIN security
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(LocalizationService.tr('settings_pin_disable_dialog_title')),
          content: Text(LocalizationService.tr('settings_pin_disable_dialog_msg')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: Text(LocalizationService.tr('btn_cancel'))
            ),
            TextButton(
              onPressed: () async {
                await _storage.write(key: 'pin_enabled', value: 'false');
                await _storage.delete(key: 'owner_pin'); // Delete existing pin mapping
                
                setState(() => _pinEnabled = false);
                Navigator.pop(context);
              }, 
              child: Text(LocalizationService.tr('btn_confirm'), style: const TextStyle(color: Colors.red))
            ),
          ],
        ),
      );
    }
  }

  Future<void> _resetPin() async {
    // To reset PIN, we just clear it and navigate back to security gate
    // which will detect no PIN and trigger setup mode.
    await _storage.delete(key: 'owner_pin');
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/owner-secure', (route) => false);
  }

  Future<void> _logout() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/language', (route) => false);
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          "Select Language",
          style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("English"),
              onTap: () {
                LocalizationService.changeLocale('en');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("தமிழ் (Tamil)"),
              onTap: () {
                LocalizationService.changeLocale('ta');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          LocalizationService.tr('settings_title'),
          style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionHeader(title: LocalizationService.tr('settings_access_control')),
          const SizedBox(height: 12),
          
          // [NEW] PIN Enable/Disable Tile
          _SettingsTile(
            icon: Icons.security,
            title: LocalizationService.tr('settings_pin_toggle_title'),
            subtitle: LocalizationService.tr('settings_pin_toggle_subtitle'),
            trailing: Switch(
              value: _pinEnabled,
              onChanged: _togglePin,
              activeColor: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),

          if (_pinEnabled) ...[
            _SettingsTile(
              icon: Icons.fingerprint,
              title: LocalizationService.tr('settings_biometric_title'),
              subtitle: LocalizationService.tr('settings_biometric_subtitle'),
              trailing: Switch(
                value: _biometricsEnabled,
                onChanged: _toggleBiometrics,
                activeColor: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.lock_reset,
              title: LocalizationService.tr('settings_reset_pin_title'),
              subtitle: LocalizationService.tr('settings_reset_pin_subtitle'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(LocalizationService.tr('settings_reset_pin_dialog_title')),
                    content: Text(LocalizationService.tr('settings_reset_pin_dialog_msg')),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: Text(LocalizationService.tr('btn_cancel'))),
                      TextButton(onPressed: () {
                        Navigator.pop(context);
                        _resetPin();
                      }, child: Text(LocalizationService.tr('btn_reset'), style: const TextStyle(color: Colors.red))),
                    ],
                  ),
                );
              },
            ),
          ],
          
          const SizedBox(height: 32),
          _SectionHeader(title: LocalizationService.tr('settings_app_settings')),
          const SizedBox(height: 12),
          ValueListenableBuilder<Locale>(
            valueListenable: LocalizationService.localeNotifier,
            builder: (context, locale, child) {
              return _SettingsTile(
                icon: Icons.language,
                title: LocalizationService.tr('settings_language'),
                subtitle: locale.languageCode == 'ta' ? "தமிழ் (Tamil)" : "English",
                onTap: () {
                  _showLanguageDialog(context);
                },
              );
            },
          ),

          const SizedBox(height: 32),
          _SectionHeader(title: LocalizationService.tr('settings_account')),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.logout,
            title: LocalizationService.tr('settings_logout'),
            subtitle: LocalizationService.tr('settings_logout_subtitle'),
            textColor: Colors.red,
            iconColor: Colors.red,
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? textColor;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.primary).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor ?? AppColors.primary, size: 24),
        ),
        title: Text(
          title,
          style: GoogleFonts.notoSansTamil(
            fontWeight: FontWeight.w600,
            color: textColor ?? AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
