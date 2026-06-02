import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light => _theme(
        brightness: Brightness.light,
        seed: const Color(0xFF0F766E),
      );

  static ThemeData get dark => _theme(
        brightness: Brightness.dark,
        seed: const Color(0xFF14B8A6),
      );

  static ThemeData _theme({
    required Brightness brightness,
    required Color seed,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
