// lib/providers/navigation_provider.dart
// Global tab navigation state — moved out of main.dart for clean architecture.

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global provider to allow any widget to switch tabs programmatically.
/// Use: ref.read(selectedTabProvider.notifier).state = index;
final selectedTabProvider = StateProvider<int>((ref) => 0);
