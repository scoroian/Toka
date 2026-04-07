// lib/features/history/application/history_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/history_repository_impl.dart';
import '../domain/history_filter.dart';
import '../domain/history_repository.dart';
import '../domain/task_event.dart';

export '../domain/history_filter.dart';

part 'history_provider.g.dart';

@Riverpod(keepAlive: true)
HistoryRepository historyRepository(HistoryRepositoryRef ref) {
  return HistoryRepositoryImpl();
}

@riverpod
class HistoryNotifier extends _$HistoryNotifier {
  static const _pageSize = 20;
  DocumentSnapshot? _lastCursor;
  bool _hasMore = true;
  HistoryFilter _filter = const HistoryFilter();

  @override
  AsyncValue<List<TaskEvent>> build(String homeId) {
    return const AsyncValue.data([]);
  }

  bool get hasMore => _hasMore;

  Future<void> loadMore({bool isPremium = false}) async {
    if (!_hasMore || state.isLoading) return;

    try {
      final repo = ref.read(historyRepositoryProvider);
      final (events, cursor) = await repo.fetchPage(
        homeId: homeId,
        filter: _filter,
        startAfter: _lastCursor,
        limit: _pageSize,
        isPremium: isPremium,
      );
      _lastCursor = cursor;
      _hasMore = cursor != null;
      state = AsyncValue.data([...(state.valueOrNull ?? []), ...events]);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  void applyFilter(HistoryFilter filter) {
    _filter = filter;
    _lastCursor = null;
    _hasMore = true;
    state = const AsyncValue.data([]);
  }
}
