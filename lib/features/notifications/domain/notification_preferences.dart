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
      fcmToken: map['fcmToken'] as String?,
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
      if (fcmToken != null) 'fcmToken': fcmToken!,
      if (systemAuthorized != null) 'systemAuthorized': systemAuthorized!,
    };
  }
}
