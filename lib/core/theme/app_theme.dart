import 'package:flutter/material.dart';

class AppTheme {
  static const Color _black = Color(0xFF0A0A0A);
  static const Color _gray900 = Color(0xFF141414);
  static const Color _gray700 = Color(0xFF2B2B2B);
  static const Color _gray400 = Color(0xFF9A9A9A);
  static const Color _white = Color(0xFFF2F2F2);

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: _white,
      onPrimary: _black,
      secondary: _gray400,
      onSecondary: _black,
      error: Color(0xFFB00020),
      onError: _white,
      surface: _gray900,
      onSurface: _white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _black,
      fontFamily: 'monospace',
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: _black,
        foregroundColor: _white,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'monospace',
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: _white,
        ),
      ),
      cardTheme: CardThemeData(
        color: _gray900,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: _gray700, width: 2),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _white,
        foregroundColor: _black,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: _gray700, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _gray900,
        contentTextStyle: const TextStyle(
          fontFamily: 'monospace',
          color: _white,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: _gray700, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _white,
          foregroundColor: _black,
          textStyle: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _white,
          textStyle: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          side: const BorderSide(color: _gray400, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: _white),
        bodyMedium: TextStyle(color: _white),
        labelLarge: TextStyle(color: _gray400),
        labelMedium: TextStyle(color: _gray400),
        titleLarge: TextStyle(fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontWeight: FontWeight.w600),
      ),
      dividerColor: _gray700,
    );
  }
}
