// lib/features/notifications/domain/notification_prefs_repository.dart
import 'notification_preferences.dart';

abstract interface class NotificationPrefsRepository {
  /// Stream de las preferencias del usuario en un hogar concreto.
  Stream<NotificationPreferences> watchPrefs(String homeId, String uid);

  /// Guarda (o actualiza) las preferencias.
  Future<void> savePrefs(NotificationPreferences prefs);

  /// Actualiza solo el token FCM.
  Future<void> updateFcmToken(String homeId, String uid, String token);
}
