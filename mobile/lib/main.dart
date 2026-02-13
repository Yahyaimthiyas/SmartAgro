import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'core/theme/theme.dart';
import 'core/services/localization_service.dart';
import 'core/services/notification_service.dart';
import 'features/auth/providers/auth_provider.dart' as app_auth;
import 'features/farmer/cart/cart_provider.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/language_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/otp_verify_screen.dart';
import 'features/farmer/home/farmer_main_shell.dart';
import 'features/owner/owner_main_shell.dart';
import 'features/owner/security/owner_security_gate_screen.dart';
import 'features/owner/settings/owner_settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await LocalizationService.init();
  await NotificationService.init();
  
  // Seeders moved to AuthProvider to ensure authorized access
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => app_auth.AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: ValueListenableBuilder<Locale>(
        valueListenable: LocalizationService.localeNotifier,
        builder: (context, locale, child) {
          return MaterialApp(
            title: 'AgriShop',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            locale: locale,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('ta')],
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/language': (context) => const LanguageScreen(),
              '/login': (context) => const LoginScreen(),
              '/otp': (context) => const OtpVerifyScreen(),
              '/home': (context) => const FarmerMainShell(),
              '/owner-secure': (context) => const OwnerSecurityGateScreen(),
              '/owner-dashboard': (context) => const OwnerMainShell(),
              '/owner-settings': (context) => const OwnerSettingsScreen(),
            },
          );
        },
      ),
    );
  }
}

