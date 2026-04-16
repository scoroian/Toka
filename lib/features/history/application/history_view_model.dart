// lib/features/history/application/history_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_provider.dart';
import '../../homes/application/current_home_provider.dart';
import '../../homes/application/dashboard_provider.dart';
import '../../members/application/members_provider.dart';
import '../domain/task_event.dart';
import 'history_provider.dart';

part 'history_view_model.g.dart';

/// Evento de historial enriquecido con datos de presentación.
class TaskEventItem {
  const TaskEventItem({
    required this.raw,
    required this.actorName,
    this.actorPhotoUrl,
    required this.isOwnEvent,
    required this.isRated,
    required this.canRate,
  });

  final TaskEvent raw;
  final String    actorName;
  final String?   actorPhotoUrl;
  final bool      isOwnEvent;
  final bool      isRated;
  /// Solo true cuando raw es CompletedEvent && !isOwnEvent && !isRated.
  final bool      canRate;

  static bool computeCanRate({
    required TaskEvent raw,
    required bool isOwnEvent,
    required bool isRated,
  }) =>
      raw is CompletedEvent && !isOwnEvent && !isRated;
}

@riverpod
class HistoryFilterNotifier extends _$HistoryFilterNotifier {
  @override
  HistoryFilter build() => const HistoryFilter();
  void setFilter(HistoryFilter f) => state = f;
}

abstract class HistoryViewModel {
  AsyncValue<List<TaskEventItem>> get items;
  HistoryFilter get filter;
  bool get hasMore;
  bool get isPremium;
  bool get hasHome;
  void loadMore();
  void applyFilter(HistoryFilter newFilter);
  Future<void> rateEvent(String eventId, double rating, {String? note});
}

class _HistoryViewModelImpl implements HistoryViewModel {
  const _HistoryViewModelImpl({
    required this.items,
    required this.filter,
    required this.hasMore,
    required this.isPremium,
    required this.homeId,
    required this.currentUid,
    required this.ref,
  });

  @override
  final AsyncValue<List<TaskEventItem>> items;
  @override
  final HistoryFilter filter;
  @override
  final bool hasMore;
  @override
  final bool isPremium;
  @override
  bool get hasHome => homeId != null;
  final String? homeId;
  final String  currentUid;
  final Ref ref;

  @override
  void loadMore() {
    if (homeId == null) return;
    ref.read(historyNotifierProvider(homeId!).notifier)
        .loadMore(isPremium: isPremium);
  }

  @override
  void applyFilter(HistoryFilter newFilter) {
    if (homeId == null) return;
    ref.read(historyFilterNotifierProvider.notifier).setFilter(newFilter);
    ref.read(historyNotifierProvider(homeId!).notifier).applyFilter(newFilter);
    loadMore();
  }

  @override
  Future<void> rateEvent(String eventId, double rating, {String? note}) async {
    // Guard: homeId must be set
    if (homeId == null) return;
    // TODO: write to homes/{homeId}/taskRatings when schema is defined
  }
}

@riverpod
HistoryViewModel historyViewModel(HistoryViewModelRef ref) {
  final homeId = ref.watch(currentHomeProvider).valueOrNull?.id;
  final filter = ref.watch(historyFilterNotifierProvider);
  final isPremium =
      ref.watch(dashboardProvider).valueOrNull?.premiumFlags.isPremium ?? false;
  final auth = ref.watch(authProvider);
  final currentUid = auth.whenOrNull(authenticated: (u) => u.uid) ?? '';

  if (homeId == null) {
    return _HistoryViewModelImpl(
      items: const AsyncValue.loading(),
      filter: filter,
      hasMore: false,
      isPremium: isPremium,
      homeId: null,
      currentUid: currentUid,
      ref: ref,
    );
  }

  final rawEvents = ref.watch(historyNotifierProvider(homeId));
  final hasMore = ref.read(historyNotifierProvider(homeId).notifier).hasMore;

  // Resolve actor names and photos from home members
  final members = ref.watch(homeMembersProvider(homeId)).valueOrNull ?? [];
  final nameMap  = {for (final m in members) m.uid: m.nickname};
  final photoMap = {for (final m in members) m.uid: m.photoUrl};

  // isRated = false until taskRatings collection is implemented
  final items = rawEvents.whenData((events) => events.map((e) {
        final actorUid = switch (e) {
          CompletedEvent c => c.actorUid,
          PassedEvent p    => p.actorUid,
          MissedEvent m    => m.actorUid,
        };
        final isOwnEvent = actorUid == currentUid;
        const isRated = false;
        return TaskEventItem(
          raw: e,
          actorName: nameMap[actorUid] ?? actorUid,
          actorPhotoUrl: photoMap[actorUid],
          isOwnEvent: isOwnEvent,
          isRated: isRated,
          canRate: TaskEventItem.computeCanRate(
            raw: e,
            isOwnEvent: isOwnEvent,
            isRated: isRated,
          ),
        );
      }).toList());

  return _HistoryViewModelImpl(
    items: items,
    filter: filter,
    hasMore: hasMore,
    isPremium: isPremium,
    homeId: homeId,
    currentUid: currentUid,
    ref: ref,
  );
}
