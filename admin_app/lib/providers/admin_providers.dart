import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_config_model.dart';
import '../models/event_model.dart';
import '../services/firestore_admin_service.dart';

final adminEventsProvider = StreamProvider<List<EventModel>>((ref) {
  return FirestoreAdminService().getAllEventsStream();
});

final adminConfigProvider = StreamProvider<AppConfigModel>((ref) {
  return FirebaseFirestore.instance
      .collection('app_config')
      .doc('pricing')
      .snapshots()
      .map((snapshot) {
        if (!snapshot.exists) return AppConfigModel.initial();
        return AppConfigModel.fromFirestore(snapshot);
      });
});
