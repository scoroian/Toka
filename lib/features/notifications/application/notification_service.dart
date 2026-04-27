// lib/features/notifications/application/notification_service.dart
//
// Servicio local de notificaciones. Responsable de:
//   1. Inicializar `flutter_local_notifications` y crear los 6 canales Android
//      (cada tipo con su propia importancia/sonido/vibración).
//   2. Exponer 6 métodos `show*` que construyen el payload canónico y la
//      notificación con el estilo elegido en la galería.
//   3. Registrar el callback de tap (deep-link) que navega al destino indicado
//      en el payload mediante el callback inyectado desde `app.dart`.
//
// Nota: este servicio se usa para notificaciones locales (QA y triggers
// de la propia app). Las notificaciones remotas por FCM producen el mismo
// payload JSON desde las Cloud Functions y el handler de `firebase_messaging`
// re-emite en local para que el usuario vea exactamente el mismo estilo.

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../l10n/app_localizations.dart';

part 'notification_service.g.dart';

enum TokaNotificationType {
  deadline,
  assignment,
  reminder,
  dailySummary,
  feedback,
  rotation,
}

class TokaNotificationChannel {
  const TokaNotificationChannel({
    required this.id,
    required this.name,
    required this.description,
    required this.importance,
    required this.playSound,
    required this.enableVibration,
  });

  final String id;
  final String name;
  final String description;
  final Importance importance;
  final bool playSound;
  final bool enableVibration;

  AndroidNotificationChannel toAndroid() => AndroidNotificationChannel(
        id,
        name,
        description: description,
        importance: importance,
        playSound: playSound,
        enableVibration: enableVibration,
      );
}

const Map<TokaNotificationType, TokaNotificationChannel> kTokaChannels = {
  TokaNotificationType.deadline: TokaNotificationChannel(
    id: 'toka_deadline',
    name: 'Tareas por vencer',
    description: 'Alertas cuando una tarea llega a su hora de vencimiento',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  ),
  TokaNotificationType.assignment: TokaNotificationChannel(
    id: 'toka_assignment',
    name: 'Tareas asignadas',
    description: 'Cuando otro miembro te asigna una tarea nueva',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  ),
  TokaNotificationType.reminder: TokaNotificationChannel(
    id: 'toka_reminder',
    name: 'Recordatorios previos',
    description:
        'Aviso silencioso unos minutos antes del vencimiento (Premium)',
    importance: Importance.defaultImportance,
    playSound: false,
    enableVibration: true,
  ),
  TokaNotificationType.dailySummary: TokaNotificationChannel(
    id: 'toka_daily_summary',
    name: 'Resumen diario',
    description: 'Lista de tareas del día a primera hora (Premium)',
    importance: Importance.low,
    playSound: false,
    enableVibration: false,
  ),
  TokaNotificationType.feedback: TokaNotificationChannel(
    id: 'toka_feedback',
    name: 'Valoraciones',
    description: 'Cuando otro miembro valora una tarea que has completado',
    importance: Importance.defaultImportance,
    playSound: true,
    enableVibration: false,
  ),
  TokaNotificationType.rotation: TokaNotificationChannel(
    id: 'toka_rotation',
    name: 'Rotaciones',
    description: 'Cuando cambia el turno de una tarea en rotación',
    importance: Importance.defaultImportance,
    playSound: false,
    enableVibration: true,
  ),
};

/// Payload canónico que viaja tanto en notificaciones locales como en
/// datos FCM remotos. La ruta está ya resuelta (`/tasks/ABC` no `/tasks/:id`).
@immutable
class TokaNotificationPayload {
  const TokaNotificationPayload({
    required this.type,
    required this.route,
    required this.homeId,
    required this.homeName,
    this.entityId,
  });

  final TokaNotificationType type;
  final String route;
  final String homeId;
  final String homeName;
  final String? entityId;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'route': route,
        'homeId': homeId,
        'homeName': homeName,
        if (entityId != null) 'entityId': entityId,
      };

  static TokaNotificationPayload? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final typeName = map['type'] as String?;
      final type = TokaNotificationType.values.firstWhere(
        (t) => t.name == typeName,
        orElse: () => TokaNotificationType.deadline,
      );
      return TokaNotificationPayload(
        type: type,
        route: map['route'] as String? ?? '/home',
        homeId: map['homeId'] as String? ?? '',
        homeName: map['homeName'] as String? ?? '',
        entityId: map['entityId'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  String encode() => jsonEncode(toJson());
}

/// Callback invocado cuando el usuario toca una notificación. Se registra
/// una única vez desde `app.dart` para redirigir a la ruta del payload.
typedef NotificationTapCallback = void Function(TokaNotificationPayload payload);

class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  NotificationTapCallback? _onTap;
  bool _initialized = false;
  int _autoIncrement = 10000;

  bool get isInitialized => _initialized;

  Future<void> init({required NotificationTapCallback onTap}) async {
    _onTap = onTap;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (resp) {
        final parsed = TokaNotificationPayload.tryParse(resp.payload);
        if (parsed != null) _onTap?.call(parsed);
      },
    );
    await _createAndroidChannels();
    _initialized = true;
  }

  Future<void> _createAndroidChannels() async {
    if (!kIsWeb && !Platform.isAndroid) return;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    for (final ch in kTokaChannels.values) {
      await android.createNotificationChannel(ch.toAndroid());
    }
  }

  int _nextId() => ++_autoIncrement;

  // ──────────────────────────────────────────────────────────────
  // Estilos (uno por evento, siguiendo lo elegido en la galería)
  // ──────────────────────────────────────────────────────────────

  /// 1 · Tarea por vencer · Compacto (1-A)
  ///
  /// `l10n` viene del caller (que sí tiene `BuildContext`). El servicio en sí
  /// vive en `application/`, sin acceso a contexto, así que delegamos la
  /// elección de idioma al sitio que llama. Las notifs remotas via FCM las
  /// genera Cloud Functions con su propia traducción.
  Future<void> showDeadline({
    required AppLocalizations l10n,
    required String homeId,
    required String homeName,
    required String taskId,
    required String taskTitle,
    required int minutesLeft,
  }) =>
      _show(
        type: TokaNotificationType.deadline,
        title: l10n.notif_deadline_title,
        body: l10n.notif_deadline_body(taskTitle, minutesLeft),
        homeId: homeId,
        homeName: homeName,
        entityId: taskId,
        route: '/tasks/$taskId',
      );

  /// 2 · Tarea asignada · Compacto con asignador (2-A)
  Future<void> showAssignment({
    required AppLocalizations l10n,
    required String homeId,
    required String homeName,
    required String taskId,
    required String taskTitle,
    required String assignerName,
    required String dueAtLabel,
  }) =>
      _show(
        type: TokaNotificationType.assignment,
        title: l10n.notif_assignment_title(assignerName),
        body: l10n.notif_assignment_body(taskTitle, dueAtLabel),
        homeId: homeId,
        homeName: homeName,
        entityId: taskId,
        route: '/tasks/$taskId',
      );

  /// 3 · Recordatorio N min antes · Compacto (3-A)
  Future<void> showReminder({
    required AppLocalizations l10n,
    required String homeId,
    required String homeName,
    required String taskId,
    required String taskTitle,
    required int minutesLeft,
    required String dueAtLabel,
  }) =>
      _show(
        type: TokaNotificationType.reminder,
        title: l10n.notif_reminder_title(minutesLeft, taskTitle),
        body: l10n.notif_reminder_body(dueAtLabel),
        homeId: homeId,
        homeName: homeName,
        entityId: taskId,
        route: '/tasks/$taskId',
      );

  /// 4 · Resumen diario · Compacto con contador (4-C)
  Future<void> showDailySummary({
    required AppLocalizations l10n,
    required String homeId,
    required String homeName,
    required int totalToday,
    required int myToday,
  }) =>
      _show(
        type: TokaNotificationType.dailySummary,
        title: l10n.notif_daily_summary_title(totalToday, myToday),
        body: l10n.notif_daily_summary_body,
        homeId: homeId,
        homeName: homeName,
        route: '/home',
      );

  /// 5 · Valoración recibida · MessagingStyle con nota (5-B)
  Future<void> showFeedback({
    required AppLocalizations l10n,
    required String homeId,
    required String homeName,
    required String feedbackId,
    required String raterName,
    required int stars,
    required String taskTitle,
  }) async {
    final starsStr = '⭐' * stars.clamp(1, 5);
    final messaging = MessagingStyleInformation(
      Person(name: raterName, key: raterName),
      conversationTitle: l10n.notif_feedback_title(taskTitle),
      groupConversation: false,
      messages: <Message>[
        Message(
          l10n.notif_feedback_msg_body(starsStr),
          DateTime.now(),
          Person(name: raterName, key: raterName),
        ),
      ],
    );
    await _show(
      type: TokaNotificationType.feedback,
      title: l10n.notif_feedback_title(taskTitle),
      body: '$raterName · $starsStr',
      homeId: homeId,
      homeName: homeName,
      entityId: feedbackId,
      route: '/history',
      androidStyle: messaging,
    );
  }

  /// 6 · Rotación · InboxStyle resumen (6-C)
  Future<void> showRotation({
    required AppLocalizations l10n,
    required String homeId,
    required String homeName,
    required List<String> rotationLines,
  }) async {
    final inbox = InboxStyleInformation(
      rotationLines,
      contentTitle: l10n.notif_rotation_title,
      summaryText: l10n.notif_rotation_summary(homeName, rotationLines.length),
    );
    await _show(
      type: TokaNotificationType.rotation,
      title: l10n.notif_rotation_title,
      body: rotationLines.take(3).join(' · '),
      homeId: homeId,
      homeName: homeName,
      route: '/tasks',
      androidStyle: inbox,
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Plomería
  // ──────────────────────────────────────────────────────────────

  Future<void> _show({
    required TokaNotificationType type,
    required String title,
    required String body,
    required String homeId,
    required String homeName,
    required String route,
    String? entityId,
    StyleInformation? androidStyle,
  }) async {
    final channel = kTokaChannels[type]!;
    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: channel.importance,
      priority: Priority.high,
      subText: homeName,
      styleInformation: androidStyle,
      playSound: channel.playSound,
      enableVibration: channel.enableVibration,
    );
    final iosDetails = DarwinNotificationDetails(
      subtitle: homeName,
      presentAlert: true,
      presentBadge: true,
      presentSound: channel.playSound,
      threadIdentifier: '${channel.id}_$homeId',
      categoryIdentifier: channel.id,
    );
    final payload = TokaNotificationPayload(
      type: type,
      route: route,
      homeId: homeId,
      homeName: homeName,
      entityId: entityId,
    );
    await _plugin.show(
      _nextId(),
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload.encode(),
    );
  }
}

@Riverpod(keepAlive: true)
NotificationService notificationService(NotificationServiceRef ref) {
  return NotificationService();
}
