import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/event_model.dart';
import '../../../providers/events_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/app_router.dart';
import '../../../core/widgets/tap_scale.dart';
import '../../../core/widgets/dark_shimmer.dart';
import '../../../services/analytics_service.dart';
import '../../detail/event_detail_screen.dart';

// lib/screens/home/widgets/featured_carousel.dart
// Dark glassmorphism featured carousel — KochiGo v3.1

class FeaturedCarousel extends ConsumerStatefulWidget {
  const FeaturedCarousel({super.key});

  @override
  ConsumerState<FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends ConsumerState<FeaturedCarousel> {
  late final PageController _controller;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.88);
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _advance());
  }

  void _advance() {
    if (!mounted) return;
    final events = ref.read(featuredEventsProvider).valueOrNull;
    if (events == null || events.length <= 1) return;
    final next = (_currentPage + 1) % events.length;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final featuredAsync = ref.watch(featuredEventsProvider);

    return featuredAsync.when(
      data: (events) {
        if (events.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Featured', style: AppTextStyles.heading2),
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppColors.brandGradient.createShader(bounds),
                    blendMode: BlendMode.srcIn,
                    child: Text(
                      'View all',
                      style: AppTextStyles.label.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            // Carousel
            SizedBox(
              height: 230,
              child: PageView.builder(
                controller: _controller,
                itemCount: events.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) => _CarouselCard(
                  event: events[index],
                  onTap: () {
                    AnalyticsService.instance
                        .logEventView(events[index].id, events[index].title);
                    Navigator.push(
                      context,
                      SlideUpFadeRoute(
                          page: EventDetailScreen(event: events[index])),
                    );
                  },
                ),
              ),
            ),

            // Dot indicators
            if (events.length > 1) ...[
              const SizedBox(height: AppSpacing.md),
              _DotsIndicator(
                count: events.length,
                current: _currentPage,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: DarkShimmer(
          width: double.infinity,
          height: 230,
          borderRadius: AppRadius.xl,
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ── Carousel Card ─────────────────────────────────────────────────────────────
class _CarouselCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;

  const _CarouselCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gradient =
        AppColors.categoryGradients[event.category.toLowerCase()] ??
            AppColors.brandGradient;

    return TapScale(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: const [
            BoxShadow(
              color: AppColors.glowCoral,
              blurRadius: 20,
              spreadRadius: -6,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Full background image
              CachedNetworkImage(
                imageUrl: event.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const ColoredBox(
                  color: AppColors.backgroundCard,
                ),
                errorWidget: (context, url, error) => const ColoredBox(
                  color: AppColors.backgroundSheet,
                ),
              ),

              // Dark gradient overlay — title reads clearly
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                    stops: [0.3, 1.0],
                  ),
                ),
              ),

              // Content — bottom-left
              Positioned(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.md,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Category gradient pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius:
                            BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        event.category.toUpperCase(),
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Event title
                    Text(
                      event.title,
                      style: AppTextStyles.heading2.copyWith(
                        color: Colors.white,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Date + location row
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 11,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          AppDateUtils.formatCardDate(event.date),
                          style: AppTextStyles.caption
                              .copyWith(color: Colors.white70),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        const Icon(
                          Icons.location_on_outlined,
                          size: 11,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location,
                            style: AppTextStyles.caption
                                .copyWith(color: Colors.white70),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Featured badge — top right
              if (event.isFeatured)
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded,
                            size: 11, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'FEATURED',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Animated Dot Indicators ───────────────────────────────────────────────────
class _DotsIndicator extends StatelessWidget {
  final int count;
  final int current;

  const _DotsIndicator({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 22 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? AppColors.brandCoral : AppColors.glassBorder,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        );
      }),
    );
  }
}
