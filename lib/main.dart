import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/main_navigation.dart';
import 'screens/clients/web_client_portal_screen.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/client_service.dart';
import 'services/safe_preferences.dart';
import 'providers/language_provider.dart';
import 'providers/navigation_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  if (kDebugMode) debugPrint('PCM App: Main Boot Sequence Started (v3.5)');

  // 1. Initialize Firebase and await it safely before starting the app
  try {
    if (Firebase.apps.isEmpty) {
      if (kIsWeb) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: "AIzaSyCBAxjvRnOSA6r4UPs2VK7P3lWd5beK1nQ",
            appId: "1:949356430964:web:2da1263f2f419f77763321",
            messagingSenderId: "949356430964",
            projectId: "premier-ceiling-master-381b0",
            authDomain: "premier-ceiling-master-381b0.firebaseapp.com",
            storageBucket: "premier-ceiling-master-381b0.firebasestorage.app",
          ),
        );
      } else {
        try {
          await Firebase.initializeApp();
        } catch (_) {
          await Firebase.initializeApp(
            options: const FirebaseOptions(
              apiKey: "AIzaSyCBAxjvRnOSA6r4UPs2VK7P3lWd5beK1nQ",
              appId: "1:949356430964:web:2da1263f2f419f77763321",
              messagingSenderId: "949356430964",
              projectId: "premier-ceiling-master-381b0",
              authDomain: "premier-ceiling-master-381b0.firebaseapp.com",
              storageBucket: "premier-ceiling-master-381b0.firebasestorage.app",
            ),
          );
        }
      }
    }

    // Configure platform-appropriate Firestore settings and handle persistence exceptions gracefully
    if (kIsWeb) {
      // 1. Programmatically clear any corrupt IndexedDB schema/target store causing b815 / ca9 assertion errors
      try {
        await FirebaseFirestore.instance.clearPersistence().catchError((e) {
          if (kDebugMode) debugPrint('PCM App: Firestore Web clearPersistence notice: $e');
        });
      } catch (e) {
        if (kDebugMode) debugPrint('PCM App: Firestore Web clearPersistence notice: $e');
      }

      // 2. Safely configure Web memory mode (bypassing local IndexedDB cache conflicts)
      try {
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: false,
        );
        if (kDebugMode) debugPrint('PCM App: Firestore Web memory mode enabled (persistenceDisabled=true)');
      } catch (e) {
        if (kDebugMode) debugPrint('PCM App: Firestore Web settings notice: $e');
      }
    } else {
      try {
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
        if (kDebugMode) debugPrint('PCM App: Firestore Mobile persistence enabled (CACHE_SIZE_UNLIMITED)');
      } catch (e) {
        if (kDebugMode) debugPrint('PCM App: Firestore Mobile persistence notice: $e');
        try {
          FirebaseFirestore.instance.settings = const Settings(
            persistenceEnabled: false,
          );
        } catch (_) {}
      }
    }

    if (!kIsWeb) {
      try {
        await FirebaseFirestore.instance.enableNetwork().catchError((e) {
          if (kDebugMode) debugPrint('PCM App: Firestore enableNetwork notice: $e');
        });
        if (kDebugMode) debugPrint('Firestore Network Enabled Successfully!');
      } catch (e) {
        if (kDebugMode) debugPrint('Failed to enable Firestore network: $e');
      }
    }
    if (kDebugMode) debugPrint('PCM App: Firebase Ready (Connected to premier-ceiling-master-381b0)');
  } catch (e) {
    if (kDebugMode) debugPrint('PCM App: Firebase Init Notice: $e');
  }

  try {
    // 2. SharedPreferences (Safe initialization)
    final prefs = await SafePreferences.getInstance().timeout(
      const Duration(seconds: 3),
      onTimeout: () => SafePreferences.getInstance(),
    );
    final isDarkMode = prefs?.getBool('isDarkMode') ?? false;

    if (prefs != null) {
      // Migrate any legacy 'UNIT' prefix in cached project ID to '# PCM-YYYYMMDD-HHmm'
      final savedUiUnit = prefs.getString('ui_unitNumber');
      if (savedUiUnit != null && (savedUiUnit.toUpperCase().contains('UNIT') || !savedUiUnit.startsWith('# PCM-'))) {
        final clean = ClientService.normalizeUnitNumber(savedUiUnit);
        await prefs.setString('ui_unitNumber', clean);
      }

      // Migrate any cached 'Thrissur' or raw GPS coordinates in cached location
      final savedUiLocation = prefs.getString('ui_location');
      if (savedUiLocation != null &&
          (savedUiLocation.toLowerCase().contains('thrissur') ||
           savedUiLocation.contains(RegExp(r'\(\s*-?\d+')))) {
        await prefs.setString('ui_location', 'Arichalil Tea Shop, Eranjanikunnu');
      }
    }

    // 3. AuthService
    await AuthService.instance.init();

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
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            'PCM Portal Initialization Error. Please refresh.\n$e',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ));
  }
}

class PCMApp extends StatelessWidget {
  final bool isDarkMode;
  const PCMApp({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PCM Admin & Client Hub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) => child ?? const SizedBox.shrink(),
      // Directly launches the full PCM application UI & Site Hub for local Flutter Web & Mobile runs
      home: const RoleNavigationShell(),
      onGenerateRoute: (settings) {
        if (settings.name != null &&
            (settings.name!.contains('/portal') || settings.name!.contains('/project/'))) {
          return MaterialPageRoute(builder: (_) => const WebClientPortalScreen());
        }
        return MaterialPageRoute(builder: (_) => const RoleNavigationShell());
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(builder: (_) => const RoleNavigationShell());
      },
    );
  }
}
