/// app_colors.dart
///
/// Centralised color palette for the ELLY application.
/// Colors are chosen to be:
///   - Accessible (WCAG AA contrast ratios)
///   - Color-blind safe (tested against Deuteranopia / Protanopia)
///   - Compatible with Material 3 dynamic color seeds

library;

import 'package:flutter/material.dart';

/// All color constants used throughout the ELLY app.
abstract final class AppColors {
  // ── Brand / Emergency ─────────────────────────────────────────────────────
  /// Primary SOS button color — deep red, accessible on both light and dark.
  static const Color sosPrimary = Color(0xFFD32F2F);

  /// Lighter tint used for ripple/pulse layers.
  static const Color sosPrimaryLight = Color(0xFFEF5350);

  /// Faintest pulse ring — subtle ambient glow.
  static const Color sosPrimaryFaint = Color(0x1AD32F2F);

  /// On-color for SOS button text/icons (white).
  static const Color sosOnPrimary = Color(0xFFFFFFFF);

  // ── Success ───────────────────────────────────────────────────────────────
  /// Activated / success green — color-blind safe.
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color successGreenLight = Color(0xFF43A047);
  static const Color successOnGreen = Color(0xFFFFFFFF);

  // ── Neutral ───────────────────────────────────────────────────────────────
  /// Surface background (light mode).
  static const Color surfaceLight = Color(0xFFFAFAFA);

  /// Surface background (dark mode).
  static const Color surfaceDark = Color(0xFF121212);

  /// Card / sheet background (light mode).
  static const Color cardLight = Color(0xFFFFFFFF);

  /// Card / sheet background (dark mode).
  static const Color cardDark = Color(0xFF1E1E1E);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimaryLight = Color(0xFF1A1A2E);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textPrimaryDark = Color(0xFFF5F5F5);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);

  // ── Material 3 Seed ───────────────────────────────────────────────────────
  /// Seed color for Material 3 [ColorScheme.fromSeed].
  static const Color colorSchemeSeed = Color(0xFFD32F2F);
}
