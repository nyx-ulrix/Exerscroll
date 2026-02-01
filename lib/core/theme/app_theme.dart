import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color _primary = Color(0xFF4CAF50);
  static const Color _primaryDark = Color(0xFF388E3C);
  static const Color _surface = Color(0xFF121212);
  static const Color _surfaceVariant = Color(0xFF1E1E1E);
  static const Color _onSurface = Color(0xFFE1E1E1);
  static const Color _onSurfaceVariant = Color(0xFFB0B0B0);
  static const Color _accent = Color(0xFF81C784);

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: _primary,
        primaryContainer: _primaryDark,
        secondary: _accent,
        surface: _surface,
        surfaceContainerHighest: _surfaceVariant,
        onSurface: _onSurface,
        onSurfaceVariant: _onSurfaceVariant,
      ),
      scaffoldBackgroundColor: _surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: _surface,
        foregroundColor: _onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: _surfaceVariant,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceVariant,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _surfaceVariant,
        selectedItemColor: _primary,
        unselectedItemColor: _onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
