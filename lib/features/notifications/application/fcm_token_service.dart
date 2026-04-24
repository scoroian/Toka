// lib/features/notifications/application/fcm_token_service.dart
import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../domain/notification_prefs_repository.dart';

/// Estado de autorización del permiso de notificaciones a nivel de sistema
/// operativo. Wrapper estable sobre [AuthorizationStatus] de firebase_messaging
/// para no filtrar el tipo externo a la UI y permitir testear sin pluggins
/// nativos.
enum NotificationAuthorizationStatus {
  authorized,
  denied,
  notDetermined,
  provisional,
}

NotificationAuthorizationStatus _mapStatus(AuthorizationStatus s) {
  switch (s) {
    case AuthorizationStatus.authorized:
      return NotificationAuthorizationStatus.authorized;
    case AuthorizationStatus.denied:
      return NotificationAuthorizationStatus.denied;
    case AuthorizationStatus.notDetermined:
      return NotificationAuthorizationStatus.notDetermined;
    case AuthorizationStatus.provisional:
      return NotificationAuthorizationStatus.provisional;
  }
}

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

  /// Muestra el prompt del sistema para autorizar notificaciones. En Android
  /// 12 y anteriores devuelve `authorized` sin diálogo.
  Future<NotificationAuthorizationStatus> requestPermission({
    bool provisional = false,
  }) async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: provisional,
    );
    return _mapStatus(settings.authorizationStatus);
  }

  /// Estado actual del permiso a nivel de SO, sin mostrar diálogo.
  Future<NotificationAuthorizationStatus> currentStatus() async {
    final settings = await _messaging.getNotificationSettings();
    return _mapStatus(settings.authorizationStatus);
  }
}
