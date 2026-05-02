import 'package:flutter/material.dart';
import 'app_colors.dart';

// lib/core/constants/app_text_styles.dart
// Dark Glassmorphism Typography — KochiGo v3.1

class AppTextStyles {
  // Font family: Poppins (bundled as asset in pubspec.yaml)
  static const String _font = 'Poppins';

  // ── DISPLAY ───────────────────────────────────────────────────
  static const TextStyle display = TextStyle(
    fontFamily: _font,
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.8,
    height: 1.1,
  );

  // Legacy alias
  static const TextStyle displayLarge = display;

  // ── HEADINGS ──────────────────────────────────────────────────
  static const TextStyle heading1 = TextStyle(
    fontFamily: _font,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: _font,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle heading3 = TextStyle(
    fontFamily: _font,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // ── BODY ──────────────────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _font,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.6,
  );

  static const TextStyle body = TextStyle(
    fontFamily: _font,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.6,
  );

  // ── LABELS & CAPTIONS ─────────────────────────────────────────
  static const TextStyle label = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.4,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _font,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
    letterSpacing: 0.6,
  );

  // ── BUTTONS ───────────────────────────────────────────────────
  static const TextStyle button = TextStyle(
    fontFamily: _font,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  // ── LEGACY ALIASES (backwards compat) ─────────────────────────
  static const TextStyle cardTitle      = heading3;
  static const TextStyle bodyRegular    = body;
  static const TextStyle bodySecondary  = body;
  static const TextStyle labelMedium    = label;
  static const TextStyle buttonText     = button;
  static const TextStyle bodyBold       = TextStyle(
    fontFamily: _font,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
  );
}
