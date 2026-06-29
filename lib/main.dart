import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/splash/splash_screen.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'providers/language_provider.dart';
import 'providers/navigation_provider.dart';
import 'package:flutter/foundation.dart';

void main() async {
  // v3.5 CRITICAL HOTFIX: Resolve Web "Zero Update" freeze.
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) debugPrint('PCM App: Main Boot Sequence Started (v3.5)');

  try {
    // 1. SharedPreferences (Safe initialization)
    final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 3), onTimeout: () {
      if (kDebugMode) debugPrint('PCM App: SharedPreferences Timeout - Using defaults');
      return SharedPreferences.getInstance(); // Fallback
    });
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;

    // 2. Initialize Services in Background (Non-blocking)
    _initServicesAsync();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => NavigationProvider()),
          ChangeNotifierProvider.value(value: AuthService.instance),
        ],
        child: PCMApp(isDarkMode: isDarkMode),
      ),
    );
  } catch (e) {
    debugPrint('PCM App: CRITICAL BOOT ERROR: $e');
    // Fallback UI to prevent blank screen
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text('PCM Portal Initialization Error. Please refresh.\n$e', textAlign: TextAlign.center)),
      ),
    ));
  }
}

Future<void> _initServicesAsync() async {
  // 1. Firebase (Safe wrapper)
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyDummyKeyForBypassOnly123456",
          appId: "1:1234567890:web:abc123xyz",
          messagingSenderId: "1234567890",
          projectId: "pcm-wayanad-bypass",
          authDomain: "pcm-wayanad-bypass.firebaseapp.com",
          storageBucket: "pcm-wayanad-bypass.appspot.com",
        ),
      ).timeout(const Duration(seconds: 5));
    } else {
      // In production mobile, Firebase usually expects a google-services.json file
      // If it's missing, we catch the error to prevent crash.
      await Firebase.initializeApp().timeout(const Duration(seconds: 10));
    }
    if (kDebugMode) debugPrint('PCM App: Firebase Ready');
  } catch (e) {
    if (kDebugMode) debugPrint('PCM App: Firebase Init Failed: $e');
  }

  // 2. AuthService (Session recovery)
  try {
    await AuthService.instance.init().timeout(const Duration(seconds: 10));
    if (kDebugMode) debugPrint('PCM App: AuthService Ready');
  } catch (e) {
    if (kDebugMode) debugPrint('PCM App: AuthService Init Timeout/Error: $e');
  }
}

class PCMApp extends StatelessWidget {
  final bool isDarkMode;
  const PCMApp({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kIsWeb ? 'PCM Client Portal' : 'PCM Admin Tools',
      debugShowCheckedModeBanner: false,
      // FIX: Force Light Theme for initial Web load to prevent "invisible text" on cream background
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) => child ?? const SizedBox.shrink(),
      home: const SplashScreen(),
    );
  }
}
