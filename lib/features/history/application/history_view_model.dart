// lib/features/history/application/history_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_provider.dart';
import '../../homes/application/current_home_provider.dart';
import '../../homes/application/dashboard_provider.dart';
import '../../members/application/members_provider.dart';
import '../domain/task_event.dart';
import 'history_provider.dart';
import 'rated_events_provider.dart';

part 'history_view_model.g.dart';

/// Evento de historial enriquecido con datos de presentación.
class TaskEventItem {
  const TaskEventItem({
    required this.raw,
    required this.actorName,
    this.actorPhotoUrl,
    this.toName,
    required this.isOwnEvent,
    required this.isRated,
    required this.canRate,
  });

  final TaskEvent raw;
  final String    actorName;
  final String?   actorPhotoUrl;
  /// Nombre resuelto del destinatario en PassedEvent / MissedEvent (toUid).
  /// Null para CompletedEvent, donde no aplica.
  final String?   toName;
  final bool      isOwnEvent;
  final bool      isRated;
  /// Solo true cuando raw es CompletedEvent && !isOwnEvent && !isRated.
  final bool      canRate;

  static bool computeCanRate({
    required TaskEvent raw,
    required bool isOwnEvent,
    required bool isRated,
    required bool canUseReviews,
  }) =>
      canUseReviews && raw is CompletedEvent && !isOwnEvent && !isRated;
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
    // Snapshot de ambos notifiers ANTES de mutar: en cuanto `setFilter`
    // cambia el filtro, `historyViewModelProvider` (que lo observa) queda
    // marcado dirty y cualquier `ref.read` posterior lanza
    // "Cannot use ref functions after the dependency of a provider changed
    // but before the provider rebuilt". Guardar las referencias evita la
    // segunda llamada a ref.read.
    final filterNotifier = ref.read(historyFilterNotifierProvider.notifier);
    final historyNotifier =
        ref.read(historyNotifierProvider(homeId!).notifier);
    filterNotifier.setFilter(newFilter);
    historyNotifier.applyFilter(newFilter);
    historyNotifier.loadMore(isPremium: isPremium);
  }

  @override
  Future<void> rateEvent(String eventId, double rating, {String? note}) async {
    if (homeId == null) return;
    await ref.read(membersRepositoryProvider).submitReview(
          homeId: homeId!,
          taskEventId: eventId,
          score: rating,
          note: note,
        );
  }
}

@riverpod
HistoryViewModel historyViewModel(HistoryViewModelRef ref) {
  final homeId = ref.watch(currentHomeProvider).valueOrNull?.id;
  final filter = ref.watch(historyFilterNotifierProvider);
  final premiumFlags =
      ref.watch(dashboardProvider).valueOrNull?.premiumFlags;
  final isPremium = premiumFlags?.isPremium ?? false;
  final canUseReviews = premiumFlags?.canUseReviews ?? false;
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

  final ratedIds = ref.watch(
    ratedEventIdsProvider(homeId: homeId, currentUid: currentUid),
  ).valueOrNull ?? {};

  final items = rawEvents.whenData((events) => events.map((e) {
        final actorUid = switch (e) {
          CompletedEvent c => c.actorUid,
          PassedEvent p    => p.actorUid,
          MissedEvent m    => m.actorUid,
        };
        final toUid = switch (e) {
          CompletedEvent _ => null,
          PassedEvent p    => p.toUid,
          MissedEvent m    => m.toUid,
        };
        final isOwnEvent = actorUid == currentUid;
        final isRated = ratedIds.contains(e.id);
        return TaskEventItem(
          raw: e,
          actorName: nameMap[actorUid] ?? '?',
          actorPhotoUrl: photoMap[actorUid],
          toName: toUid == null ? null : (nameMap[toUid] ?? '?'),
          isOwnEvent: isOwnEvent,
          isRated: isRated,
          canRate: TaskEventItem.computeCanRate(
            raw: e,
            isOwnEvent: isOwnEvent,
            isRated: isRated,
            canUseReviews: canUseReviews,
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
