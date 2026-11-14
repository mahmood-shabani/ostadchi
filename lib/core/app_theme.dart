import 'package:flutter/material.dart';

class AppTheme {
  static const navy = Color(0xFF17324D);
  static const blue = Color(0xFF1769AA);
  static const background = Color(0xFFF4F7FA);
  static const teal = Color(0xFF159A8C);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: blue,
      primary: blue,
      secondary: teal,
      surface: Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: background,
        foregroundColor: navy,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDCE4EC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDCE4EC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: blue, width: 1.5),
        ),
      ),
    );
  }
}
