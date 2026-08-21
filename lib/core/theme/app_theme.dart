import 'package:flutter/material.dart';

class AppTheme {
  // SlateLight & Brand Colors from Native Android Compose Theme
  static const Color slateLight = Color(0xFFF6F7F5);
  static const Color primaryDark = Color(0xFF243B55);
  static const Color textPrimary = Color(0xFF1E1E1B);
  static const Color textSecondary = Color(0xFF6D7875);
  static const Color accentBlue = Color(0xFF2E7BB4);
  static const Color accentLightBlue = Color(0xFFE8F2FA);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: slateLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryDark,
        surface: slateLight,
        primary: primaryDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }
}
