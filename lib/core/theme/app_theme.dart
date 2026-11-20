import 'package:flutter/material.dart';

/// Tokyo Night Light palette.
/// Reference: https://github.com/enkia/tokyo-night-vscode-theme
class TokyoNightLight {
  TokyoNightLight._();

  // Base surfaces
  static const Color background = Color(0xFFE1E2E7);
  static const Color foreground = Color(0xFF343B58);
  static const Color surface = Color(0xFFD5D6DB);
  static const Color surfaceVariant = Color(0xFFC4C8DA);

  // Accents
  static const Color blue = Color(0xFF2E7DE9);
  static const Color cyan = Color(0xFF007197);
  static const Color green = Color(0xFF587539);
  static const Color yellow = Color(0xFF8C6C3E);
  static const Color red = Color(0xFFF52A65);
  static const Color magenta = Color(0xFF9854F1);
  static const Color orange = Color(0xFFB15C00);

  // Outline / divider
  static const Color outline = Color(0xFFA8ADBD);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: TokyoNightLight.blue,
      onPrimary: Colors.white,
      secondary: TokyoNightLight.cyan,
      onSecondary: Colors.white,
      tertiary: TokyoNightLight.magenta,
      onTertiary: Colors.white,
      error: TokyoNightLight.red,
      onError: Colors.white,
      surface: TokyoNightLight.surface,
      onSurface: TokyoNightLight.foreground,
      surfaceContainerHighest: TokyoNightLight.surfaceVariant,
      onSurfaceVariant: TokyoNightLight.foreground,
      outline: TokyoNightLight.outline,
      outlineVariant: TokyoNightLight.surfaceVariant,
      shadow: Colors.black26,
      scrim: Colors.black54,
      inverseSurface: TokyoNightLight.foreground,
      onInverseSurface: TokyoNightLight.background,
      inversePrimary: TokyoNightLight.cyan,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: TokyoNightLight.background,
      appBarTheme: AppBarTheme(
        backgroundColor: TokyoNightLight.surface,
        foregroundColor: TokyoNightLight.foreground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: TokyoNightLight.foreground,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: TokyoNightLight.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: TokyoNightLight.blue,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TokyoNightLight.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: TokyoNightLight.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: TokyoNightLight.blue, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: TokyoNightLight.foreground,
        contentTextStyle: const TextStyle(color: TokyoNightLight.background),
        behavior: SnackBarBehavior.floating,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: TokyoNightLight.foreground,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: TokyoNightLight.foreground,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: TextStyle(color: TokyoNightLight.foreground),
        bodySmall: TextStyle(color: TokyoNightLight.foreground),
      ),
    );
  }
}
