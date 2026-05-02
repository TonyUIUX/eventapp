import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_review/in_app_review.dart';

class RatingService {
  static const _launchCountKey = 'launch_count';
  static const _detailViewsKey = 'detail_views';
  static const _ratingRequestedKey = 'rating_requested';

  static Future<void> trackLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_launchCountKey) ?? 0) + 1;
    await prefs.setInt(_launchCountKey, count);
    await _maybeRequestReview(prefs);
  }

  static Future<void> trackDetailView() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_detailViewsKey) ?? 0) + 1;
    await prefs.setInt(_detailViewsKey, count);
    await _maybeRequestReview(prefs);
  }

  static Future<void> _maybeRequestReview(SharedPreferences prefs) async {
    final launches = prefs.getInt(_launchCountKey) ?? 0;
    final views = prefs.getInt(_detailViewsKey) ?? 0;
    final alreadyRequested = prefs.getBool(_ratingRequestedKey) ?? false;

    if (!alreadyRequested && launches >= 5 && views >= 3) {
      final inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
        await prefs.setBool(_ratingRequestedKey, true);
      }
    }
  }
}
