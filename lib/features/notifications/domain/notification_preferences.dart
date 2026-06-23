// lib/features/notifications/domain/notification_preferences.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_preferences.freezed.dart';

@freezed
class NotificationPreferences with _$NotificationPreferences {
  const factory NotificationPreferences({
    required String homeId,
    required String uid,
    @Default(true) bool notifyOnDue,
    @Default(false) bool notifyBefore,
    @Default(30) int minutesBefore,
    @Default(false) bool dailySummary,
    String? dailySummaryTime,
    @Default([]) List<String> silencedTypes,
    String? fcmToken,
    bool? systemAuthorized,
  }) = _NotificationPreferences;

  const NotificationPreferences._();

  factory NotificationPreferences.fromMap(
    String homeId,
    String uid,
    Map<String, dynamic> map,
  ) {
    return NotificationPreferences(
      homeId: homeId,
      uid: uid,
      notifyOnDue: map['notifyOnDue'] as bool? ?? true,
      notifyBefore: map['notifyBefore'] as bool? ?? false,
      minutesBefore: map['minutesBefore'] as int? ?? 30,
      dailySummary: map['dailySummary'] as bool? ?? false,
      dailySummaryTime: map['dailySummaryTime'] as String?,
      silencedTypes: (map['silencedTypes'] as List<dynamic>?)?.cast<String>() ?? [],
      // PRIVACIDAD (Hallazgo #01): el token FCM ya NO se lee/guarda en el doc de
      // miembro (legible por todo el hogar). Vive en users/{uid}.fcmToken (doc
      // privado) y lo gestiona FcmTokenService.updateFcmToken. El campo se
      // mantiene en el modelo por compatibilidad pero no se persiste aquí.
      fcmToken: null,
      systemAuthorized: map['systemAuthorized'] as bool?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notifyOnDue': notifyOnDue,
      'notifyBefore': notifyBefore,
      'minutesBefore': minutesBefore,
      'dailySummary': dailySummary,
      'silencedTypes': silencedTypes,
      if (dailySummaryTime != null) 'dailySummaryTime': dailySummaryTime!,
      // No escribir fcmToken en el doc de miembro (Hallazgo #01).
      if (systemAuthorized != null) 'systemAuthorized': systemAuthorized!,
    };
  }
}
