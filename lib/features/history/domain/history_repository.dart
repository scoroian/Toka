// lib/features/history/domain/history_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import 'history_filter.dart';
import 'task_event.dart';

abstract class HistoryRepository {
  /// Returns events for the page and an optional cursor for the next page.
  /// A null cursor means there are no more pages (end of data or date limit).
  Future<(List<TaskEvent>, DocumentSnapshot?)> fetchPage({
    required String homeId,
    HistoryFilter filter,
    DocumentSnapshot? startAfter,
    int limit,
    bool isPremium,
  });
}
