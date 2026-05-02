# ✨ Animation Spec & Component Redesign — v3.1 UI

> Every animation has ONE job: make the user feel the app is alive.
> NO animation should exceed 400ms. NO animation should block interaction.
> Use curves: easeOutCubic for entrances, easeInCubic for exits.

---

## Animation Philosophy

```
Rule 1: Entrance = slide UP + fade in   (300ms, easeOutCubic)
Rule 2: Exit    = fade out              (200ms, easeInCubic)
Rule 3: Tap     = scale down to 0.95   (100ms) → scale back (150ms easeOutBack)
Rule 4: Scroll  = staggered list items (50ms delay per item, max 6 items)
Rule 5: Loading = shimmer (always) + skeleton shape matching real content
Rule 6: Success = scale up 1.0→1.15→1.0 with glow pulse
```

---

## 1. Page Transitions

### Route to route transition
```dart
// lib/core/utils/app_router.dart

// Custom page transition — slide up + fade
class SlideUpFadeRoute extends PageRouteBuilder {
  final Widget page;
  SlideUpFadeRoute({required this.page})
    : super(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (_, animation, __, child) {
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ));
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
      );
}

// Use for: PostEventScreen, EventDetailScreen, AuthScreen
Navigator.push(context, SlideUpFadeRoute(page: EventDetailScreen(event: event)));
```

### Hero transition for event images
```dart
// event_card.dart → event_detail_screen.dart
// Wrap EventCard image AND detail screen image in Hero with SAME tag

// In card:
Hero(
  tag: 'event_image_${event.id}',
  child: CachedNetworkImage(...),
)

// In detail:
Hero(
  tag: 'event_image_${event.id}',
  child: CachedNetworkImage(...),
)

// Hero creates automatic smooth shared-element transition
```

---

## 2. Staggered List Animation

```dart
// lib/core/widgets/staggered_list.dart
// Use this for ALL lists in the app (events, notifications, search results)

class StaggeredListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final int maxStagger; // after this index, no delay

  @override
  State<StaggeredListItem> createState() => _StaggeredListItemState();
}

class _StaggeredListItemState extends State<StaggeredListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    final delay = widget.index < widget.maxStagger
        ? Duration(milliseconds: widget.index * 60)
        : Duration.zero;

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.7,
        curve: Curves.easeOut)),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller,
      curve: Curves.easeOutCubic));

    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// Usage in ListView.builder:
ListView.builder(
  itemBuilder: (_, index) => StaggeredListItem(
    index: index,
    maxStagger: 6,  // Only first 6 items animate
    child: EventCard(event: events[index]),
  ),
)
```

---

## 3. Tap / Press Animation (TapScale)

```dart
// lib/core/widgets/tap_scale.dart
// Wrap ANY tappable widget with this for physical press feel

class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;

  const TapScale({
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.94,
    super.key,
  });

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: widget.scale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

// Usage:
TapScale(
  onTap: () => Navigator.push(...),
  child: EventCard(event: event),
)
```

---

## 4. Dark Shimmer Loading

```dart
// lib/core/widgets/dark_shimmer.dart
// Dark-mode-aware shimmer. Replace all existing shimmer usages.

class DarkShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const DarkShimmer({
    required this.width,
    required this.height,
    this.borderRadius = AppRadius.sm,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1E1E2E),
      highlightColor: const Color(0xFF2E2E42),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

// Event Card Skeleton:
class EventCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(children: [
        DarkShimmer(width: double.infinity, height: 160, borderRadius: AppRadius.md),
        const SizedBox(height: 12),
        DarkShimmer(width: double.infinity, height: 18),
        const SizedBox(height: 8),
        DarkShimmer(width: 140, height: 13),
        const SizedBox(height: 6),
        DarkShimmer(width: 100, height: 13),
      ]),
    );
  }
}
```

---

## 5. Story Ring Avatar (HomeScreen Top)

```dart
// lib/core/widgets/story_ring_avatar.dart
// Like the reference image — circular avatar with gradient ring

class StoryRingAvatar extends StatelessWidget {
  final String? imageUrl;
  final String label;
  final bool hasNew;         // Gradient ring when unseen
  final bool isAddButton;    // First item: "Your Story" + button
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: size + 4,
            height: size + 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasNew
                ? AppColors.brandGradient
                : const LinearGradient(
                    colors: [AppColors.textTertiary, AppColors.textTertiary]),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2.5),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.backgroundBase,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: isAddButton
                    ? Container(
                        color: AppColors.backgroundCard,
                        child: const Icon(Icons.add_rounded,
                          color: AppColors.brandCoral, size: 28),
                      )
                    : CachedNetworkImage(
                        imageUrl: imageUrl ?? '',
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.backgroundCard,
                          child: const Icon(Icons.person_rounded,
                            color: AppColors.textTertiary),
                        ),
                      ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: hasNew ? AppColors.textPrimary : AppColors.textTertiary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
```

---

## 6. New Event Card (Dark Glassmorphism)

```dart
// lib/screens/home/widgets/event_card.dart — FULL REDESIGN

class EventCard extends StatelessWidget {
  final EventModel event;

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: () => Navigator.push(context,
        SlideUpFadeRoute(page: EventDetailScreen(event: event))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          color: AppColors.backgroundCard,
          border: Border.all(color: AppColors.glassBorder),
          boxShadow: [
            BoxShadow(
              color: AppColors.backgroundDeep.withValues(alpha: 0.6),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with gradient overlay
            Stack(
              children: [
                Hero(
                  tag: 'event_image_${event.id}',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.xl)),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: CachedNetworkImage(
                        imageUrl: event.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => DarkShimmer(
                          width: double.infinity, height: 200,
                          borderRadius: AppRadius.xl,
                        ),
                      ),
                    ),
                  ),
                ),
                // Bottom gradient fade on image
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.backgroundCard.withValues(alpha: 0.95),
                        ],
                      ),
                    ),
                  ),
                ),
                // Category badge (gradient pill, top-left)
                Positioned(
                  top: 12, left: 12,
                  child: _CategoryBadge(category: event.category),
                ),
                // Price badge (top-right)
                Positioned(
                  top: 12, right: 12,
                  child: _PriceBadge(price: event.price),
                ),
                // Featured glow border
                if (event.isFeatured)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppRadius.xl)),
                        border: Border.all(
                          color: AppColors.brandCoral.withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Content area
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title,
                    style: AppTextStyles.heading3,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.calendar_today_rounded,
                      size: 12, color: AppColors.brandCoral),
                    const SizedBox(width: 5),
                    Text(DateUtils.formatCardDate(event.date),
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.brandCoral)),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                      size: 12, color: AppColors.textTertiary),
                    const SizedBox(width: 5),
                    Expanded(child: Text(event.location,
                      style: AppTextStyles.label,
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                  // Tags row
                  if (event.tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(spacing: 6, children: event.tags.take(2).map(
                      (tag) => _TagChip(tag: tag)).toList()),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String category;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: AppColors.categoryGradients[category] ?? AppColors.brandGradient,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 8,
        )],
      ),
      child: Text(category.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          color: Colors.white, letterSpacing: 1.0, fontWeight: FontWeight.w700)),
    );
  }
}
```

---

## 7. Gradient App Bar

```dart
// lib/core/widgets/gradient_app_bar.dart

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showGradientTitle; // gradient text on title

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: showGradientTitle
        ? ShaderMask(
            shaderCallback: (bounds) =>
              AppColors.brandGradient.createShader(bounds),
            child: Text(title,
              style: AppTextStyles.heading1.copyWith(color: Colors.white)),
          )
        : Text(title, style: AppTextStyles.heading2),
      actions: actions,
    );
  }
}
```

---

## 8. Booking CTA Card (Updated Dark Style)

```dart
// On EventDetailScreen — booking CTA
// Replaces the old coral card with glassmorphism + gradient

GlassCard(
  glowColor: AppColors.glowCoral,
  gradient: AppColors.brandGradient,
  padding: const EdgeInsets.all(16),
  child: Row(children: [
    Expanded(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          event.price == 'Free' ? 'FREE EVENT' : event.price ?? '',
          style: AppTextStyles.caption.copyWith(
            color: Colors.white70, letterSpacing: 1.2),
        ),
        const SizedBox(height: 4),
        Text(
          event.price == 'Free' ? 'Register Now' : 'Book Tickets',
          style: AppTextStyles.heading2.copyWith(color: Colors.white),
        ),
      ],
    )),
    TapScale(
      onTap: () => openUrl(event.ticketLink ?? event.registrationLink!),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          event.price == 'Free' ? 'Register' : 'Book Now',
          style: AppTextStyles.buttonSmall.copyWith(color: AppColors.brandCoral),
        ),
      ),
    ),
  ]),
)
```

---

## 9. Onboarding Screens (Dark)

```dart
// lib/screens/onboarding/ — 3 pages, dark glassmorphism

// Page design pattern:
// - Full dark bg with gradient blob in background (blurred circle)
// - Large emoji or Lottie animation centered
// - White bold heading
// - Grey body text
// - Bottom: dot indicators + Next/Get Started button

// Background gradient blob:
Positioned(
  top: -100, right: -100,
  child: Container(
    width: 300, height: 300,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: AppColors.brandGradient,
    ),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
      child: const SizedBox(),
    ),
  ),
)
```
