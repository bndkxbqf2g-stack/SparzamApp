import 'package:flutter/material.dart';

/// Farben und Oberflächen der Sparzam-Ansichten.
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
      colorScheme: scheme.copyWith(
        primary: deepGreen,
        onPrimary: Colors.white,
        secondary: sage,
        surface: warmWhite,
      ),
      scaffoldBackgroundColor: canvas,
      appBarTheme: const AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: deepGreen,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Color(0xFF202B22),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: Color(0xFF202B22),
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: Color(0xFF202B22),
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF303B31),
          fontSize: 15,
        ),
      ),
      cardTheme: const CardThemeData(
        color: warmWhite,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          side: BorderSide(color: Color(0xFFE8ECE5)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: warmWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE3E9E0)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: warmWhite,
        indicatorColor: const Color(0xFFDDEBDF),
        height: 70,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
