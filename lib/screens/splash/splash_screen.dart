import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import '../../utils/js_helper_stub.dart'
    if (dart.library.js) '../../utils/js_helper_web.dart' as js_helper;
import '../main_navigation.dart';
import '../../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    
    // v3.2 WEB FIX: Dismiss HTML splash screen if it exists
    if (kIsWeb) {
      js_helper.removeSplashFromWeb();
    }

    // 1. Setup Premium Fade Animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInQuad),
    );

    _controller.forward();
    
    // Start initialization
    _initializeApp();

    // FAIL-SAFE: If app stuck on logo for > 5 seconds, force bypass
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        debugPrint('Splash: 5s Fail-safe triggered. Bypassing...');
        _navigateToHome();
      }
    });
  }

  Future<void> _initializeApp() async {
    // 1. Play Premium Startup Sound (Silent fail)


    // 2. Wait for logo animation
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) _navigateToHome();
  }



  void _navigateToHome() async {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;

    // Start Fade-Out before navigation
    await _controller.reverse();

    if (!mounted) return;

    // Premium Fade-In Navigation to Home
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const RoleNavigationShell(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 1000),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, 
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Branded PCM Logo
              Hero(
                tag: 'pcm_logo',
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 280,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.architecture,
                      size: 120,
                      color: AppColors.border,
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
              // Subtle Loading Indicator matching our theme
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.border),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
