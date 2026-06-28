import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/events_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/app_config_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/app_router.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/dark_shimmer.dart';
import '../../core/widgets/staggered_list.dart';
import 'widgets/event_card.dart';
import 'widgets/featured_carousel.dart';
import 'widgets/category_filter_bar.dart';
import 'widgets/date_toggle.dart';
import 'widgets/promo_banner.dart';
import '../search/search_screen.dart';
import '../../services/event_post_service.dart';
import '../../models/post_event_form_data.dart';
import '../../services/payment_service.dart';
import 'package:flutter/foundation.dart';

// lib/screens/home/home_screen.dart
// Full dark glassmorphism HomeScreen — Evorra v3.1

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final filteredAsync = ref.watch(filteredEventsProvider);
    final isOffline = ref.watch(isOfflineProvider);

    // Preload featured images
    ref.listen(featuredEventsProvider, (_, next) {
      next.whenData((events) {
        for (final event in events.take(3)) {
          if (event.imageUrl.isNotEmpty) {
            precacheImage(CachedNetworkImageProvider(event.imageUrl), context);
          }
        }
      });
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      body: RefreshIndicator(
        color: AppColors.brandCoral,
        backgroundColor: AppColors.backgroundCard,
        onRefresh: () async {
                  ref.invalidate(eventsProvider);
                  // Wait for the stream to emit fresh data — not a fixed delay
                  try {
                    await ref.read(eventsProvider.future);
                  } catch (_) {
                    // Ignore errors during refresh (network offline etc.)
                  }
                },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [

            // ── Gradient App Bar ────────────────────────────────────────
            SliverAppBar(
              floating: true,
              pinned: true,
              backgroundColor: AppColors.backgroundBase,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false,
              title: ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.brandGradient.createShader(bounds),
                blendMode: BlendMode.srcIn,
                child: Text(
                  'Evorra',
                  style: AppTextStyles.display.copyWith(
                    fontSize: 26,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.glassSurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    SlideUpFadeRoute(page: const SearchScreen(isTab: false)),
                  ),
                ),
                if (kDebugMode) ...[
                  IconButton(
                    icon: const Icon(Icons.bug_report, color: Colors.greenAccent),
                    onPressed: () async {
                      final config = ref.read(appConfigProvider).valueOrNull;
                      if (config == null) { debugPrint('Config not loaded'); return; }
                      
                      try {
                        final eventId = await EventPostService.instance.createPendingEvent(
                          eventData: (PostEventFormData()
                            ..title = 'DEBUG TEST EVENT ${DateTime.now().millisecondsSinceEpoch}'
                            ..category = 'tech'
                            ..date = DateTime.now().add(const Duration(days: 1))
                            ..description = 'This is a debug test event with sufficient description length for validation testing purposes.'
                            ..location = 'Test Location, Kochi'
                            ..organizer = 'Debug Tester'
                            ..entryType = 'free'
                            ..price = 'Free')
                            .toMap(),
                          eventDurationDays: config.eventDurationDays,
                          imageUrls: [],
                        );
                        debugPrint('✅ Event submitted! ID: $eventId');
                        debugPrint('Check Firestore → events → $eventId');
                      } catch (e) {
                        debugPrint('❌ Submission failed: $e');
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.payment, color: Colors.yellowAccent),
                    onPressed: () {
                      PaymentService.instance.startPayment(
                        amountPaise: 100,  // ₹1 in paise for minimum test
                        contactPhone: '9999999999',
                        onSuccess: (paymentId) {
                          debugPrint('✅ RAZORPAY SUCCESS: $paymentId');
                        },
                        onError: (error) {
                          debugPrint('❌ RAZORPAY FAILURE: $error');
                        },
                      );
                    },
                  ),
                ],
                const SizedBox(width: AppSpacing.sm),
              ],
            ),

            // ── Offline Banner ──────────────────────────────────────────
            if (isOffline)
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  color: AppColors.warning.withValues(alpha: 0.15),
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs, horizontal: AppSpacing.md),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off_rounded,
                          size: 14, color: AppColors.warning),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Offline • Showing cached events',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Promo Banner ────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: PromoBanner(),
            ),

            // ── Date Filter Toggle ──────────────────────────────────────
            const SliverToBoxAdapter(
              child: DateToggle(),
            ),

            // ── Category Chips ──────────────────────────────────────────
            const SliverToBoxAdapter(
              child: CategoryFilterBar(),
            ),

            // ── Featured Carousel ───────────────────────────────────────
            const SliverToBoxAdapter(child: FeaturedCarousel()),

            // ── Section Header ──────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Discover Events', style: AppTextStyles.heading2),
                  ],
                ),
              ),
            ),

            // ── Events List ─────────────────────────────────────────────
            filteredAsync.when(
              data: (events) {
                if (events.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => StaggeredListItem(
                      index: index,
                      maxStagger: 6,
                      child: EventCard(event: events[index]),
                    ),
                    childCount: events.length,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: _LoadingState(),
              ),
              error: (e, _) => SliverFillRemaining(
                child: _ErrorState(
                    onRetry: () => ref.invalidate(eventsProvider)),
              ),
            ),

            // ── Bottom Spacing ──────────────────────────────────────────
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.xxl),
            ),
          ],
        ),
      ),
    );
  }
}



// ── Loading State ─────────────────────────────────────────────────────────────
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                color: AppColors.backgroundCard,
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const Column(
                children: [
                  DarkShimmer(
                    width: double.infinity,
                    height: 180,
                    borderRadius: AppRadius.xl,
                  ),
                  Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DarkShimmer(width: double.infinity, height: 18),
                        SizedBox(height: AppSpacing.sm),
                        DarkShimmer(width: 160, height: 13),
                        SizedBox(height: AppSpacing.xs),
                        DarkShimmer(width: 120, height: 13),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_busy_rounded, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'No Events Found',
              style: AppTextStyles.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Flexible(
              child: Text(
                'Try adjusting your category or date filter.',
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error State ───────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.lg),
            const Text('Connection Issue', style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'We couldn\'t load events.\nCheck your connection and try again.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            GradientButton(
              label: 'Try Again',
              onTap: onRetry,
              height: 48,
            ),
          ],
        ),
      ),
    );
  }
}
