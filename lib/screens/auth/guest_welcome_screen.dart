import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'login_screen.dart';
import 'registration_screen.dart';

class GuestWelcomeScreen extends StatelessWidget {
  const GuestWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent, // Ensures no default background peeks through edges
      body: Container(
        // Full-Screen Responsive Layout
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          // Traditional Theme Background
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
                ? [AppColors.darkBackground, const Color(0xFF1A1A1A)] 
                : [const Color(0xFFFFF9E6), const Color(0xFFFFF3CD)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const SizedBox(height: 20),
                        
                        // Branding & Logo
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? Colors.white10 : Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: isDark ? Colors.black54 : const Color(0xFFE6D599).withValues(alpha: 0.6),
                                blurRadius: 24,
                                spreadRadius: 4,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: ClipOval(
                            child: Hero(
                              tag: 'app_logo',
                              child: Image.asset(
                                'assets/images/app_logo.png', // Uses the requested logo
                                height: 160,
                                width: 160,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => 
                                    const Icon(Icons.favorite, size: 80, color: AppColors.premiumGold),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 48),
                        
                        // Welcome Content Tagline
                        Column(
                          children: [
                            Text(
                              'Kurichiyar Matrimony',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                color: isDark ? Colors.white : const Color(0xFF8B4513), // Traditional Brown/Amber accent
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Where Traditions Meet True Love',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                fontStyle: FontStyle.italic,
                                color: isDark ? Colors.white70 : const Color(0xFF5D4037),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 64),
                        
                        // Action Buttons
                        Column(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD4AF37), // Premium Gold matching the theme
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 60),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                elevation: 8,
                                shadowColor: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                              ),
                              child: const Text(
                                'LOGIN',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                              ),
                            ),
                            const SizedBox(height: 20),
                            OutlinedButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistrationScreen()));
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isDark ? Colors.white : const Color(0xFF8B4513),
                                minimumSize: const Size(double.infinity, 60),
                                side: BorderSide(
                                  color: isDark ? Colors.white38 : const Color(0xFF8B4513),
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                              child: const Text(
                                'REGISTER',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
