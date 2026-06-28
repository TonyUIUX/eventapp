import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/tap_scale.dart';
import '../../providers/auth_provider.dart';

// lib/screens/auth/auth_screen.dart
// Dark glassmorphism Auth Screen — Evorra v3.2 (production-ready Google Sign-In)

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  // Track which tab is active — updated both when switching tabs and in build.
  bool _isSignUp = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _nameController = TextEditingController();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    // addListener fires on both indexIsChanging AND after the animation ends.
    // Use !indexIsChanging to catch the final settled state.
    if (!_tabController.indexIsChanging) {
      setState(() {
        _isSignUp = _tabController.index == 1;
        _errorMessage = null;
      });
      _formKey.currentState?.reset();
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (mounted) setState(() => _errorMessage = message);
  }

  void _clearError() {
    if (_errorMessage != null && mounted) setState(() => _errorMessage = null);
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────
  Future<void> _handleGoogleSignIn() async {
    _clearError();
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final cred = await authService.signInWithGoogle();

      if (!mounted) return;

      if (cred == null) {
        // User cancelled the Google account picker — silent, no error shown.
        return;
      }

      // Navigate away only if still mounted and sign-in succeeded.
      if (mounted) {
        Navigator.of(context).pop(true); // pass true = success
      }
    } on FirebaseAuthException catch (e) {
      final msg = _mapFirebaseError(e.code);
      _showError(msg);
    } catch (e) {
      _showError('Google Sign-In failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Email Auth ────────────────────────────────────────────────────────────
  Future<void> _handleEmailAuth() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _clearError();
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);

      if (_isSignUp) {
        await authService.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
        );
      } else {
        await authService.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (mounted) Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (e) {
      _showError(_mapFirebaseError(e.code));
    } catch (e) {
      _showError('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Error message mapper ──────────────────────────────────────────────────
  String _mapFirebaseError(String code) {
    return switch (code) {
      'email-already-in-use'    => 'An account with this email already exists.',
      'invalid-email'           => 'Please enter a valid email address.',
      'weak-password'           => 'Password must be at least 6 characters.',
      'user-not-found'          => 'No account found with this email.',
      'wrong-password'          => 'Incorrect password. Please try again.',
      'invalid-credential'      => 'Email or password is incorrect.',
      'too-many-requests'       => 'Too many attempts. Please wait and try again.',
      'network-request-failed'  => 'Network error. Check your internet connection.',
      'operation-not-allowed'   => 'This sign-in method is not enabled.',
      'user-disabled'           => 'This account has been disabled.',
      'popup-blocked'           => 'Popup was blocked. Please allow popups.',
      'cancelled-popup-request' => 'Sign-in was cancelled.',
      'user-cancelled'          => 'Sign-in was cancelled.',
      'google-sign-in-failed'   => 'Google Sign-In failed. Check your internet connection and try again.',
      _                         => 'Sign-in failed ($code). Please try again.',
    };
  }

  // ── Phone sheet ───────────────────────────────────────────────────────────
  // void _showPhoneAuthSheet() {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (_) => _PhoneAuthSheet(
  //       authService: ref.read(authServiceProvider),
  //       onSuccess: () {
  //         // Sheet pops itself — then pop auth screen.
  //         // if (mounted) Navigator.of(context).pop(true);
  //       },
  //     ),
  //   );
  // }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      body: Stack(
        children: [
          // Background gradient blob
          Positioned(
            top: -150,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandPurple.withValues(alpha: 0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: const SizedBox(),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Close button ──────────────────────────────────────────
                  Align(
                    alignment: Alignment.topLeft,
                    child: TapScale(
                      onTap: () => Navigator.of(context).pop(false),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.glassSurface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // ── Logo ──────────────────────────────────────────────────
                  Center(
                    child: ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.brandGradient.createShader(bounds),
                      blendMode: BlendMode.srcIn,
                      child: Text(
                        'Evorra',
                        style: AppTextStyles.display.copyWith(
                          fontFamily: 'Poppins',
                          fontSize: 48,
                          color: Colors.white,
                          letterSpacing: -1.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Center(
                    child: Text(
                      'Events. Community. Yours.',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // ── Google button ─────────────────────────────────────────
                  TapScale(
                    onTap: _isLoading ? null : _handleGoogleSignIn,
                    child: AnimatedOpacity(
                      opacity: _isLoading ? 0.5 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: _isLoading
                            ? const Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Google 'G' icon — no external asset needed
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'G',
                                        style: AppTextStyles.label.copyWith(
                                          color: Colors.blueAccent.shade700,
                                          fontWeight: FontWeight.w800,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Continue with Google',
                                    style: AppTextStyles.label
                                        .copyWith(color: Colors.white),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Divider ───────────────────────────────────────────────
                  Row(
                    children: [
                      const Expanded(
                          child: Divider(color: AppColors.glassBorder)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textTertiary),
                        ),
                      ),
                      const Expanded(
                          child: Divider(color: AppColors.glassBorder)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Tab bar ───────────────────────────────────────────────
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.glassSurface,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: AppColors.glassBorder,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.textSecondary,
                      labelStyle: AppTextStyles.label,
                      tabs: const [
                        Tab(text: 'Sign In'),
                        Tab(text: 'Create Account'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Error banner ──────────────────────────────────────────
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: _errorMessage != null
                        ? Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.error.withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                                border: Border.all(
                                    color: AppColors.error
                                        .withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: AppColors.error,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: AppTextStyles.caption
                                          .copyWith(color: AppColors.error),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _clearError,
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: AppColors.error,
                                      size: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  // ── Form ──────────────────────────────────────────────────
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (_isSignUp) ...[
                          _GlassTextField(
                            controller: _nameController,
                            hintText: 'Full Name',
                            icon: Icons.person_outline_rounded,
                            textInputAction: TextInputAction.next,
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                    ? 'Name is required'
                                    : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        _GlassTextField(
                          controller: _emailController,
                          hintText: 'Email Address',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Email is required';
                            }
                            final emailRegex = RegExp(
                                r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
                            if (!emailRegex.hasMatch(val.trim())) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _GlassTextField(
                          controller: _passwordController,
                          hintText: 'Password',
                          icon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleEmailAuth(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: AppColors.textTertiary,
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                          validator: (val) => val == null || val.length < 6
                              ? 'Minimum 6 characters required'
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        GradientButton(
                          label: _isSignUp ? 'Create Account' : 'Sign In',
                          isLoading: _isLoading,
                          height: 56,
                          onTap: _isLoading ? () {} : _handleEmailAuth,
                        ),

                        // Mobile sign-in button temporarily hidden
                      ],
                    ),
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

// ── Glass Text Field ──────────────────────────────────────────────────────────

class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;

  const _GlassTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.suffixIcon,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      style: AppTextStyles.body.copyWith(color: Colors.white),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textTertiary),
        prefixIcon: Icon(icon, color: AppColors.textTertiary, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.glassSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        errorStyle: AppTextStyles.caption.copyWith(color: AppColors.error),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
      validator: validator,
    );
  }
}

// ── Phone Auth Bottom Sheet ───────────────────────────────────────────────────

class _PhoneAuthSheet extends StatefulWidget {
  final dynamic authService;
  final VoidCallback onSuccess;
  const _PhoneAuthSheet({required this.authService, required this.onSuccess});

  @override
  State<_PhoneAuthSheet> createState() => _PhoneAuthSheetState();
}

class _PhoneAuthSheetState extends State<_PhoneAuthSheet> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isLoading = false;
  String? _verificationId;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (!RegExp(r'^\+[1-9]\d{9,14}$').hasMatch(phone)) {
      setState(() => _error =
          'Enter a valid number with country code (e.g. +91XXXXXXXXXX)');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await widget.authService.verifyPhone(
        phoneNumber: phone,
        onCodeSent: (String verificationId) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _otpSent = true;
              _isLoading = false;
            });
          }
        },
        onFailed: (FirebaseAuthException e) {
          if (mounted) {
            setState(() {
              _error = 'Failed to send OTP: ${e.message ?? e.code}';
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'An error occurred. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_verificationId == null) return;
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _error = 'Enter the 6-digit OTP');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await widget.authService.signInWithOTP(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      if (mounted) {
        Navigator.of(context).pop(); // close sheet
        widget.onSuccess();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.code == 'invalid-verification-code'
              ? 'Invalid OTP. Please try again.'
              : 'Verification failed (${e.code}). Try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Verification failed. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: const BoxDecoration(
          color: AppColors.backgroundSheet,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          border: Border(top: BorderSide(color: AppColors.glassBorder)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _otpSent ? 'Enter OTP' : 'Phone Sign-In',
              style: AppTextStyles.heading2.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _otpSent
                  ? 'Enter the 6-digit code sent to ${_phoneController.text.trim()}'
                  : 'We\'ll send a one-time code to verify your number.',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.error)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (!_otpSent)
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _sendOtp(),
                style: AppTextStyles.body.copyWith(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '+91 98765 43210',
                  hintStyle: AppTextStyles.body
                      .copyWith(color: AppColors.textTertiary),
                  prefixIcon: const Icon(Icons.phone_outlined,
                      color: AppColors.textTertiary, size: 20),
                  filled: true,
                  fillColor: AppColors.glassSurface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide:
                          const BorderSide(color: AppColors.glassBorder)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              )
            else
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _verifyOtp(),
                style: AppTextStyles.heading2
                    .copyWith(color: Colors.white, letterSpacing: 8),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '------',
                  hintStyle: AppTextStyles.heading2.copyWith(
                      color: AppColors.textTertiary, letterSpacing: 8),
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.glassSurface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide:
                          const BorderSide(color: AppColors.brandCoral)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                label: _otpSent ? 'Verify OTP' : 'Send OTP',
                isLoading: _isLoading,
                height: 56,
                onTap: _isLoading ? () {} : (_otpSent ? _verifyOtp : _sendOtp),
              ),
            ),
            if (_otpSent) ...[
              const SizedBox(height: AppSpacing.md),
              Center(
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => setState(() {
                            _otpSent = false;
                            _error = null;
                            _otpController.clear();
                          }),
                  child: Text(
                    'Change number',
                    style: AppTextStyles.label
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
