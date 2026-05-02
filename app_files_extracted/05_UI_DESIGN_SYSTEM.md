# 🎨 UI Design System

## Design Principles
1. **Clarity first** — Users should understand what an event is in 3 seconds
2. **Minimal chrome** — The content IS the UI. No decorative elements
3. **Touch-friendly** — All tap targets minimum 48×48dp
4. **Consistent spacing** — Use multiples of 4dp (4, 8, 12, 16, 20, 24, 32)

---

## Color Palette

```dart
// lib/core/constants/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  // Primary — Vibrant coral/orange (energetic, event-vibe)
  static const Color primary = Color(0xFFFF5A35);
  static const Color primaryLight = Color(0xFFFF8A6B);
  static const Color primaryDark = Color(0xFFCC3B1E);

  // Backgrounds
  static const Color background = Color(0xFFF8F8F8);   // Off-white page bg
  static const Color surface = Color(0xFFFFFFFF);       // Card background
  static const Color surfaceAlt = Color(0xFFF2F2F2);   // Chip unselected bg

  // Text
  static const Color textPrimary = Color(0xFF1A1A1A);  // Titles
  static const Color textSecondary = Color(0xFF666666); // Subtitles, meta
  static const Color textTertiary = Color(0xFF999999);  // Placeholder, disabled

  // Borders & Dividers
  static const Color border = Color(0xFFE8E8E8);
  static const Color divider = Color(0xFFF0F0F0);

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);

  // Category Colors (for chips/badges)
  static const Map<String, Color> categoryColors = {
    'comedy':   Color(0xFFFBBF24),  // Amber
    'music':    Color(0xFF8B5CF6),  // Purple
    'tech':     Color(0xFF3B82F6),  // Blue
    'fitness':  Color(0xFF22C55E),  // Green
    'art':      Color(0xFFEC4899),  // Pink
    'workshop': Color(0xFFFF5A35),  // Primary orange
  };
}
```

---

## Typography

```dart
// lib/core/constants/app_text_styles.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Font: Use Google Fonts — 'Poppins'
  // Add google_fonts package for this

  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle bodyRegular = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.6,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
    letterSpacing: 0.3,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );
}
```

> Add `google_fonts: ^6.x.x` to pubspec.yaml and wrap TextStyles with `GoogleFonts.poppins(textStyle: ...)` for the Poppins font.

---

## Spacing Constants

```dart
// lib/core/constants/app_constants.dart

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 100.0; // Pill shape
}
```

---

## Component Specs

### EventCard
```
Container:
  margin: 16px horizontal, 8px vertical
  decoration: rounded 12px, white bg, shadow (blur 8, offset y:2, opacity 0.08)

Image:
  aspect ratio: 16:9
  border radius: 12px top (only top corners)
  use CachedNetworkImage with shimmer placeholder

Category Chip (on image, bottom-left):
  position: absolute, 8px from bottom, 8px from left
  background: category color (from AppColors.categoryColors)
  text: white, 11px, semibold, uppercase
  padding: 3px 8px
  border radius: 100px (pill)

Content Padding: 12px all sides

Title:
  style: AppTextStyles.cardTitle
  maxLines: 2
  overflow: ellipsis

Date Row:
  icon: Icons.calendar_today, size 13, color textSecondary
  text: "Sat, 19 Apr · 7:00 PM"
  gap: 5px between icon and text
  margin top: 6px

Location Row:
  icon: Icons.location_on_outlined, size 13, color textSecondary
  text: event.location
  maxLines: 1, overflow: ellipsis
  margin top: 4px
```

### Category Chip (Filter Bar)
```
Selected:
  background: AppColors.primary
  text: white, 13px, semibold

Unselected:
  background: AppColors.surfaceAlt
  text: AppColors.textSecondary, 13px

Height: 36px
Padding: 12px horizontal
Border radius: 100px (pill)
Gap between chips: 8px
```

### Shimmer Placeholder Card
```
Same dimensions as EventCard
Replace all content with grey shimmer blocks:
  - Image area: full shimmer
  - Title: 2 lines, shimmer
  - Date: 1 line short, shimmer
  - Location: 1 line medium, shimmer
Use `shimmer` package BaseColor: #E0E0E0, HighlightColor: #F5F5F5
```

---

## Theme Configuration

```dart
// In main.dart

ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    background: AppColors.background,
  ),
  scaffoldBackgroundColor: AppColors.background,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.surface,
    foregroundColor: AppColors.textPrimary,
    elevation: 0,
    scrolledUnderElevation: 1,
    titleTextStyle: AppTextStyles.heading2,
  ),
  cardTheme: CardTheme(
    color: AppColors.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
  ),
  useMaterial3: true,
)
```

---

## Iconography
Use Material Icons (built-in). No icon packages needed.

| Use Case         | Icon                         |
|------------------|------------------------------|
| Home tab         | Icons.home_outlined          |
| Saved tab        | Icons.bookmark_outline       |
| Date             | Icons.calendar_today         |
| Location         | Icons.location_on_outlined   |
| Phone            | Icons.phone_outlined         |
| Instagram        | Icons.alternate_email        |
| Back button      | Icons.arrow_back_ios_new     |
| Save (empty)     | Icons.bookmark_border        |
| Save (filled)    | Icons.bookmark               |
| Error            | Icons.wifi_off_rounded       |
| Empty            | Icons.event_busy_outlined    |
