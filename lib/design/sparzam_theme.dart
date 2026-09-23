import 'package:flutter/material.dart';

/// Shared visual foundation for the approved Sparzam design.
abstract final class SparzamTheme {
  static const sage = Color(0xFF477B59);
  static const deepGreen = Color(0xFF244F37);
  static const canvas = Color(0xFFF8F8F3);
  static const warmWhite = Color(0xFFFFFEFA);
  static const muted = Color(0xFF718075);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: sage,
      brightness: Brightness.light,
      surface: warmWhite,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      appBarTheme: const AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: deepGreen,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        color: warmWhite,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(22)),
          side: BorderSide(color: Color(0xFFE8ECE5)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: warmWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE3E9E0)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: warmWhite,
        indicatorColor: const Color(0xFFDDEBDF),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
