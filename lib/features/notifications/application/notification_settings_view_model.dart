// lib/features/notifications/application/notification_settings_view_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../subscription/application/subscription_dashboard_provider.dart';
import '../domain/notification_preferences.dart';
import 'notification_prefs_provider.dart';

part 'notification_settings_view_model.freezed.dart';
part 'notification_settings_view_model.g.dart';

/// Vista inmutable que consume la pantalla de notificaciones. Combina las
/// preferencias del miembro, el estado premium del hogar y el permiso del
/// sistema operativo. Se entrega mediante un `Stream` (no `Future`) para
/// evitar que el cambio de estado premium flickere los toggles (BUG-13).
@freezed
class NotificationSettingsView with _$NotificationSettingsView {
  const factory NotificationSettingsView({
    required NotificationPreferences prefs,
    required bool isPremium,
    required bool systemAuthorized,
  }) = _NotificationSettingsView;
}

/// Stream unificado que emite una nueva vista cuando cambian las prefs del
/// miembro, el `subscriptionDashboard` (premium) o la autorización de
/// sistema. Al dejarlo `keepAlive`, la vista conserva los datos previos
/// mientras Firestore entrega la siguiente emisión, evitando el salto a
/// estado "deshabilitado" durante la transición.
@Riverpod(keepAlive: true)
Stream<NotificationSettingsView> notificationSettings(
  NotificationSettingsRef ref,
  String homeId,
  String uid,
) {
  final sub = ref.watch(subscriptionDashboardProvider());
  final isPremium = sub.valueOrNull?.isPremium ?? false;
  final sysAuth =
      ref.watch(systemNotificationsAuthorizedProvider).valueOrNull ?? true;

  final prefsStream =
      ref.watch(notificationPrefsRepositoryProvider).watchPrefs(homeId, uid);

  return prefsStream.map(
    (prefs) => NotificationSettingsView(
      prefs: prefs,
      isPremium: isPremium,
      systemAuthorized: sysAuth,
    ),
  );
}

/// Action-only provider: aislado del stream para que guardar preferencias no
/// provoque un rebuild de la vista (que ya lo hace el stream cuando Firestore
/// propaga el cambio).
@riverpod
class NotificationSettingsActions extends _$NotificationSettingsActions {
  @override
  void build() {}

  Future<void> updatePrefs(NotificationPreferences updated) async {
    await ref.read(notificationPrefsNotifierProvider.notifier).save(updated);
  }
}
