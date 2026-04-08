// lib/features/notifications/application/notification_settings_view_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../subscription/application/subscription_provider.dart';
import '../../subscription/domain/subscription_state.dart';
import '../domain/notification_preferences.dart';
import 'notification_prefs_provider.dart';

part 'notification_settings_view_model.freezed.dart';
part 'notification_settings_view_model.g.dart';

abstract class NotificationSettingsViewModel {
  bool get isLoaded;
  bool get isPremium;
  NotificationPreferences get prefs;
  Future<void> updatePrefs(NotificationPreferences updated);
}

@freezed
class _NotifVMState with _$NotifVMState {
  const factory _NotifVMState({
    @Default(false) bool isLoaded,
    @Default(false) bool isPremium,
    NotificationPreferences? prefs,
  }) = __NotifVMState;
}

bool _subIsPremium(SubscriptionState sub) => sub.map(
      free: (_) => false,
      active: (_) => true,
      cancelledPendingEnd: (_) => true,
      rescue: (_) => true,
      expiredFree: (_) => false,
      restorable: (_) => false,
      purged: (_) => false,
    );

@riverpod
class NotificationSettingsViewModelNotifier
    extends _$NotificationSettingsViewModelNotifier
    implements NotificationSettingsViewModel {
  @override
  _NotifVMState build(String homeId, String uid) {
    final sub = ref.watch(subscriptionStateProvider);
    final isPremium = _subIsPremium(sub);

    final prefsAsync =
        ref.watch(notificationPrefsProvider(homeId: homeId, uid: uid));
    prefsAsync.whenData((p) {
      if (!state.isLoaded) {
        Future.microtask(() => state = state.copyWith(
              isLoaded: true,
              isPremium: isPremium,
              prefs: p,
            ));
      }
    });
    return _NotifVMState(isPremium: isPremium);
  }

  @override
  bool get isLoaded => state.isLoaded;
  @override
  bool get isPremium => state.isPremium;
  @override
  NotificationPreferences get prefs =>
      state.prefs ?? NotificationPreferences(homeId: '', uid: '');

  @override
  Future<void> updatePrefs(NotificationPreferences updated) async {
    state = state.copyWith(prefs: updated);
    await ref.read(notificationPrefsNotifierProvider.notifier).save(updated);
  }
}

@riverpod
NotificationSettingsViewModel notificationSettingsViewModel(
  NotificationSettingsViewModelRef ref,
  String homeId,
  String uid,
) {
  ref.watch(notificationSettingsViewModelNotifierProvider(homeId, uid));
  return ref
      .read(notificationSettingsViewModelNotifierProvider(homeId, uid).notifier);
}
