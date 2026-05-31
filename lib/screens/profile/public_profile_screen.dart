import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/staggered_list.dart';
import '../../core/widgets/dark_shimmer.dart';
import '../../models/user_model.dart';
import '../../models/event_model.dart';
import '../../services/firestore_service.dart';
import '../home/widgets/event_card.dart';

class PublicProfileScreen extends ConsumerWidget {
  final String userId;
  const PublicProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<UserModel?>(
      future: FirestoreService.instance.getUserProfile(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _PublicProfileSkeleton();
        }
        
        final user = snapshot.data;
        if (user == null) {
          return Scaffold(
            backgroundColor: AppColors.backgroundBase,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off_rounded, size: 52, color: AppColors.textTertiary),
                  const SizedBox(height: AppSpacing.lg),
                  const Text('User Not Found', style: AppTextStyles.heading2),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'This profile may have been removed.',
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.backgroundBase,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context, user),
              _buildProfileHeader(user),
              _buildSectionTitle('Events by ${user.displayName}'),
              _buildUserEventsList(user.uid),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, UserModel user) {
    return SliverAppBar(
      expandedHeight: 0,
      pinned: true,
      title: Text(user.displayName, style: AppTextStyles.heading2),
      centerTitle: true,
      backgroundColor: AppColors.backgroundBase,
      elevation: 0,
      scrolledUnderElevation: 0,
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.brandCoral.withValues(alpha: 0.1),
              AppColors.backgroundBase,
            ],
          ),
        ),
        child: Column(
          children: [
            // Profile Photo with gradient ring
            Container(
              width: 84,
              height: 84,
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
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.person_rounded,
                              size: 40,
                              color: AppColors.textTertiary,
                            ),
                          )
                        : const Icon(Icons.person_rounded, size: 40, color: AppColors.textTertiary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(user.displayName, style: AppTextStyles.heading1.copyWith(color: Colors.white)),
                if (user.isVerifiedOrg) ...[
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(Icons.verified_rounded, color: AppColors.brandCoral, size: 20),
                ],
              ],
            ),
            if (user.bio != null && user.bio!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                user.bio!,
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatPill(label: 'Events', value: user.totalEventsPosted.toString()),
                const SizedBox(width: AppSpacing.sm),
                _StatPill(label: 'Followers', value: user.followersCount.toString()),
                const SizedBox(width: AppSpacing.sm),
                _StatPill(label: 'Following', value: user.followingCount.toString()),
              ],
            ),
            if (user.instagramHandle != null || user.website != null) ...[
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (user.instagramHandle != null)
                    _SocialChip(icon: Icons.camera_alt_rounded, label: user.instagramHandle!),
                  if (user.website != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    const _SocialChip(icon: Icons.language_rounded, label: 'Website'),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xl, AppSpacing.md, AppSpacing.md),
      sliver: SliverToBoxAdapter(
        child: Text(title, style: AppTextStyles.heading2),
      ),
    );
  }

  Widget _buildUserEventsList(String userId) {
    return StreamBuilder<List<EventModel>>(
      stream: FirestoreService.instance.getEventsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                children: List.generate(
                  2,
                  (_) => const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: DarkShimmer(width: double.infinity, height: 200, borderRadius: AppRadius.xl),
                  ),
                ),
              ),
            ),
          );
        }
        
        final events = snapshot.data!.where((e) => e.postedBy == userId).toList();
        
        if (events.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.event_note_rounded, size: 52, color: AppColors.textTertiary),
                    const SizedBox(height: AppSpacing.md),
                    const Text('No Active Events', style: AppTextStyles.heading2),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'This user hasn\'t posted any events yet.',
                      style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => StaggeredListItem(
              index: index,
              child: EventCard(event: events[index]),
            ),
            childCount: events.length,
          ),
        );
      },
    );
  }
}

class _SocialChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SocialChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textPrimary),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: AppTextStyles.label),
        ],
      ),
    );
  }
}

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

class _PublicProfileSkeleton extends StatelessWidget {
  const _PublicProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpacing.lg),
            const DarkShimmer(width: 84, height: 84, borderRadius: 42),
            const SizedBox(height: AppSpacing.md),
            const DarkShimmer(width: 140, height: 20),
            const SizedBox(height: AppSpacing.sm),
            const DarkShimmer(width: 200, height: 14),
            const SizedBox(height: AppSpacing.xl),
            const DarkShimmer(width: 120, height: 32, borderRadius: AppRadius.pill),
            const SizedBox(height: AppSpacing.xxl),
            const Align(
              alignment: Alignment.centerLeft,
              child: DarkShimmer(width: 150, height: 18),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ListView.builder(
                itemCount: 2,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.md),
                  child: DarkShimmer(width: double.infinity, height: 200, borderRadius: AppRadius.xl),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
