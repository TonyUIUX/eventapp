import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

// lib/core/widgets/glass_card.dart
// Reusable frosted glassmorphism card — KochiGo v3.1

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blur;
  final Color? glowColor;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const GlassCard({
    required this.child,
    this.padding,
    this.borderRadius = AppRadius.lg,
    this.blur = 20,
    this.glowColor,
    this.gradient,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: gradient,
          color: gradient == null ? AppColors.glassSurface : null,
          border: Border.all(color: AppColors.glassBorder, width: 1),
          boxShadow: glowColor != null
              ? [
                  BoxShadow(
                    color: glowColor!,
                    blurRadius: 24,
                    spreadRadius: -4,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(AppSpacing.md),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
