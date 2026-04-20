// lib/features/history/application/rated_events_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rated_events_provider.g.dart';

@riverpod
Stream<Set<String>> ratedEventIds(
  RatedEventIdsRef ref, {
  required String homeId,
  required String currentUid,
}) {
  if (homeId.isEmpty || currentUid.isEmpty) {
    return Stream.value(<String>{});
  }
  return FirebaseFirestore.instance
      .collection('homes')
      .doc(homeId)
      .collection('memberReviews')
      .doc(currentUid)
      .snapshots()
      .map((snap) {
    if (!snap.exists) return <String>{};
    final ids = (snap.data()?['ratedEventIds'] as List?)?.cast<String>() ?? [];
    return ids.toSet();
  });
}
