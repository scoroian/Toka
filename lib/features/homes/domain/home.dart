import 'package:freezed_annotation/freezed_annotation.dart';

import 'home_limits.dart';

part 'home.freezed.dart';

enum HomePremiumStatus {
  free,
  active,
  cancelledPendingEnd,
  rescue,
  expiredFree,
  restorable,
  purged;

  static HomePremiumStatus fromString(String value) {
    return HomePremiumStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => HomePremiumStatus.free,
    );
  }
}

@freezed
class Home with _$Home {
  const factory Home({
    required String id,
    required String name,
    required String ownerUid,
    required String? currentPayerUid,
    required String? lastPayerUid,
    required HomePremiumStatus premiumStatus,
    required String? premiumPlan,
    required DateTime? premiumEndsAt,
    required DateTime? restoreUntil,
    required bool autoRenewEnabled,
    required HomeLimits limits,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? lastBillingError,
    // URL de la foto del hogar en Cloud Storage. null cuando el hogar
    // todavía usa la inicial. Se actualiza desde el sheet de "Avatar
    // del hogar" en `home_settings_screen` (ambas skins).
    String? photoUrl,
  }) = _Home;
}
