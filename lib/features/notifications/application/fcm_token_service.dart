// lib/features/notifications/application/fcm_token_service.dart
import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../domain/notification_prefs_repository.dart';

/// Obtiene el token FCM actual y lo guarda en Firestore.
/// Llamar una vez al autenticarse y al recibir un refresh de token.
class FcmTokenService {
  FcmTokenService({
    required NotificationPrefsRepository repository,
    required FirebaseMessaging messaging,
  })  : _repository = repository,
        _messaging = messaging;

  final NotificationPrefsRepository _repository;
  final FirebaseMessaging _messaging;

  Future<void> initAndSaveToken(String homeId, String uid) async {
    final token = await _messaging.getToken();
    if (token == null) return;
    await _repository.updateFcmToken(homeId, uid, token);
  }

  StreamSubscription<String> listenForTokenRefresh(String homeId, String uid) {
    return _messaging.onTokenRefresh.listen((token) {
      _repository.updateFcmToken(homeId, uid, token);
    });
  }
}
