// lib/features/notifications/application/notification_prefs_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_provider.dart';
import '../../homes/application/current_home_provider.dart';
import '../data/notification_prefs_repository_impl.dart';
import '../domain/notification_preferences.dart';
import '../domain/notification_prefs_repository.dart';
import 'fcm_token_service.dart';

part 'notification_prefs_provider.g.dart';

@Riverpod(keepAlive: true)
NotificationPrefsRepository notificationPrefsRepository(NotificationPrefsRepositoryRef ref) {
  return NotificationPrefsRepositoryImpl(firestore: FirebaseFirestore.instance);
}

@riverpod
Stream<NotificationPreferences> notificationPrefs(
  NotificationPrefsRef ref, {
  required String homeId,
  required String uid,
}) {
  return ref.watch(notificationPrefsRepositoryProvider).watchPrefs(homeId, uid);
}

@riverpod
class NotificationPrefsNotifier extends _$NotificationPrefsNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> save(NotificationPreferences prefs) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(notificationPrefsRepositoryProvider).savePrefs(prefs),
    );
  }
}

@Riverpod(keepAlive: true)
void fcmTokenInit(FcmTokenInitRef ref) {
  final authState = ref.watch(authProvider);
  final homeAsync = ref.watch(currentHomeProvider);

  final uid = authState.whenOrNull(authenticated: (u) => u.uid);
  final home = homeAsync.valueOrNull;

  if (uid == null || home == null) return;

  final service = FcmTokenService(
    repository: ref.watch(notificationPrefsRepositoryProvider),
    messaging: FirebaseMessaging.instance,
  );

  // Save current token
  service.initAndSaveToken(home.id, uid);

  // Listen for token refreshes
  final sub = service.listenForTokenRefresh(home.id, uid);
  ref.onDispose(sub.cancel);
}

/// Estado actual del permiso de notificaciones a nivel de sistema operativo.
/// Se invalida manualmente al volver al foreground para forzar una relectura.
@riverpod
Future<bool> systemNotificationsAuthorized(
  SystemNotificationsAuthorizedRef ref,
) async {
  final settings = await FirebaseMessaging.instance.getNotificationSettings();
  return settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional;
}
