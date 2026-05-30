import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/tap_scale.dart';
import '../../providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

// lib/screens/auth/auth_screen.dart
// Dark glassmorphism Auth Screen — Evorra v3.1

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() => _errorMessage = null);
        _formKey.currentState?.reset();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final authService = ref.read(authServiceProvider);
      final cred = await authService.signInWithGoogle();
      if (cred != null && mounted) {
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'popup-blocked'           => 'Popup was blocked. Please allow popups for this site.',
        'cancelled-popup-request' => 'Sign-in was cancelled.',
        'user-cancelled'          => 'Sign-in was cancelled.',
        'network-request-failed'  => 'Network error. Check your internet connection.',
        _                         => 'Google Sign-In failed (${e.code}). Please try again.',
      };
      _showError(msg);
    } catch (e) {
      _showError('Google Sign-In failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPhoneAuthSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PhoneAuthSheet(
        authService: ref.read(authServiceProvider),
        onSuccess: () {
          Navigator.pop(context); // close sheet
          if (mounted) Navigator.pop(context); // close auth screen
        },
      ),
    );
  }

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final authService = ref.read(authServiceProvider);
      final isSignUp = _tabController.index == 1;

      if (isSignUp) {
        await authService.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          displayName: _nameController.text.trim(),
        );
      } else {
        await authService.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }

      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'email-already-in-use'    => 'An account with this email already exists.',
        'invalid-email'           => 'Please enter a valid email address.',
        'weak-password'           => 'Password must be at least 6 characters.',
        'user-not-found'          => 'No account found with this email.',
        'wrong-password'          => 'Incorrect password. Please try again.',
        'invalid-credential'      => 'Email or password is incorrect.',
        'too-many-requests'       => 'Too many attempts. Please wait and try again.',
        'network-request-failed'  => 'Network error. Check your internet connection.',
        'operation-not-allowed'   => 'Email/Password sign-in is not enabled. Contact support.',
        'user-disabled'           => 'This account has been disabled.',
        _                         => 'Sign-in failed (${e.code}). Please try again.',
      };
      _showError(msg);
    } catch (e) {
      _showError('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSignUp = _tabController.index == 1;

    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      body: Stack(
        children: [
          // Background Gradient Blob
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
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Close Button
                  Align(
                    alignment: Alignment.topLeft,
                    child: TapScale(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.glassSurface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // App Logo/Name
                  Center(
                    child: ShaderMask(
                      shaderCallback: (bounds) => AppColors.brandGradient.createShader(bounds),
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
                      style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Google Button
                  TapScale(
                    onTap: _isLoading ? null : _handleGoogleSignIn,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Inline Google 'G' — no network call, no SVG issue
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
                            style: AppTextStyles.label.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.glassBorder)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('or', style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
                      ),
                      const Expanded(child: Divider(color: AppColors.glassBorder)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Custom Tab Bar
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

                  // Form Error Message
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: AppTextStyles.caption.copyWith(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Input Fields
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (isSignUp) ...[
                          _GlassTextField(
                            controller: _nameController,
                            hintText: 'Full Name',
                            icon: Icons.person_outline_rounded,
                            validator: (val) => val == null || val.isEmpty ? 'Name is required' : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        _GlassTextField(
                          controller: _emailController,
                          hintText: 'Email Address',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (val) => val == null || !val.contains('@') ? 'Enter a valid email' : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _GlassTextField(
                          controller: _passwordController,
                          hintText: 'Password',
                          icon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppColors.textTertiary, size: 20),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          validator: (val) => val == null || val.length < 6 ? 'Min 6 characters' : null,
                        ),
                        
                        const SizedBox(height: AppSpacing.xl),

                        // Action Button
                        GradientButton(
                          label: isSignUp ? 'Create Account' : 'Sign In',
                          isLoading: _isLoading,
                          height: 56,
                          onTap: _isLoading ? () {} : () => _handleEmailAuth(),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Phone Auth Link
                        TapScale(
                          onTap: () => _showPhoneAuthSheet(context),
                          child: Text(
                            'Continue with Phone Number',
                            style: AppTextStyles.label.copyWith(color: AppColors.brandCoral),
                          ),
                        ),
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
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _GlassTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: AppTextStyles.body.copyWith(color: Colors.white),
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
        errorStyle: AppTextStyles.caption.copyWith(color: AppColors.error),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
        validator: validator,
    );
  }
}

// ── Phone Auth Bottom Sheet ────────────────────────────────────────────────────

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
    if (phone.length < 10) {
      setState(() => _error = 'Enter a valid phone number with country code (e.g. +91XXXXXXXXXX)');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      await widget.authService.verifyPhone(
        phoneNumber: phone,
        onCodeSent: (String verificationId) {
          if (mounted) setState(() { _verificationId = verificationId; _otpSent = true; _isLoading = false; });
        },
        onFailed: (e) {
          if (mounted) setState(() { _error = 'Failed to send OTP: ${e.message}'; _isLoading = false; });
        },
      );
    } catch (e) {
      if (mounted) setState(() { _error = 'An error occurred. Try again.'; _isLoading = false; });
    }
  }

  Future<void> _verifyOtp() async {
    if (_verificationId == null) return;
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _error = 'Enter the 6-digit OTP');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      await widget.authService.signInWithOTP(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      widget.onSuccess();
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() { _error = e.code == 'invalid-verification-code' ? 'Invalid OTP. Please try again.' : 'Verification failed. Try again.'; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Verification failed. Try again.'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: const BoxDecoration(
          color: AppColors.backgroundSheet,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          border: Border(top: BorderSide(color: AppColors.glassBorder)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.glassBorder, borderRadius: BorderRadius.circular(2)),
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
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: AppTextStyles.caption.copyWith(color: AppColors.error))),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (!_otpSent)
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: AppTextStyles.body.copyWith(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '+91 98765 43210',
                  hintStyle: AppTextStyles.body.copyWith(color: AppColors.textTertiary),
                  prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textTertiary, size: 20),
                  filled: true,
                  fillColor: AppColors.glassSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.glassBorder)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              )
            else
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: AppTextStyles.heading2.copyWith(color: Colors.white, letterSpacing: 8),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '------',
                  hintStyle: AppTextStyles.heading2.copyWith(color: AppColors.textTertiary, letterSpacing: 8),
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.glassSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.brandCoral)),
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
                  onPressed: _isLoading ? null : () => setState(() { _otpSent = false; _error = null; _otpController.clear(); }),
                  child: Text('Change number', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
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
