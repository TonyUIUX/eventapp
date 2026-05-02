import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'constants/app_colors.dart';
import 'constants/app_text_styles.dart';
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
      error: (err, stack) => Center(child: Text('Error: $err')),
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline_rounded, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            const Text(
              'Sign In Required',
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: 8),
            Text(
              reason,
              style: AppTextStyles.bodyRegular,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Sign In or Create Account'),
            ),
          ],
        ),
      ),
    );
  }
}
