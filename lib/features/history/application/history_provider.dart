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
  bool _loading = false;
  HistoryFilter _filter = const HistoryFilter();
  // Token monotónico: al cambiar el filtro se incrementa, invalidando
  // cualquier `loadMore` en vuelo con el filtro anterior para evitar
  // que los resultados obsoletos se mergeen sobre el estado nuevo.
  int _loadToken = 0;

  @override
  AsyncValue<List<TaskEvent>> build(String homeId) {
    return const AsyncValue.data([]);
  }

  bool get hasMore => _hasMore;

  Future<void> loadMore({bool isPremium = false}) async {
    if (!_hasMore || _loading) return;
    _loading = true;
    final token = _loadToken;

    try {
      final repo = ref.read(historyRepositoryProvider);
      final (events, cursor) = await repo.fetchPage(
        homeId: homeId,
        filter: _filter,
        startAfter: _lastCursor,
        limit: _pageSize,
        isPremium: isPremium,
      );
      if (token != _loadToken) return;
      _lastCursor = cursor;
      _hasMore = cursor != null;
      state = AsyncValue.data([...(state.valueOrNull ?? []), ...events]);
    } catch (e, s) {
      if (token != _loadToken) return;
      state = AsyncValue.error(e, s);
    } finally {
      if (token == _loadToken) _loading = false;
    }
  }

  void applyFilter(HistoryFilter filter) {
    _filter = filter;
    _lastCursor = null;
    _hasMore = true;
    _loading = false;
    _loadToken++;
    state = const AsyncValue.data([]);
  }
}
