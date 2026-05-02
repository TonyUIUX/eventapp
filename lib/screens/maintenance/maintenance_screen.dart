import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../providers/app_config_provider.dart';

// lib/screens/maintenance/maintenance_screen.dart
// Full dark glassmorphism maintenance screen — KochiGo v3.1

class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(appConfigProvider);
    final message = configAsync.maybeWhen(
      data: (config) => config.maintenanceMessage,
      orElse: () => 'We\'re polishing things up. Back soon!',
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      body: Stack(
        children: [
          // Background gradient blob — top right
          const Positioned(
            top: -120,
            right: -120,
            child: _GradientBlob(
              size: 320,
              gradient: AppColors.brandGradient,
              blurSigma: 80,
            ),
          ),

          // Background gradient blob — bottom left
          const Positioned(
            bottom: -80,
            left: -80,
            child: _GradientBlob(
              size: 240,
              gradient: AppColors.accentPurplePink,
              blurSigma: 60,
            ),
          ),

          // Content
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Large wrench emoji
                  const Text(
                    '🔧',
                    style: TextStyle(fontSize: 72),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Heading with gradient
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppColors.brandGradient.createShader(bounds),
                    blendMode: BlendMode.srcIn,
                    child: const Text(
                      'Under Maintenance',
                      style: AppTextStyles.display,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Maintenance message from Firebase
                  Text(
                    message,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.7,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Subtle animated progress indicator
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.brandCoral.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  const Text(
                    'Auto-refreshing…',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Blurred gradient blob for background decoration.
class _GradientBlob extends StatelessWidget {
  final double size;
  final Gradient gradient;
  final double blurSigma;

  const _GradientBlob({
    required this.size,
    required this.gradient,
    required this.blurSigma,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: const SizedBox(),
      ),
    );
  }
}
