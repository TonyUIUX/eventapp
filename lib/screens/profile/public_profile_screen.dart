import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
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
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.brandCoral)));
        }
        
        final user = snapshot.data;
        if (user == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('User not found')),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
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
      backgroundColor: AppColors.surface,
      elevation: 0,
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        color: AppColors.surface,
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.surfaceAlt,
              backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
              child: user.photoUrl == null ? const Icon(Icons.person, size: 40) : null,
            ),
            const SizedBox(height: 16),
            Text(user.displayName, style: AppTextStyles.heading2),
            if (user.bio != null && user.bio!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                user.bio!,
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (user.instagramHandle != null) _SocialChip(icon: Icons.camera_alt, label: user.instagramHandle!),
                if (user.website != null) ...[
                  const SizedBox(width: 12),
                  const _SocialChip(icon: Icons.language, label: 'Website'),
                ],
              ],
            ),
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
      stream: FirestoreService.instance.getEventsStream(), // Filtered in UI for simplicity
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: AppColors.brandCoral)));
        
        final events = snapshot.data!.where((e) => e.postedBy == userId || (e as dynamic).userId == userId).toList();
        
        if (events.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Center(child: Text('No active events yet')),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => EventCard(
              event: events[index],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textPrimary),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.labelMedium),
        ],
      ),
    );
  }
}
