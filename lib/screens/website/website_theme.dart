import 'package:flutter/material.dart';

class WebsiteTheme {
  static const Color midnightNavy = Color(0xFF0F172A);
  static const Color navyCard = Color(0xFF1E293B);
  static const Color champagneGold = Color(0xFFF59E0B);
  static const Color goldLight = Color(0xFFFBBF24);
  static const Color borderGold = Color(0xFFD97706);
  static const Color textLight = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color whatsappGreen = Color(0xFF10B981);
  static const Color white = Colors.white;

  static TextStyle goldAccent({double fontSize = 12, FontWeight weight = FontWeight.bold}) {
    return TextStyle(
      color: champagneGold,
      fontSize: fontSize,
      fontWeight: weight,
      letterSpacing: 1.0,
    );
  }

  static TextStyle headingLarge({double fontSize = 32, Color color = Colors.white}) {
    return TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.5,
    );
  }

  static TextStyle headingMedium({double fontSize = 20, Color color = Colors.white}) {
    return TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
    );
  }

  static TextStyle bodyText({double fontSize = 14, Color color = textMuted, double height = 1.5}) {
    return TextStyle(
      color: color,
      fontSize: fontSize,
      height: height,
    );
  }
}
