/// app_theme.dart
///
/// Material 3 [ThemeData] for the ELLY application.
/// Exposes both [lightTheme] and [darkTheme] instances.
/// Typography is powered by Google Fonts (Inter).

library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// ELLY Material 3 theme factory.
abstract final class AppTheme {
  // ── Light Theme ───────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.colorSchemeSeed,
      surface: AppColors.surfaceLight,
    );

    return _buildTheme(colorScheme);
  }

  // ── Dark Theme ────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.colorSchemeSeed,
      brightness: Brightness.dark,
      surface: AppColors.surfaceDark,
    );

    return _buildTheme(colorScheme);
  }

  // Helper method to bypass GoogleFonts during tests to prevent network fetching errors.
  static TextStyle _fontStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    }
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  // ── Shared Builder ────────────────────────────────────────────────────────
  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
    );

    final isTesting = Platform.environment.containsKey('FLUTTER_TEST');
    final textThemeBase = isTesting
        ? base.textTheme
        : GoogleFonts.interTextTheme(base.textTheme);

    return base.copyWith(
      // ── Typography ─────────────────────────────────────────────────────
      textTheme: textThemeBase.copyWith(
        // Headline used for countdown number
        displayLarge: _fontStyle(
          fontSize: 120,
          fontWeight: FontWeight.w800,
          color: colorScheme.onSurface,
          letterSpacing: -4,
        ),
        // SOS button label
        headlineLarge: _fontStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.sosOnPrimary,
          letterSpacing: 2,
        ),
        // SOS button subtext
        titleMedium: _fontStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.sosOnPrimary.withValues(alpha: 0.85),

          letterSpacing: 1.5,
        ),
        // Sheet title
        headlineSmall: _fontStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
        // Body / description
        bodyLarge: _fontStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurfaceVariant,
          height: 1.5,
        ),
      ),

      // ── Elevated Button ────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: _fontStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // ── Text Button ────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(120, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: _fontStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Bottom Sheet ───────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: true,
      ),

      // ── App Bar ────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: _fontStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}
