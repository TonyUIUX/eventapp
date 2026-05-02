import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_config_model.dart';

final appConfigProvider = StreamProvider<AppConfigModel>((ref) {
  return FirebaseFirestore.instance
      .collection('app_config')
      .doc('pricing')
      .snapshots()
      .map((snapshot) {
        if (!snapshot.exists) {
          return AppConfigModel.initial();
        }
        return AppConfigModel.fromFirestore(snapshot);
      });
});

final maintenanceModeProvider = Provider<bool>((ref) {
  final configAsync = ref.watch(appConfigProvider);
  return configAsync.maybeWhen(
    data: (config) => config.maintenanceMode,
    orElse: () => false,
  );
});
