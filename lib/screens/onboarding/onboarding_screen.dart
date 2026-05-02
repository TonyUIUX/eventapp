import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/gradient_button.dart';
import '../../main.dart';

// lib/screens/onboarding/onboarding_screen.dart
// Dark glassmorphism Onboarding Screen — KochiGo v3.1

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('has_seen_onboarding') ?? false;
    if (hasSeen && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    }
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  // Blob colors for each page
  final List<Color> _blobColors = [
    AppColors.brandCoral.withValues(alpha: 0.3),
    AppColors.brandPurple.withValues(alpha: 0.3),
    AppColors.success.withValues(alpha: 0.3),
  ];

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == 2;
    final blobColor = _blobColors[_currentPage];

    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      body: Stack(
        children: [
          // Background Gradient Blob
          AnimatedPositioned(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOutCubic,
            top: -100,
            right: _currentPage == 1 ? -150 : -50,
            left: _currentPage == 2 ? -100 : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 700),
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: blobColor,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: const SizedBox(),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top controls
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: TextButton(
                      onPressed: _finishOnboarding,
                      child: Text(
                        'Skip',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ),

                // Page Content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    children: const [
                      _OnboardingPage(
                        emoji: '🎭',
                        title: 'Discover Events\nAround You',
                        body: 'Find the best concerts, workshops, and meetups happening in your city.',
                      ),
                      _OnboardingPage(
                        emoji: '📅',
                        title: 'Today. This Weekend.\nAll Week.',
                        body: 'Never miss out. See exactly what is happening right now or plan ahead.',
                      ),
                      _OnboardingPage(
                        emoji: '🔖',
                        title: 'Post. Promote.\nEarn.',
                        body: 'Host your own events, reach a larger audience, and track your success.',
                      ),
                    ],
                  ),
                ),

                // Bottom Controls
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: [
                      SmoothPageIndicator(
                        controller: _pageController,
                        count: 3,
                        effect: const ExpandingDotsEffect(
                          dotHeight: 6,
                          dotWidth: 6,
                          expansionFactor: 3,
                          spacing: 8,
                          activeDotColor: AppColors.brandCoral,
                          dotColor: AppColors.glassBorder,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        width: double.infinity,
                        child: GradientButton(
                          label: isLastPage ? 'Get Started' : 'Next',
                          height: 56,
                          onTap: () {
                            if (isLastPage) {
                              _finishOnboarding();
                            } else {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOutCubic,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final String emoji;
  final String title;
  final String body;

  const _OnboardingPage({
    required this.emoji,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: AppSpacing.xl),
          Text(
            title,
            style: AppTextStyles.display.copyWith(
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            body,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
