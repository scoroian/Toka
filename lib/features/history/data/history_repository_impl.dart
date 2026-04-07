// lib/features/history/data/history_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/history_filter.dart';
import '../domain/history_repository.dart';
import '../domain/task_event.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<(List<TaskEvent>, DocumentSnapshot?)> fetchPage({
    required String homeId,
    HistoryFilter filter = const HistoryFilter(),
    DocumentSnapshot? startAfter,
    int limit = 20,
    bool isPremium = false,
  }) async {
    // Build base query with optional equality filters.
    Query<Map<String, dynamic>> query = _firestore
        .collection('homes')
        .doc(homeId)
        .collection('taskEvents')
        .orderBy('createdAt', descending: true);

    if (filter.memberUid != null) {
      query = query.where('actorUid', isEqualTo: filter.memberUid);
    }
    if (filter.taskId != null) {
      query = query.where('taskId', isEqualTo: filter.taskId);
    }
    if (filter.eventType != null) {
      query = query.where('eventType', isEqualTo: filter.eventType);
    }

    // IMPORTANT: startAfterDocument must be added BEFORE limit.
    // FakeFirebaseFirestore returns 0 results when limit precedes startAfterDocument.
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    query = query.limit(limit);

    final snap = await query.get();
    final rawCount = snap.docs.length;

    // Apply date cutoff client-side so the query remains compatible with
    // FakeFirebaseFirestore (which doesn't support startAfterDocument combined
    // with a range where-clause on the same field as orderBy).
    final daysBack = isPremium ? 90 : 30;
    final cutoff = DateTime.now().subtract(Duration(days: daysBack));

    final events = snap.docs
        .where((d) {
          final ts = d.data()['createdAt'] as Timestamp?;
          return ts != null && ts.toDate().isAfter(cutoff);
        })
        .map((d) => TaskEvent.fromFirestore(
            d as DocumentSnapshot<Map<String, dynamic>>))
        .toList();

    // Return cursor only when we got a full page AND no docs were cut by date.
    // If rawCount < limit → end of Firestore data.
    // If events.length < rawCount → some docs were older than cutoff → boundary reached.
    final nextCursor =
        (rawCount >= limit && events.length == rawCount) ? snap.docs.last : null;

    return (events, nextCursor);
  }
}
