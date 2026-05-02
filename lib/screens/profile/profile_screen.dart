import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/tap_scale.dart';
import '../../core/auth_gate.dart';
import '../../providers/auth_provider.dart';
import '../../providers/events_provider.dart';
import '../../models/event_model.dart';
import '../../core/utils/date_utils.dart';
import '../detail/event_detail_screen.dart';
import 'edit_profile_screen.dart';

// lib/screens/profile/profile_screen.dart
// Dark glassmorphism Profile Screen — KochiGo v3.1

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthGate(
      reason: 'Sign in to view your profile and manage events.',
      child: Scaffold(
        backgroundColor: AppColors.backgroundBase,
        body: ref.watch(currentUserProfileProvider).when(
          data: (user) {
            if (user == null) {
              return const Center(child: Text('User profile not found.'));
            }
            return RefreshIndicator(
              color: AppColors.brandCoral,
              backgroundColor: AppColors.backgroundCard,
              onRefresh: () async {
                // Refresh profile data
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ── App Bar with Sign Out ───────────────────────────────
                  SliverAppBar(
                    backgroundColor: AppColors.backgroundBase,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    pinned: true,
                    actions: [
                      TextButton.icon(
                        onPressed: () => ref.read(authServiceProvider).signOut(),
                        icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
                        label: Text('Sign Out', style: AppTextStyles.label.copyWith(color: AppColors.error)),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                  ),

                  // ── Header Section ────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.brandCoral.withValues(alpha: 0.15),
                            AppColors.backgroundBase,
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: AppSpacing.md),
                          // Profile Photo (StoryRingAvatar style)
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 88,
                                height: 88,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppColors.brandGradient,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(2.5),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.backgroundBase,
                                    ),
                                    child: ClipOval(
                                      child: user.photoUrl != null
                                          ? CachedNetworkImage(
                                              imageUrl: user.photoUrl!,
                                              fit: BoxFit.cover,
                                              errorWidget: (_, __, ___) => const Icon(Icons.person_rounded, size: 40, color: AppColors.textTertiary),
                                            )
                                          : const Icon(Icons.person_rounded, size: 40, color: AppColors.textTertiary),
                                    ),
                                  ),
                                ),
                              ),
                              // Edit Overlay Badge
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.glassSurface,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.glassBorder),
                                ),
                                child: const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Name
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                user.displayName.isEmpty ? 'KochiGo User' : user.displayName,
                                style: AppTextStyles.heading1.copyWith(color: Colors.white),
                              ),
                              if (user.isVerifiedOrg) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.verified_rounded, color: AppColors.brandCoral, size: 20),
                              ],
                            ],
                          ),
                          
                          // Bio
                          if (user.bio != null && user.bio!.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                              child: Text(
                                user.bio!,
                                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.xl),

                          // Stats Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _StatPill(label: 'Events', value: user.totalEventsPosted.toString()),
                              const SizedBox(width: AppSpacing.sm),
                              _StatPill(label: 'Views', value: user.totalViews.toString()),
                              const SizedBox(width: AppSpacing.sm),
                              const _StatPill(label: 'Following', value: '124'), // Placeholder
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          // Edit Profile Button
                          TapScale(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                border: Border.all(color: AppColors.glassBorder),
                              ),
                              child: Text('Edit Profile', style: AppTextStyles.label.copyWith(color: Colors.white)),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                        ],
                      ),
                    ),
                  ),

                  // ── My Events Tabs ────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('My Events', style: AppTextStyles.heading2),
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            height: 48,
                            padding: const EdgeInsets.all(4),
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
                              labelStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
                              tabs: const [
                                Tab(text: 'Active'),
                                Tab(text: 'Pending'),
                                Tab(text: 'Expired'),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ),
                    ),
                  ),

                  // ── Tab Views ──────────────────────────────────────────────
                  SliverFillRemaining(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _EventsList(status: 'active', uid: user.uid),
                        _EventsList(status: 'under_review', uid: user.uid),
                        _EventsList(status: 'expired', uid: user.uid, isExpired: true),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.brandCoral)),
          error: (e, _) => Center(child: Text('Error loading profile: $e', style: AppTextStyles.body.copyWith(color: AppColors.error))),
        ),
      ),
    );
  }
}

// ── Stat Pill ─────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: AppTextStyles.heading3.copyWith(color: Colors.white)),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ── Events List ───────────────────────────────────────────────────────────────

class _EventsList extends ConsumerWidget {
  final String status;
  final String uid;
  final bool isExpired;

  const _EventsList({required this.status, required this.uid, this.isExpired = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For now, filtering the main events provider
    final eventsAsync = ref.watch(eventsProvider);

    return eventsAsync.when(
      data: (allEvents) {
        final filtered = allEvents.where((e) {
          // Adjust this logic if 'under_review' is considered isActive=false, etc.
          // Fallback simple filter based on basic logic if status field is missing
          if (isExpired) return e.postedBy == uid && e.status == 'expired';
          if (status == 'active') return e.postedBy == uid && (e.status == 'active' || e.isActive);
          return e.postedBy == uid && e.status == status;
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Text(
              'No $status events.',
              style: AppTextStyles.body.copyWith(color: AppColors.textTertiary),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            return _MiniEventCard(event: filtered[index], isExpired: isExpired);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.brandCoral)),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ── Mini Event Card ───────────────────────────────────────────────────────────

class _MiniEventCard extends StatelessWidget {
  final EventModel event;
  final bool isExpired;

  const _MiniEventCard({required this.event, required this.isExpired});

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: event))),
      child: Container(
        height: 120,
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppRadius.lg)),
              child: CachedNetworkImage(
                imageUrl: event.imageUrl,
                width: 110,
                height: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => const ColoredBox(color: AppColors.backgroundSheet),
                errorWidget: (_, __, ___) => const ColoredBox(color: AppColors.backgroundSheet),
              ),
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: AppTextStyles.label.copyWith(color: Colors.white),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppDateUtils.formatCardDate(event.date),
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.visibility_rounded, size: 12, color: AppColors.textTertiary),
                            const SizedBox(width: 4),
                            Text('${event.totalViews}', style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
                          ],
                        ),
                        if (isExpired)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: AppColors.brandGradient,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              'Re-boost',
                              style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
