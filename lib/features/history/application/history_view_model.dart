// lib/features/history/application/history_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../homes/application/current_home_provider.dart';
import '../../homes/application/dashboard_provider.dart';
import '../domain/task_event.dart';
import 'history_provider.dart';

part 'history_view_model.g.dart';

@riverpod
class HistoryFilterNotifier extends _$HistoryFilterNotifier {
  @override
  HistoryFilter build() => const HistoryFilter();
  void setFilter(HistoryFilter f) => state = f;
}

abstract class HistoryViewModel {
  AsyncValue<List<TaskEvent>> get events;
  HistoryFilter get filter;
  bool get hasMore;
  bool get isPremium;
  void loadMore();
  void applyFilter(HistoryFilter newFilter);
}

class _HistoryViewModelImpl implements HistoryViewModel {
  const _HistoryViewModelImpl({
    required this.events,
    required this.filter,
    required this.hasMore,
    required this.isPremium,
    required this.homeId,
    required this.ref,
  });

  @override
  final AsyncValue<List<TaskEvent>> events;
  @override
  final HistoryFilter filter;
  @override
  final bool hasMore;
  @override
  final bool isPremium;
  final String? homeId;
  final Ref ref;

  @override
  void loadMore() {
    if (homeId == null) return;
    ref
        .read(historyNotifierProvider(homeId!).notifier)
        .loadMore(isPremium: isPremium);
  }

  @override
  void applyFilter(HistoryFilter newFilter) {
    if (homeId == null) return;
    ref.read(historyFilterNotifierProvider.notifier).setFilter(newFilter);
    ref.read(historyNotifierProvider(homeId!).notifier).applyFilter(newFilter);
    loadMore();
  }
}

@riverpod
HistoryViewModel historyViewModel(HistoryViewModelRef ref) {
  final homeId = ref.watch(currentHomeProvider).valueOrNull?.id;
  final filter = ref.watch(historyFilterNotifierProvider);
  final isPremium =
      ref.watch(dashboardProvider).valueOrNull?.premiumFlags.isPremium ?? false;

  if (homeId == null) {
    return _HistoryViewModelImpl(
      events: const AsyncValue.loading(),
      filter: filter,
      hasMore: false,
      isPremium: isPremium,
      homeId: null,
      ref: ref,
    );
  }

  final events = ref.watch(historyNotifierProvider(homeId));
  final hasMore =
      ref.read(historyNotifierProvider(homeId).notifier).hasMore;

  return _HistoryViewModelImpl(
    events: events,
    filter: filter,
    hasMore: hasMore,
    isPremium: isPremium,
    homeId: homeId,
    ref: ref,
  );
}
