import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // v3.1 PREMIUM LUXURY THEME
  static const Color background = Color(0xFFFDFBF7); // Premium soft ivory/cream — moon-white

  static const Color darkBackground = Color(0xFF0D0D11); // Luxury Dark Mode
  static const Color border = Color(0xFF4A4A4A);       // Neutral Charcoal (Replaced Saddle Brown)
  static const Color premiumGold = Color(0xFFD4AF37);  // Luxury Gold
  static const Color primaryButton = Color(0xFF556B2F); 
  static const Color resultGreen = Color(0xFF006400);   
  static const Color labelColor = Color(0xFF1C1C1E);    
  static const Color pureWhite = Colors.white;
  static const Color subtleGrey = Color(0xFFE0E0E0);
  static const Color alertRed = Color(0xFFB71C1C);
}

class AppStyles {
  static BoxDecoration glassmorphicDecoration({
    double blur = 20,
    double opacity = 0.05,
    double borderRadius = 20,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.0),
    );
  }

  static BoxDecoration neumorphicDecoration({
    Color color = AppColors.pureWhite,
    bool hasThickBorder = false,
    double borderRadius = 12,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: hasThickBorder ? AppColors.border : AppColors.border.withValues(alpha: 0.1),
        width: hasThickBorder ? 1.5 : 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          offset: const Offset(2, 2),
          blurRadius: 4,
        ),
      ],
    );
  }

  static InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label.toUpperCase(),
      labelStyle: const TextStyle(
        color: Colors.black,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.0,
      ),
      hintStyle: const TextStyle(color: Colors.black54),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.4), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border, width: 2.5),
      ),
    );
  }

  static const TextStyle resultStyle = TextStyle(
    color: AppColors.resultGreen,
    fontWeight: FontWeight.w900,
    fontSize: 22,
    letterSpacing: 0.5,
  );

  static const TextStyle boldLabel = TextStyle(
    color: AppColors.labelColor,
    fontWeight: FontWeight.w900,
    fontSize: 14,
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: GoogleFonts.notoSansMalayalam().fontFamily,
      primaryColor: AppColors.primaryButton,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.border,
        primary: AppColors.primaryButton,
        onPrimary: AppColors.pureWhite,
        surface: AppColors.background,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: AppColors.labelColor, fontWeight: FontWeight.w900),
        bodyLarge: TextStyle(color: Colors.black),
        bodyMedium: TextStyle(color: Colors.black),
        titleMedium: TextStyle(color: Colors.black),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.inter().fontFamily,
      primaryColor: AppColors.premiumGold,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.premiumGold,
        secondary: Colors.blueAccent,
        surface: Color(0xFF1C1C1E),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        bodyLarge: TextStyle(color: Colors.white70),
        bodyMedium: TextStyle(color: Colors.white70),
      ),
    );
  }
}
