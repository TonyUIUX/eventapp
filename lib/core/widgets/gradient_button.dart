import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';

// lib/core/widgets/gradient_button.dart
// Full-width gradient CTA button — KochiGo v3.1

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Gradient gradient;
  final double height;
  final Widget? icon;
  final bool isLoading;

  const GradientButton({
    required this.label,
    required this.onTap,
    this.gradient = AppColors.brandGradient,
    this.height = 54,
    this.icon,
    this.isLoading = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: const [
            BoxShadow(
              color: AppColors.glowCoral,
              blurRadius: 20,
              spreadRadius: -4,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[icon!, const SizedBox(width: AppSpacing.sm)],
                    Text(
                      label,
                      style: AppTextStyles.button.copyWith(color: Colors.white),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
