import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_state.freezed.dart';

/// Estado completo de la suscripción Premium de un hogar.
/// Se deriva de HomePremiumStatus + campos adicionales del hogar.
@freezed
class SubscriptionState with _$SubscriptionState {
  const factory SubscriptionState.free() = SubscriptionFree;

  const factory SubscriptionState.active({
    required String plan,
    required DateTime endsAt,
    required bool autoRenew,
  }) = SubscriptionActive;

  const factory SubscriptionState.cancelledPendingEnd({
    required String plan,
    required DateTime endsAt,
  }) = SubscriptionCancelledPendingEnd;

  const factory SubscriptionState.rescue({
    required String plan,
    required DateTime? endsAt,
    required int daysLeft,
  }) = SubscriptionRescue;

  const factory SubscriptionState.expiredFree() = SubscriptionExpiredFree;

  const factory SubscriptionState.restorable({
    required DateTime restoreUntil,
  }) = SubscriptionRestorable;

  const factory SubscriptionState.purged() = SubscriptionPurged;
}
