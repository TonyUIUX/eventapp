import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

// lib/core/theme/app_theme.dart
// Dark-only ThemeData — KochiGo v3.1
// App is dark-only. No light theme.

class AppTheme {
  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.backgroundBase,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.brandCoral,
      secondary: AppColors.brandPurple,
      surface: AppColors.backgroundCard,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSurface: AppColors.textPrimary,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: AppColors.textPrimary,
      titleTextStyle: AppTextStyles.heading2,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      selectedItemColor: AppColors.brandCoral,
      unselectedItemColor: AppColors.textTertiary,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AppColors.backgroundCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.glassBorder, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.backgroundCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.brandCoral, width: 1.5),
      ),
      hintStyle: AppTextStyles.body,
      labelStyle: AppTextStyles.label,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.glassBorder,
      thickness: 0.5,
    ),
    textTheme: const TextTheme(
      displayLarge:  AppTextStyles.display,
      headlineLarge: AppTextStyles.heading1,
      headlineMedium: AppTextStyles.heading2,
      headlineSmall: AppTextStyles.heading3,
      bodyLarge:     AppTextStyles.bodyLarge,
      bodyMedium:    AppTextStyles.body,
      labelLarge:    AppTextStyles.button,
      labelSmall:    AppTextStyles.caption,
    ),
    useMaterial3: true,
    fontFamily: 'Poppins',
  );
}
