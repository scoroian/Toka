// lib/features/notifications/application/notification_tap_handler.dart
//
// Handler del tap sobre una notificación (local o remota). Resuelve el payload
// canónico y navega al destino indicado usando el GoRouter global.
//
// Aislar la lógica aquí permite testear la decisión de navegación sin montar
// el servicio de `flutter_local_notifications` completo.

import 'package:go_router/go_router.dart';

import 'notification_service.dart';

class NotificationTapHandler {
  const NotificationTapHandler(this._router);

  final GoRouter _router;

  void handle(TokaNotificationPayload payload) {
    final route = _resolveRoute(payload);
    _router.go(route);
  }

  /// Devuelve la ruta final a la que debe navegarse. Se expone como método
  /// estático para poder testearlo sin necesidad de un GoRouter real.
  static String resolveRoute(TokaNotificationPayload payload) =>
      _resolveRoute(payload);

  static String _resolveRoute(TokaNotificationPayload payload) {
    final entity = payload.entityId;
    switch (payload.type) {
      case TokaNotificationType.deadline:
      case TokaNotificationType.assignment:
      case TokaNotificationType.reminder:
        // Siempre detalle de la tarea. Si falta el id, caemos a la lista.
        return entity != null && entity.isNotEmpty
            ? '/tasks/$entity'
            : '/tasks';
      case TokaNotificationType.dailySummary:
        return '/home';
      case TokaNotificationType.feedback:
        // Historial con query param para que la pantalla auto-abra la nota.
        return entity != null && entity.isNotEmpty
            ? '/history?feedbackId=$entity'
            : '/history';
      case TokaNotificationType.rotation:
        return '/tasks';
    }
  }
}
