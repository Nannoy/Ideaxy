import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7C4DFF),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF0E0E12),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
    return base.copyWith(
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF18181F),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF2A2A35)),
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF14141A),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
      listTileTheme: const ListTileThemeData(iconColor: Colors.white70),
    );
  }
}

