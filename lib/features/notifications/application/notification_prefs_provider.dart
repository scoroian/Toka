// lib/features/notifications/application/notification_prefs_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/notification_prefs_repository_impl.dart';
import '../domain/notification_preferences.dart';
import '../domain/notification_prefs_repository.dart';

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
