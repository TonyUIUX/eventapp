import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/events_provider.dart';
import '../../services/analytics_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/staggered_list.dart';
import '../../core/widgets/tap_scale.dart';
import '../../core/widgets/gradient_button.dart';
import '../home/widgets/event_card.dart';

// lib/screens/search/search_screen.dart
// Dark glassmorphism search screen — KochiGo v3.1

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  // Placeholder for recent searches
  final List<String> _recentSearches = ['Music Festival', 'Tech Meetup', 'Art'];

  final List<Map<String, String>> _categories = [
    {'cat': 'music', 'emoji': '🎵', 'label': 'Music'},
    {'cat': 'comedy', 'emoji': '😂', 'label': 'Comedy'},
    {'cat': 'tech', 'emoji': '💻', 'label': 'Tech'},
    {'cat': 'fitness', 'emoji': '🏃', 'label': 'Fitness'},
    {'cat': 'art', 'emoji': '🎨', 'label': 'Art'},
    {'cat': 'food', 'emoji': '🍔', 'label': 'Food'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    ref.read(searchQueryProvider.notifier).state = '';
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _removeRecentSearch(String search) {
    setState(() {
      _recentSearches.remove(search);
    });
  }

  void _onCategoryTap(String category) {
    _controller.text = category;
    ref.read(searchQueryProvider.notifier).state = category;
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);

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
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: AppSpacing.md),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.glassSurface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.search_rounded, color: AppColors.textTertiary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
                    style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Events, places, tags...',
                      hintStyle: AppTextStyles.body.copyWith(color: AppColors.textTertiary),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (query.isNotEmpty)
                  TapScale(
                    onTap: () {
                      _controller.clear();
                      ref.read(searchQueryProvider.notifier).state = '';
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 18),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: query.isEmpty
          ? _SearchPrompt(
              recentSearches: _recentSearches,
              categories: _categories,
              onRemoveRecent: _removeRecentSearch,
              onCategoryTap: _onCategoryTap,
            )
          : resultsAsync.when(
              data: (events) {
                if (events.isNotEmpty) {
                  AnalyticsService.instance.logSearch(query, events.length);
                }
                if (events.isEmpty) {
                  return _NoResults(query: query);
                }
                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text(
                          '${events.length} events found',
                          style: AppTextStyles.label.copyWith(color: AppColors.brandCoral),
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return StaggeredListItem(
                            index: index,
                            maxStagger: 8,
                            child: EventCard(event: events[index]),
                          );
                        },
                        childCount: events.length,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.brandCoral),
              ),
              error: (_, __) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('😵', style: TextStyle(fontSize: 52)),
                      const SizedBox(height: AppSpacing.lg),
                      const Text('Search Unavailable', style: AppTextStyles.heading3),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'We couldn\'t load results right now.\nCheck your connection and try again.',
                        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      GradientButton(
                        label: 'Try Again',
                        onTap: () => ref.invalidate(eventsProvider),
                        height: 48,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

// ── Empty State Prompt ────────────────────────────────────────────────────────
class _SearchPrompt extends StatelessWidget {
  final List<String> recentSearches;
  final List<Map<String, String>> categories;
  final ValueChanged<String> onRemoveRecent;
  final ValueChanged<String> onCategoryTap;

  const _SearchPrompt({
    required this.recentSearches,
    required this.categories,
    required this.onRemoveRecent,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recentSearches.isNotEmpty) ...[
            Text('Recent Searches', style: AppTextStyles.heading3.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recentSearches.map((search) {
                return TapScale(
                  onTap: () => onCategoryTap(search),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.glassSurface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.history_rounded, size: 14, color: AppColors.textTertiary),
                        const SizedBox(width: 6),
                        Text(search, style: AppTextStyles.label),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => onRemoveRecent(search),
                          child: const Icon(Icons.close_rounded, size: 14, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          Text('Browse by Category', style: AppTextStyles.heading3.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final gradient = AppColors.categoryGradients[cat['cat']] ?? AppColors.brandGradient;
              return TapScale(
                onTap: () => onCategoryTap(cat['label']!),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(cat['emoji']!, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cat['label']!,
                          style: AppTextStyles.label.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── No Results State ──────────────────────────────────────────────────────────
class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 64)),
          const SizedBox(height: AppSpacing.lg),
          Text('No events for \'$query\'', style: AppTextStyles.heading3),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Try checking your spelling or use different keywords.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
