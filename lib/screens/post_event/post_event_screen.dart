import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/payment_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../models/post_event_form_data.dart';
import '../../providers/app_config_provider.dart';
import '../../services/event_post_service.dart';
import '../../services/storage_service.dart';
import '../../core/auth_gate.dart';
import '../../core/widgets/gradient_button.dart';
import '../../main.dart'; // Add this import for MainShell
import 'success_screen.dart';

import 'steps/step1_basics.dart';
import 'steps/step2_details.dart';
import 'steps/step3_media.dart';
import 'steps/step4_organizer.dart';
import 'steps/step5_review.dart';

// lib/screens/post_event/post_event_screen.dart
// Dark glassmorphism post event shell

class PostEventScreen extends ConsumerStatefulWidget {
  const PostEventScreen({super.key});

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
    _initDraft();
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
    final configAsync = ref.read(appConfigProvider);
    final config = configAsync.value;
    if (config == null) return;

    setState(() => _isSubmitting = true);
    
    try {
      // 1. Upload images first
      List<String> imageUrls = [];
      for (var i = 0; i < _formData.images.length; i++) {
        final url = await StorageService().uploadEventImage(
          _formData.images[i],
          'user_post_${DateTime.now().millisecondsSinceEpoch}',
          'img_$i.jpg',
        );
        imageUrls.add(url);
      }

      if (config.requiresPayment && config.paymentEnabled) {
        // 2. Create pending event
        final eventId = await EventPostService.instance.createPendingEvent(
          eventData: _formData.toMap(),
          eventDurationDays: config.eventDurationDays,
          imageUrls: imageUrls,
        );

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
                  content: Text('Payment Failed: $error', style: const TextStyle(color: Colors.white)), 
                  backgroundColor: AppColors.backgroundCard,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.glassBorder)),
                ),
              );
            }
          },
        );
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
            content: Text('Submission failed: $e', style: const TextStyle(color: Colors.white)), 
            backgroundColor: AppColors.backgroundCard,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.glassBorder)),
          ),
        );
      }
    }
  }

  Future<void> _onSuccess() async {
    await _formData.clearDraft();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SuccessScreen()),
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
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainShell()));
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
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainShell()));
                        }
                      }
                    },
                  ),
          ),
          body: !_isDraftLoaded 
              ? const Center(child: CircularProgressIndicator(color: AppColors.brandCoral))
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
          bottomNavigationBar: _currentStep < 4 && _isDraftLoaded
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
        if (_formData.images.isEmpty) {
          error = 'Please add at least one image.';
        }
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
          content: Text(error, style: const TextStyle(color: Colors.white)),
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
