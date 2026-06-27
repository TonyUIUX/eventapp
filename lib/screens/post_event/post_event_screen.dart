import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/payment_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../models/post_event_form_data.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_config_provider.dart';
import '../../services/event_post_service.dart';
import '../../services/storage_service.dart';
import '../../core/auth_gate.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/utils/app_router.dart';
import '../../main.dart'; // Add this import for MainShell
import 'success_screen.dart';
import '../../core/widgets/dark_shimmer.dart';
// ── Instamojo additions (Razorpay imports above are untouched) ──────────────
import '../payment/payment_webview_screen.dart';
import '../../models/app_config_model.dart';
// ── Cashfree — provided via cashfreeServiceProvider (app_config_provider.dart) ─────
import 'steps/step1_basics.dart';
import 'steps/step2_details.dart';
import 'steps/step3_media.dart';
import 'steps/step4_organizer.dart';
import 'steps/step5_review.dart';

// lib/screens/post_event/post_event_screen.dart
// Dark glassmorphism post event shell

import '../../models/event_model.dart'; // Added import for EventModel

class PostEventScreen extends ConsumerStatefulWidget {
  final EventModel? eventToEdit;
  
  const PostEventScreen({super.key, this.eventToEdit});

  @override
  ConsumerState<PostEventScreen> createState() => _PostEventScreenState();
}

class _PostEventScreenState extends ConsumerState<PostEventScreen> {
  final PageController _pageController = PageController();
  final PostEventFormData _formData = PostEventFormData();
  int _currentStep = 0;
  bool _isSubmitting = false;
  bool _isDraftLoaded = false;

  final List<String> _stepTitles = [
    'Basics',
    'Details',
    'Media',
    'Contact & Tags',
    'Review',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.eventToEdit != null) {
      _formData.fromEventModel(widget.eventToEdit!);
      _isDraftLoaded = true;
    } else {
      _initDraft();
    }
  }

  Future<void> _initDraft() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(PostEventFormData.draftKey)) {
      if (mounted) {
        final restore = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.backgroundSheet,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              side: const BorderSide(color: AppColors.glassBorder),
            ),
            title: Text('Continue Draft?', style: AppTextStyles.heading2.copyWith(color: Colors.white)),
            content: Text('You have an unsaved event draft. Would you like to continue?', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
            actions: [
              TextButton(
                onPressed: () {
                  _formData.clearDraft();
                  Navigator.pop(context, false);
                },
                child: Text('Discard', style: AppTextStyles.label.copyWith(color: AppColors.error)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Yes', style: AppTextStyles.label.copyWith(color: Colors.white)),
              ),
            ],
          ),
        );
        if (restore == true) {
          await _formData.loadDraft();
        }
      }
    }
    if (mounted) {
      setState(() => _isDraftLoaded = true);
    }
  }

  void _onFormUpdate() {
    setState(() {});
    _formData.saveDraft();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _handleSubmit() async {
    final isSuperAdmin = ref.read(isSuperAdminProvider);
    setState(() => _isSubmitting = true);

    try {
      // 1. Upload images — gracefully skip if Storage is unavailable
      List<String> imageUrls = List<String>.from(_formData.existingImageUrls);
      bool storageError = false;
      for (var i = 0; i < _formData.images.length; i++) {
        try {
          final url = await StorageService().uploadEventImage(
            _formData.images[i],
            'user_post_${DateTime.now().millisecondsSinceEpoch}',
            'img_$i.jpg',
          );
          imageUrls.add(url);
        } catch (uploadErr) {
          storageError = true;
          debugPrint('StorageService upload error: $uploadErr');
        }
      }
      if (storageError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Image upload failed — submitting event without photos.',
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
            ),
            backgroundColor: AppColors.backgroundCard,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.glassBorder),
            ),
          ),
        );
      }

      if (_formData.eventIdToEdit != null) {
        // Edit flow
        await EventPostService.instance.updateEvent(
          eventId: _formData.eventIdToEdit!,
          eventData: _formData.toMap(),
          imageUrls: imageUrls,
        );
        await _onSuccess();
        return;
      }

      // ── Superadmin: post instantly, skip payment entirely ──────────────
      if (isSuperAdmin) {
        await EventPostService.instance.submitSuperAdminEvent(
          eventData: _formData.toMap(),
          imageUrls: imageUrls,
          eventDurationDays: 365,
        );
        await _onSuccess();
        return;
      }

      // ── Normal flow ────────────────────────────────────────────────────
      final configAsync = ref.read(appConfigProvider);
      final config = configAsync.value;
      if (config == null) {
        setState(() => _isSubmitting = false);
        return;
      }

      if (config.requiresPayment && config.paymentEnabled) {
        // ── Gateway decision from Firestore config — zero code change needed
        if (config.useInstamojo) {
          await _initiateInstamojoPayment(config, imageUrls);
        } else if (config.useCashfree) {
          await _initiateCashfreePayment(config, imageUrls);
        } else {
          // ── Existing Razorpay code — completely unchanged ───────────────
          _initiateRazorpayPayment(config, imageUrls);
        }
      } else {
        // Free submission
        await EventPostService.instance.submitFreeEvent(
          eventData: _formData.toMap(),
          eventDurationDays: config.eventDurationDays,
          imageUrls: imageUrls,
        );
        await _onSuccess();
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: $e', style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)), 
            backgroundColor: AppColors.backgroundCard,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.glassBorder)),
          ),
        );
      }
    }
  }

  // ── EXISTING Razorpay method — body untouched, only extracted ─────────────
  void _initiateRazorpayPayment(AppConfigModel config, List<String> imageUrls) {
    EventPostService.instance.createPendingEvent(
      eventData: _formData.toMap(),
      eventDurationDays: config.eventDurationDays,
      imageUrls: imageUrls,
    ).then((eventId) {
      // 3. Start Payment
      PaymentService.instance.startPayment(
        amountPaise: config.postingFee,
        contactPhone: _formData.contactPhone ?? '',
        onSuccess: (paymentId) async {
          await EventPostService.instance.markPaymentComplete(
            eventId: eventId,
            paymentId: paymentId,
            postingFee: config.postingFee,
          );
          await _onSuccess();
        },
        onError: (error) async {
          await EventPostService.instance.markPaymentFailed(eventId);
          setState(() => _isSubmitting = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payment Failed: $error', style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)), 
                backgroundColor: AppColors.backgroundCard,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.glassBorder)),
              ),
            );
          }
        },
      );
    });
  }

  // ── NEW Instamojo method — parallel branch, zero Razorpay code touched ────
  Future<void> _initiateInstamojoPayment(
      AppConfigModel config, List<String> imageUrls) async {
    try {
      // Step 1: Create pending event draft in Firestore
      final eventId = await EventPostService.instance.createPendingEvent(
        eventData: _formData.toMap(),
        eventDurationDays: config.eventDurationDays,
        imageUrls: imageUrls,
      );

      // Step 2: Create Instamojo payment request via REST API
      final user = ref.read(currentUserProfileProvider).value;
      final service = ref.read(instamojoServiceProvider);

      final paymentRequest = await service.createPaymentRequest(
        purpose: 'Evorra Event: ${_formData.title}',
        amountRupees: config.postingFee,
        buyerName: user?.displayName ?? 'Evorra User',
        buyerEmail: user?.email ?? 'noemail@evorra.app',
        buyerPhone: user?.phone ?? '0000000000',
        eventId: eventId,
      );

      setState(() => _isSubmitting = false);
      if (!mounted) return;

      // Step 3: Open WebView for payment
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentWebViewScreen(
            paymentRequest: paymentRequest,
            onSuccess: () async {
              // Mark paid in Firestore
              await EventPostService.instance.markPaymentComplete(
                eventId: eventId,
                paymentId: paymentRequest.id,
                postingFee: config.postingFee,
              );
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                SlideUpFadeRoute(page: const SuccessScreen()),
              );
            },
            onFailure: () async {
              await EventPostService.instance.markPaymentFailed(eventId);
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Payment cancelled or failed.'),
                  backgroundColor: AppColors.backgroundCard,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.glassBorder),
                  ),
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not start payment: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── NEW Cashfree method — parallel branch, zero Razorpay/Instamojo touched ──
  Future<void> _initiateCashfreePayment(
      AppConfigModel config, List<String> imageUrls) async {
    try {
      // Step 1: Create pending event draft in Firestore
      final eventId = await EventPostService.instance.createPendingEvent(
        eventData: _formData.toMap(),
        eventDurationDays: config.eventDurationDays,
        imageUrls: imageUrls,
      );

      // Step 2: Create Cashfree order via REST API
      final user = ref.read(currentUserProfileProvider).value;
      final cashfreeService = ref.read(cashfreeServiceProvider);

      // Register callbacks BEFORE doPayment
      cashfreeService.setCallback(
        onSuccess: (orderId) async {
          // Step 3a: Verify payment on success callback
          final isPaid = await cashfreeService.verifyOrder(orderId);
          if (isPaid) {
            await EventPostService.instance.markPaymentComplete(
              eventId: eventId,
              paymentId: orderId,
              postingFee: config.postingFee,
            );
            await _onSuccess();
          } else {
            await EventPostService.instance.markPaymentFailed(eventId);
            setState(() => _isSubmitting = false);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Payment verification failed. Please contact support.',
                    style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                  ),
                  backgroundColor: AppColors.backgroundCard,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.glassBorder),
                  ),
                ),
              );
            }
          }
        },
        onError: (errorMessage, orderId) async {
          await EventPostService.instance.markPaymentFailed(eventId);
          setState(() => _isSubmitting = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Payment failed: $errorMessage',
                  style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                ),
                backgroundColor: AppColors.backgroundCard,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.glassBorder),
                ),
              ),
            );
          }
        },
      );

      // Create order (server-side call via REST API)
      final order = await cashfreeService.createOrder(
        amountRupees: config.postingFee ~/ 100, // convert paise to rupees
        customerId: user?.uid ?? 'guest',
        customerEmail: user?.email ?? 'noemail@evorra.app',
        customerPhone: user?.phone ?? '9999999999',
        customerName: user?.displayName ?? 'Evorra User',
        eventId: eventId,
      );

      setState(() => _isSubmitting = false);
      if (!mounted) return;

      // Step 4: Open Cashfree WebView checkout
      cashfreeService.doPayment(order);
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not start Cashfree payment: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _onSuccess() async {
    await _formData.clearDraft();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      SlideUpFadeRoute(page: const SuccessScreen()),
    );
  }

  Future<bool> _showExitDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundSheet,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        title: Text('Save Draft?', style: AppTextStyles.heading2.copyWith(color: Colors.white)),
        content: Text('You have unsaved changes. Would you like to keep your progress as a draft?', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true), // Exit, keep draft
            child: Text('Yes, Exit', style: AppTextStyles.label.copyWith(color: AppColors.error)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Stay
            child: Text('No, Stay', style: AppTextStyles.label.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return AuthGate(
      reason: 'Sign in to post your events to the community.',
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final shouldPop = await _showExitDialog();
          if (shouldPop && context.mounted) {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(context, SlideUpFadeRoute(page: const MainShell()));
            }
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.backgroundBase,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            title: ShaderMask(
              shaderCallback: (bounds) => AppColors.brandGradient.createShader(bounds),
              blendMode: BlendMode.srcIn,
              child: Text('Create Event', style: AppTextStyles.heading2.copyWith(color: Colors.white)),
            ),
            leading: _currentStep > 0
                ? IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white), onPressed: _prevStep)
                : IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () async {
                      final shouldPop = await _showExitDialog();
                      if (shouldPop && context.mounted) {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          Navigator.pushReplacement(context, SlideUpFadeRoute(page: const MainShell()));
                        }
                      }
                    },
                  ),
          ),
          body: !_isDraftLoaded 
              ? const _FormSkeleton()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Progress Bar
                    ShaderMask(
                      shaderCallback: (bounds) => AppColors.brandGradient.createShader(bounds),
                      blendMode: BlendMode.srcIn,
                      child: LinearProgressIndicator(
                        value: (_currentStep + 1) / 5,
                        backgroundColor: AppColors.glassBorder.withValues(alpha: 0.3),
                        color: Colors.white,
                        minHeight: 3,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Step Label
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Text(
                        'Step ${_currentStep + 1} of 5 · ${_stepTitles[_currentStep]}',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (idx) => setState(() => _currentStep = idx),
                        physics: const NeverScrollableScrollPhysics(), // No swipe
                        children: [
                          Step1Basics(formData: _formData, onUpdate: _onFormUpdate),
                          Step2Details(formData: _formData, onUpdate: _onFormUpdate),
                          Step3Media(formData: _formData, onUpdate: _onFormUpdate),
                          Step4Organizer(formData: _formData, onUpdate: _onFormUpdate),
                          Step5Review(formData: _formData, onConfirm: _handleSubmit, isSubmitting: _isSubmitting),
                        ],
                      ),
                    ),
                  ],
                ),
          bottomNavigationBar: _currentStep < 4 && _isDraftLoaded && !isKeyboardOpen
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: GradientButton(
                      label: 'Continue',
                      height: 56,
                      onTap: _handleNextStep,
                    ),
                  ),
                )
              : null,
        ),      // closes Scaffold
      ),        // closes PopScope
    );          // closes AuthGate
  }

  void _handleNextStep() {
    String? error;
    switch (_currentStep) {
      case 0:
        if (_formData.title.length < 5 || _formData.title.length > 80) {
          error = 'Title must be 5-80 characters.';
        } else if (_formData.category.isEmpty) {
          error = 'Please select a category.';
        } else if (_formData.date == null) {
          error = 'Please select a date.';
        } else if (_formData.date!.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
          error = 'Select a future date.';
        }
        break;
      case 1:
        if (_formData.description.length < 50 || _formData.description.length > 1000) {
          error = 'Description must be 50-1000 characters.';
        } else if (_formData.location.isEmpty) {
          error = 'Please enter a venue location.';
        } else if (_formData.mapLink != null && _formData.mapLink!.isNotEmpty && !_formData.mapLink!.startsWith('https://')) {
          error = 'Map link must start with https://';
        } else if (_formData.ticketLink != null && _formData.ticketLink!.isNotEmpty && !_formData.ticketLink!.startsWith('http')) {
          error = 'Ticket link must be a valid URL starting with http.';
        } else if (_formData.registrationLink != null && _formData.registrationLink!.isNotEmpty && !_formData.registrationLink!.startsWith('http')) {
          error = 'Registration link must be a valid URL starting with http.';
        }
        break;
      case 2:
        // Image is now optional
        break;
      case 3:
        if (_formData.organizer.isEmpty) {
          error = 'Please enter an organizer name.';
        } else if (_formData.contactPhone != null && _formData.contactPhone!.isNotEmpty && !RegExp(r'^\d{10}$').hasMatch(_formData.contactPhone!)) {
          error = 'Phone must be exactly 10 digits.';
        }
        break;
    }

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
          backgroundColor: AppColors.backgroundCard,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.glassBorder)),
        ),
      );
    } else {
      _nextStep();
    }
  }
}

class _FormSkeleton extends StatelessWidget {
  const _FormSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: AppSpacing.md),
          DarkShimmer(width: double.infinity, height: 4),
          SizedBox(height: AppSpacing.xl),
          DarkShimmer(width: 80, height: 12),
          SizedBox(height: AppSpacing.sm),
          DarkShimmer(width: double.infinity, height: 52, borderRadius: AppRadius.md),
          SizedBox(height: AppSpacing.xl),
          DarkShimmer(width: 90, height: 12),
          SizedBox(height: AppSpacing.sm),
          DarkShimmer(width: double.infinity, height: 52, borderRadius: AppRadius.md),
          SizedBox(height: AppSpacing.xl),
          DarkShimmer(width: 70, height: 12),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: DarkShimmer(width: double.infinity, height: 76, borderRadius: AppRadius.md)),
              SizedBox(width: AppSpacing.md),
              Expanded(child: DarkShimmer(width: double.infinity, height: 76, borderRadius: AppRadius.md)),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: DarkShimmer(width: double.infinity, height: 76, borderRadius: AppRadius.md)),
              SizedBox(width: AppSpacing.md),
              Expanded(child: DarkShimmer(width: double.infinity, height: 76, borderRadius: AppRadius.md)),
            ],
          ),
        ],
      ),
    );
  }
}
