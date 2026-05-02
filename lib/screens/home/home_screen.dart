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
import '../search/search_screen.dart';
import '../post_event/post_event_screen.dart';
import '../../services/event_post_service.dart';
import '../../models/post_event_form_data.dart';
import '../../providers/auth_provider.dart';
import '../../services/payment_service.dart';
import 'package:flutter/foundation.dart';

// lib/screens/home/home_screen.dart
// Full dark glassmorphism HomeScreen — KochiGo v3.1

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedDateFilter = 0; // 0=Today, 1=Weekend, 2=This Week
  String _selectedCategory = 'all';
  bool _promoDismissed = false;

  static const List<String> _dateFilters = ['Today', 'Weekend', 'This Week'];

  static const List<String> _categories = [
    'all', 'music', 'comedy', 'tech', 'fitness', 'art', 'workshop', 'food', 'business',
  ];

  @override
  Widget build(BuildContext context) {
    final filteredAsync = ref.watch(filteredEventsProvider);
    final isOffline = ref.watch(isOfflineProvider);
    final configAsync = ref.watch(appConfigProvider);

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

    final showPromo = !_promoDismissed &&
        (configAsync.valueOrNull?.showPromoBanner ?? false);

    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      body: RefreshIndicator(
        color: AppColors.brandCoral,
        backgroundColor: AppColors.backgroundCard,
        onRefresh: () => ref.refresh(eventsProvider.future),
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
                child: const Text(
                  'Vivra',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
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
                    SlideUpFadeRoute(page: const SearchScreen()),
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
                            ..eventDate = DateTime.now().add(const Duration(days: 1))
                            ..startTime = const TimeOfDay(hour: 18, minute: 0)
                            ..description = 'This is a debug test event with sufficient description length for validation testing purposes.'
                            ..location = 'Test Location, Kochi'
                            ..organizerName = 'Debug Tester'
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
                const SizedBox(width: 8),
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
                      const SizedBox(width: 8),
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
            if (showPromo)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                  child: _PromoBanner(
                    message: configAsync.valueOrNull?.promoBannerText ??
                        'Something exciting is coming!',
                    onDismiss: () => setState(() => _promoDismissed = true),
                  ),
                ),
              ),

            // ── Story Ring Avatars ──────────────────────────────────────
            SliverToBoxAdapter(
              child: filteredAsync.maybeWhen(
                data: (events) => _StoryRow(
                  events: events,
                  onAddTap: () => Navigator.push(
                    context,
                    SlideUpFadeRoute(page: const PostEventScreen()),
                  ),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ),

            // ── Date Filter Toggle ──────────────────────────────────────
            SliverToBoxAdapter(
              child: _DateFilterBar(
                selected: _selectedDateFilter,
                filters: _dateFilters,
                onSelect: (i) => setState(() => _selectedDateFilter = i),
              ),
            ),

            // ── Category Chips ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: _CategoryFilterBar(
                selected: _selectedCategory,
                categories: _categories,
                onSelect: (cat) => setState(() => _selectedCategory = cat),
              ),
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
                    Icon(Icons.tune_rounded,
                        size: 18, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),

            // ── Events List ─────────────────────────────────────────────
            filteredAsync.when(
              data: (events) {
                if (events.isEmpty) {
                  return const SliverFillRemaining(child: _EmptyState());
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

// ── Story Ring Row ────────────────────────────────────────────────────────────
class _StoryRow extends StatelessWidget {
  final List events;
  final VoidCallback onAddTap;

  const _StoryRow({required this.events, required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    // Unique posters from loaded events (up to 8)
    final posters = events
        .where((e) => e.postedByPhotoUrl != null && e.postedByPhotoUrl!.isNotEmpty)
        .take(8)
        .toList();

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
        itemCount: posters.length + 1, // +1 for the add button
        itemBuilder: (context, index) {
          if (index == 0) {
            // First item: "Post Event" add button
            return _StoryItem(
              onTap: onAddTap,
              label: 'Post',
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppColors.backgroundCard,
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: AppColors.glassBorder, width: 1.5),
                  ),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: AppColors.brandCoral,
                  size: 26,
                ),
              ),
            );
          }
          final event = posters[index - 1];
          return _StoryItem(
            onTap: () {},
            label: event.postedByName?.split(' ').first ?? 'User',
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.brandGradient,
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: event.postedByPhotoUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => const ColoredBox(
                      color: AppColors.backgroundSheet,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StoryItem extends StatelessWidget {
  final Widget child;
  final String label;
  final VoidCallback onTap;

  const _StoryItem({
    required this.child,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            child,
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Date Filter Bar ───────────────────────────────────────────────────────────
class _DateFilterBar extends StatelessWidget {
  final int selected;
  final List<String> filters;
  final ValueChanged<int> onSelect;

  const _DateFilterBar({
    required this.selected,
    required this.filters,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, 0, AppSpacing.md, AppSpacing.xs),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final isSelected = index == selected;
          return GestureDetector(
            onTap: () => onSelect(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.brandGradient : null,
                color: isSelected ? null : AppColors.glassSurface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: isSelected ? Colors.transparent : AppColors.glassBorder,
                ),
              ),
              child: Text(
                filters[index],
                style: AppTextStyles.label.copyWith(
                  color: isSelected
                      ? Colors.white
                      : AppColors.textSecondary,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Category Filter Bar ───────────────────────────────────────────────────────
class _CategoryFilterBar extends StatelessWidget {
  final String selected;
  final List<String> categories;
  final ValueChanged<String> onSelect;

  const _CategoryFilterBar({
    required this.selected,
    required this.categories,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat == selected;
          final gradient = cat == 'all'
              ? AppColors.brandGradient
              : (AppColors.categoryGradients[cat] ?? AppColors.brandGradient);

          return GestureDetector(
            onTap: () => onSelect(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: isSelected ? gradient : null,
                color: isSelected ? null : AppColors.glassSurface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: isSelected ? Colors.transparent : AppColors.glassBorder,
                ),
              ),
              child: Text(
                cat == 'all'
                    ? '✦ All'
                    : cat[0].toUpperCase() + cat.substring(1),
                style: AppTextStyles.label.copyWith(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Promo Banner ──────────────────────────────────────────────────────────────
class _PromoBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _PromoBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.brandCoral.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department_rounded,
              color: AppColors.brandCoral, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.label.copyWith(color: AppColors.brandCoral),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close_rounded,
                size: 16, color: AppColors.textTertiary),
          ),
        ],
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
          children: [
            const Text('🎭', style: TextStyle(fontSize: 64)),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'No Events Found',
              style: AppTextStyles.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Try adjusting your category or date filter.',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
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
            const Icon(Icons.cloud_off_rounded,
                size: 64, color: AppColors.textTertiary),
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
