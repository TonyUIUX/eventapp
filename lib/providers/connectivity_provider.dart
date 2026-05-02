import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Streams real-time connectivity changes
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

// Simple bool — true when device has no network connection
final isOfflineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).when(
    data: (results) =>
        results.isEmpty || results.contains(ConnectivityResult.none),
    loading: () => false,
    error: (_, __) => false,
  );
});
