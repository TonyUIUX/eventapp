import 'package:flutter/material.dart';

// lib/core/constants/app_colors.dart
// Dark Glassmorphism Design System — KochiGo v3.1

class AppColors {

  // ── BACKGROUNDS ────────────────────────────────────────────────
  static const Color backgroundDeep   = Color(0xFF08090F); // Deepest bg
  static const Color backgroundBase   = Color(0xFF0D0E1A); // Main scaffold
  static const Color backgroundCard   = Color(0xFF13141F); // Card surface
  static const Color backgroundSheet  = Color(0xFF181928); // Bottom sheets

  // ── GLASS SURFACES ─────────────────────────────────────────────
  // Semi-transparent overlays. Use with BackdropFilter blur.
  static const Color glassSurface    = Color(0x1AFFFFFF); // 10% white
  static const Color glassBorder     = Color(0x26FFFFFF); // 15% white
  static const Color glassHighlight  = Color(0x0DFFFFFF); // 5% white

  // ── BRAND GRADIENT (Primary) ───────────────────────────────────
  // Coral stays as brand anchor. Paired with deep purple.
  static const Color brandCoral   = Color(0xFFFF5247); // KochiGo coral
  static const Color brandPurple  = Color(0xFF7C3AFF); // Deep violet
  static const Color brandPink    = Color(0xFFE040FB); // Vivid magenta

  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFFFF5247), Color(0xFFE040FB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient brandGradientVertical = LinearGradient(
    colors: [Color(0xFFFF5247), Color(0xFF7C3AFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── ACCENT GRADIENTS (Cards, Categories) ──────────────────────
  static const LinearGradient accentGreenTeal = LinearGradient(
    colors: [Color(0xFF00C9A7), Color(0xFF00B4D8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentPurplePink = LinearGradient(
    colors: [Color(0xFF7C3AFF), Color(0xFFE040FB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentOrangeYellow = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFFD60A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentBlueViolet = LinearGradient(
    colors: [Color(0xFF4361EE), Color(0xFF7C3AFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Category gradient map ──────────────────────────────────────
  static const Map<String, LinearGradient> categoryGradients = {
    'comedy':   LinearGradient(colors: [Color(0xFFFFD60A), Color(0xFFFF6B35)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
    'music':    LinearGradient(colors: [Color(0xFF7C3AFF), Color(0xFFE040FB)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
    'tech':     LinearGradient(colors: [Color(0xFF4361EE), Color(0xFF00B4D8)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
    'fitness':  LinearGradient(colors: [Color(0xFF00C9A7), Color(0xFF00B4D8)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
    'art':      LinearGradient(colors: [Color(0xFFE040FB), Color(0xFFFF5247)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
    'workshop': LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFFD60A)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
    'food':     LinearGradient(colors: [Color(0xFFFF5247), Color(0xFFFF6B35)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
    'business': LinearGradient(colors: [Color(0xFF4361EE), Color(0xFF7C3AFF)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
  };

  // ── GLOW COLORS (for shadows and borders) ─────────────────────
  static const Color glowCoral   = Color(0x40FF5247); // 25% coral
  static const Color glowPurple  = Color(0x407C3AFF); // 25% purple
  static const Color glowGreen   = Color(0x4000C9A7); // 25% teal

  // ── TEXT ──────────────────────────────────────────────────────
  static const Color textPrimary    = Color(0xFFF1F1F5); // Near white
  static const Color textSecondary  = Color(0xFF8E8EA0); // Muted grey
  static const Color textTertiary   = Color(0xFF52526A); // Subtle hints
  static const Color textOnGradient = Color(0xFFFFFFFF); // Always white on gradient

  // ── STATUS ────────────────────────────────────────────────────
  static const Color success  = Color(0xFF00C9A7);
  static const Color warning  = Color(0xFFFFD60A);
  static const Color error    = Color(0xFFFF5247);
  static const Color info     = Color(0xFF4361EE);

  // ── LEGACY (keep for backwards compat during migration) ───────
  static const Color primary        = brandCoral;
  static const Color primaryLight   = Color(0xFFFFEBEB);
  static const Color primaryDark    = Color(0xFFD32F2F);
  static const Color accent         = success;
  static const Color background     = backgroundBase;
  static const Color surface        = backgroundCard;
  static const Color surfaceAlt     = backgroundSheet;
  static const Color border         = glassBorder;
  static const Color divider        = Color(0x1AFFFFFF);
  static const Color shimmerBase    = Color(0xFF1E1E2E);
  static const Color shimmerHighlight = Color(0xFF2E2E42);
  static const Color textOnPrimary  = Color(0xFFFFFFFF);

  // Legacy flat color map for category chips (screen migration compat)
  static const Map<String, Color> categoryColors = {
    'comedy':   Color(0xFFFFD60A),
    'music':    Color(0xFF7C3AFF),
    'tech':     Color(0xFF4361EE),
    'fitness':  Color(0xFF00C9A7),
    'art':      Color(0xFFE040FB),
    'workshop': Color(0xFFFF6B35),
    'food':     Color(0xFFFF5247),
    'business': Color(0xFF4361EE),
  };

  // Legacy shadow tokens
  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x60000000),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];
}
