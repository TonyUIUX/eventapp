import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'constants/app_colors.dart';
import 'constants/app_text_styles.dart';
import 'constants/app_spacing.dart';
import 'utils/app_router.dart';
import 'widgets/gradient_button.dart';
import '../screens/auth/auth_screen.dart';

class AuthGate extends ConsumerWidget {
  final Widget child;
  final String reason;

  const AuthGate({
    super.key,
    required this.child,
    this.reason = 'Please sign in to continue.',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          return child;
        }
        return _LoginPrompt(reason: reason);
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.brandCoral)),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 52)),
            const SizedBox(height: AppSpacing.lg),
            const Text('Auth Error', style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Something went wrong. Please try again.',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  final String reason;
  
  const _LoginPrompt({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline_rounded, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Sign In Required',
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              reason,
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            GradientButton(
              label: 'Sign In or Create Account',
              height: 48,
              onTap: () {
                Navigator.of(context).push(
                  SlideUpFadeRoute(page: const AuthScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
