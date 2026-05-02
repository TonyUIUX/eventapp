import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/event_model.dart';
import '../../providers/saved_events_provider.dart';
import '../../providers/events_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/rating_service.dart';
import '../../services/personalization_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/url_utils.dart';
import '../../core/widgets/tap_scale.dart';
import '../../core/widgets/gradient_button.dart';

// lib/screens/detail/event_detail_screen.dart
// Dark glassmorphism detail screen — KochiGo v3.1

class EventDetailScreen extends ConsumerWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSaved = ref.watch(savedEventIdsProvider).contains(event.id);
    final user = ref.watch(authStateProvider).value;
    final isOwner = user != null && event.postedBy != null && user.uid == event.postedBy;

    // Analytics (only track once, but this is simple)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.instance.logEventView(event.id, event.title);
      RatingService.trackDetailView();
      PersonalizationService.instance.logCategoryView(event.category);
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero App Bar ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.width * (9 / 16), // 16:9 ratio
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: AppColors.backgroundBase,
            leading: Center(
              child: _GlassHeaderAction(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.pop(context),
              ),
            ),
            actions: [
              if (isOwner)
                _GlassHeaderAction(
                  icon: Icons.edit_rounded,
                  onTap: () {
                    // Navigate to Edit
                  },
                ),
              const SizedBox(width: 8),
              _GlassHeaderAction(
                icon: Icons.share_rounded,
                onTap: () => _handleShare(event),
              ),
              const SizedBox(width: 8),
              _GlassHeaderOverflow(isOwner: isOwner),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'event_image_${event.id}',
                    child: CachedNetworkImage(
                      imageUrl: event.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const ColoredBox(color: AppColors.backgroundCard),
                      errorWidget: (context, url, error) => const ColoredBox(color: AppColors.backgroundSheet),
                    ),
                  ),
                  // Bottom 40% gradient overlay
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, AppColors.backgroundBase],
                          stops: [0.6, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Main Content ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges Row
                  Row(
                    children: [
                      _CategoryBadge(category: event.category),
                      if (event.isFeatured) ...[
                        const SizedBox(width: 8),
                        const _FeaturedChip(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    event.title,
                    style: AppTextStyles.heading1.copyWith(color: Colors.white, height: 1.2),
                  ),
                  const SizedBox(height: 16),

                  // Organizer Row
                  _OrganizerRow(event: event),
                  const SizedBox(height: 24),

                  // Date & Location Chips
                  Row(
                    children: [
                      Expanded(
                        child: _InfoChip(
                          icon: Icons.calendar_today_rounded,
                          iconColor: AppColors.brandCoral,
                          text: AppDateUtils.formatDetailDate(event.date),
                          onTap: () => AppUrlUtils.addToGoogleCalendar(
                            title: event.title,
                            description: event.description,
                            location: event.location,
                            startDate: event.date,
                            context: context,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoChip(
                          icon: Icons.location_on_rounded,
                          iconColor: AppColors.textTertiary,
                          text: event.location,
                          onTap: () {
                            AnalyticsService.instance.logMapTap(event.id);
                            AppUrlUtils.openUrl(event.mapLink, context);
                          },
                        ),
                      ),
                    ],
                  ),

                  // Booking CTA
                  if (event.ticketLink != null || event.registrationLink != null) ...[
                    const SizedBox(height: 24),
                    _BookingCTA(event: event),
                  ],

                  // Divider
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Divider(color: AppColors.glassBorder, height: 1),
                  ),

                  // About Section
                  Text('About', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text(
                    event.description,
                    style: AppTextStyles.body.copyWith(color: Colors.white, height: 1.6),
                  ),

                  // Tags
                  if (event.tags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: event.tags.map((tag) => _TagChip(tag: tag)).toList(),
                    ),
                  ],

                  // Divider
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Divider(color: AppColors.glassBorder, height: 1),
                  ),

                  // More from Organizer
                  if (event.postedBy != null) ...[
                    _MoreFromOrganizer(organizerId: event.postedBy!, currentEventId: event.id),
                    const SizedBox(height: 32),
                  ],

                  const SizedBox(height: 80), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Sticky Bottom Bar ───────────────────────────────────────────
      bottomNavigationBar: _StickyBottomBar(event: event, isSaved: isSaved),
    );
  }

  void _handleShare(EventModel event) {
    AnalyticsService.instance.logShare(event.id, event.title);
    Share.share(
      '🎉 ${event.title}\n📅 ${AppDateUtils.formatDetailDate(event.date)}\n📍 ${event.location}\n\nDiscover more on Vivra!',
      subject: event.title,
    );
  }
}

// ── Header Actions ────────────────────────────────────────────────────────────

class _GlassHeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassHeaderAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.glassSurface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}

class _GlassHeaderOverflow extends StatelessWidget {
  final bool isOwner;
  const _GlassHeaderOverflow({required this.isOwner});

  @override
  Widget build(BuildContext context) {
    return TapScale(
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.glassSurface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, size: 18, color: Colors.white),
          color: AppColors.backgroundCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: const BorderSide(color: AppColors.glassBorder),
          ),
          onSelected: (value) {
            if (value == 'report') {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('Report submitted.', style: TextStyle(color: Colors.white)),
                backgroundColor: AppColors.backgroundCard,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.glassBorder)),
              ));
            }
          },
          itemBuilder: (context) => [
            if (!isOwner)
              PopupMenuItem(
                value: 'report',
                child: Text('Report Event', style: AppTextStyles.body.copyWith(color: AppColors.error)),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Badges ────────────────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    final gradient = AppColors.categoryGradients[category.toLowerCase()] ?? AppColors.brandGradient;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        category.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _FeaturedChip extends StatelessWidget {
  const _FeaturedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.brandCoral.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 11, color: AppColors.brandCoral),
          const SizedBox(width: 4),
          Text(
            'FEATURED',
            style: AppTextStyles.caption.copyWith(color: AppColors.brandCoral, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String tag;
  const _TagChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Text('#$tag', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
    );
  }
}

// ── Organizer Row ─────────────────────────────────────────────────────────────

class _OrganizerRow extends StatelessWidget {
  final EventModel event;
  const _OrganizerRow({required this.event});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.brandGradient,
          ),
          child: Padding(
            padding: const EdgeInsets.all(1.5),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: event.postedByPhotoUrl ?? '',
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const ColoredBox(
                  color: AppColors.backgroundCard,
                  child: Icon(Icons.person_rounded, color: AppColors.textTertiary, size: 20),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Organized by', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
            Row(
              children: [
                Text(
                  event.postedByName ?? event.organizer,
                  style: AppTextStyles.label.copyWith(color: Colors.white),
                ),
                if (event.isVerifiedOrg) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.verified_rounded, color: AppColors.success, size: 14),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ── Info Chip ─────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  final VoidCallback onTap;

  const _InfoChip({
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.glassSurface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.caption.copyWith(color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Booking CTA ───────────────────────────────────────────────────────────────

class _BookingCTA extends StatelessWidget {
  final EventModel event;
  const _BookingCTA({required this.event});

  @override
  Widget build(BuildContext context) {
    final bool hasTicket = event.ticketLink != null && event.ticketLink!.isNotEmpty;
    final String url = hasTicket ? event.ticketLink! : event.registrationLink!;
    final String label = hasTicket ? 'Get Tickets' : 'Register Now';

    return TapScale(
      onTap: () {
        AnalyticsService.instance.logBookingTap(event.id, hasTicket ? 'tickets' : 'registration');
        AppUrlUtils.openUrl(url, context);
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A2D3A), AppColors.backgroundCard],
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.glassBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.local_activity_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.heading3.copyWith(color: Colors.white)),
                  Text(
                    'Secure your spot for this experience.',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textTertiary, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── More from Organizer ───────────────────────────────────────────────────────

class _MoreFromOrganizer extends ConsumerWidget {
  final String organizerId;
  final String currentEventId;

  const _MoreFromOrganizer({required this.organizerId, required this.currentEventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(relatedEventsProvider(currentEventId));

    return eventsAsync.when(
      data: (events) {
        final organizerEvents = events.where((e) => e.postedBy == organizerId && e.id != currentEventId).toList();
        if (organizerEvents.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('More from this Organizer', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: organizerEvents.length,
                itemBuilder: (context, index) {
                  final e = organizerEvents[index];
                  return TapScale(
                    onTap: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: e)));
                    },
                    child: Container(
                      width: 240,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundCard,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppRadius.lg)),
                            child: CachedNetworkImage(
                              imageUrl: e.imageUrl,
                              width: 100,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    e.title,
                                    style: AppTextStyles.label.copyWith(color: Colors.white),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppDateUtils.formatCardDate(e.date),
                                    style: AppTextStyles.caption.copyWith(color: AppColors.brandCoral),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ── Sticky Bottom Bar ─────────────────────────────────────────────────────────

class _StickyBottomBar extends ConsumerWidget {
  final EventModel event;
  final bool isSaved;

  const _StickyBottomBar({required this.event, required this.isSaved});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, MediaQuery.of(context).padding.bottom + AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard.withValues(alpha: 0.95),
        border: const Border(top: BorderSide(color: AppColors.glassBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TapScale(
              onTap: () {
                ref.read(savedEventIdsProvider.notifier).toggle(event.id);
                AnalyticsService.instance.logEventSaved(event.id, saved: !isSaved);
              },
              child: isSaved
                  ? Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.glassSurface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.brandCoral),
                      ),
                      alignment: Alignment.center,
                      child: Text('Saved', style: AppTextStyles.label.copyWith(color: AppColors.brandCoral)),
                    )
                  : GradientButton(
                      label: 'Save Event',
                      onTap: () {}, // Tap is handled by TapScale
                      height: 48,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
