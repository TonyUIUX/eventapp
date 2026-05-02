import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/app_config_provider.dart';
import '../../../core/utils/url_utils.dart';

class PromoBanner extends ConsumerStatefulWidget {
  const PromoBanner({super.key});

  @override
  ConsumerState<PromoBanner> createState() => _PromoBannerState();
}

class _PromoBannerState extends ConsumerState<PromoBanner> {
  bool _isDismissed = false;
  static const String _dismissKey = 'promo_banner_dismissed';

  @override
  void initState() {
    super.initState();
    _checkDismissed();
  }

  Future<void> _checkDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDismissed = prefs.getBool(_dismissKey) ?? false;
    });
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dismissKey, true);
    setState(() {
      _isDismissed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) return const SizedBox.shrink();

    final configAsync = ref.watch(appConfigProvider);

    return configAsync.maybeWhen(
      data: (config) {
        if (!config.showPromoBanner) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Color(int.parse(config.promoBannerColor.replaceFirst('#', '0xFF'))),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              const Icon(Icons.celebration_rounded, color: Colors.orangeAccent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      config.promoBannerText,
                      style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (config.promoBannerCta.isNotEmpty && config.promoBannerLink != null) ...[
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => AppUrlUtils.openUrl(config.promoBannerLink!, context),
                        child: Text(
                          config.promoBannerCta,
                          style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
                onPressed: _dismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
