import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/main_navigation.dart';
import 'screens/clients/web_client_portal_screen.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/client_service.dart';
import 'providers/language_provider.dart';
import 'providers/navigation_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/fcm_admin_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

    if (kIsWeb) {
      try {
        await FirebaseFirestore.instance.clearPersistence().catchError((e) {
          if (kDebugMode) debugPrint('PCM App: Firestore Web clearPersistence notice: $e');
        });
      } catch (e) {
        if (kDebugMode) debugPrint('PCM App: Firestore Web clearPersistence notice: $e');
      }

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

      try {
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
        if (kDebugMode) debugPrint('FCM: Background message handler registered successfully');
      } catch (e) {
        if (kDebugMode) debugPrint('FCM: Background handler registration notice: $e');
      }
    }
    if (kDebugMode) debugPrint('PCM App: Firebase Ready (Connected to premier-ceiling-master-381b0)');
  } catch (e) {
    if (kDebugMode) debugPrint('PCM App: Firebase Init Notice: $e');
  }

  try {
    final prefs = await SharedPreferences.getInstance().timeout(
      const Duration(seconds: 3),
      onTimeout: () => SharedPreferences.getInstance(),
    );
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;

    final savedUiUnit = prefs.getString('ui_unitNumber');
    if (savedUiUnit != null && (savedUiUnit.toUpperCase().contains('UNIT') || !savedUiUnit.startsWith('# PCM-'))) {
      final clean = ClientService.normalizeUnitNumber(savedUiUnit);
      await prefs.setString('ui_unitNumber', clean);
    }

    final savedUiLocation = prefs.getString('ui_location');
    if (savedUiLocation != null &&
        (savedUiLocation.toLowerCase().contains('thrissur') ||
         savedUiLocation.contains(RegExp(r'\(\s*-?\d+')))) {
      await prefs.setString('ui_location', 'Arichalil Tea Shop, Eranjanikunnu');
    }

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
