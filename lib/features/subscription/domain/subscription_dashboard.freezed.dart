// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subscription_dashboard.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SubscriptionDashboard {
  String get homeId => throw _privateConstructorUsedError;
  HomePremiumStatus get status => throw _privateConstructorUsedError;
  String? get plan => throw _privateConstructorUsedError;
  DateTime? get endsAt => throw _privateConstructorUsedError;
  DateTime? get restoreUntil => throw _privateConstructorUsedError;
  bool get autoRenew => throw _privateConstructorUsedError;
  String? get currentPayerUid => throw _privateConstructorUsedError;
  PlanCounters get planCounters =>
      throw _privateConstructorUsedError; // Tier efectivo + tope, denormalizados por el backend en el dashboard
// (`premiumFlags`). `tier` es 'pareja'|'familia'|'grupo'|'free'|null (null
// con el flag de tiers OFF o dashboard legacy). El cliente solo los lee.
  String? get tier => throw _privateConstructorUsedError;
  int? get maxMembers =>
      throw _privateConstructorUsedError; // Packs de miembro activos (`premiumFlags.memberPacks`). null en dashboards
// legacy o con el flag de packs OFF. El cliente solo los lee.
  MemberPacks? get memberPacks => throw _privateConstructorUsedError;

  /// Create a copy of SubscriptionDashboard
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SubscriptionDashboardCopyWith<SubscriptionDashboard> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SubscriptionDashboardCopyWith<$Res> {
  factory $SubscriptionDashboardCopyWith(SubscriptionDashboard value,
          $Res Function(SubscriptionDashboard) then) =
      _$SubscriptionDashboardCopyWithImpl<$Res, SubscriptionDashboard>;
  @useResult
  $Res call(
      {String homeId,
      HomePremiumStatus status,
      String? plan,
      DateTime? endsAt,
      DateTime? restoreUntil,
      bool autoRenew,
      String? currentPayerUid,
      PlanCounters planCounters,
      String? tier,
      int? maxMembers,
      MemberPacks? memberPacks});

  $PlanCountersCopyWith<$Res> get planCounters;
  $MemberPacksCopyWith<$Res>? get memberPacks;
}

/// @nodoc
class _$SubscriptionDashboardCopyWithImpl<$Res,
        $Val extends SubscriptionDashboard>
    implements $SubscriptionDashboardCopyWith<$Res> {
  _$SubscriptionDashboardCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SubscriptionDashboard
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? homeId = null,
    Object? status = null,
    Object? plan = freezed,
    Object? endsAt = freezed,
    Object? restoreUntil = freezed,
    Object? autoRenew = null,
    Object? currentPayerUid = freezed,
    Object? planCounters = null,
    Object? tier = freezed,
    Object? maxMembers = freezed,
    Object? memberPacks = freezed,
  }) {
    return _then(_value.copyWith(
      homeId: null == homeId
          ? _value.homeId
          : homeId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as HomePremiumStatus,
      plan: freezed == plan
          ? _value.plan
          : plan // ignore: cast_nullable_to_non_nullable
              as String?,
      endsAt: freezed == endsAt
          ? _value.endsAt
          : endsAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      restoreUntil: freezed == restoreUntil
          ? _value.restoreUntil
          : restoreUntil // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      autoRenew: null == autoRenew
          ? _value.autoRenew
          : autoRenew // ignore: cast_nullable_to_non_nullable
              as bool,
      currentPayerUid: freezed == currentPayerUid
          ? _value.currentPayerUid
          : currentPayerUid // ignore: cast_nullable_to_non_nullable
              as String?,
      planCounters: null == planCounters
          ? _value.planCounters
          : planCounters // ignore: cast_nullable_to_non_nullable
              as PlanCounters,
      tier: freezed == tier
          ? _value.tier
          : tier // ignore: cast_nullable_to_non_nullable
              as String?,
      maxMembers: freezed == maxMembers
          ? _value.maxMembers
          : maxMembers // ignore: cast_nullable_to_non_nullable
              as int?,
      memberPacks: freezed == memberPacks
          ? _value.memberPacks
          : memberPacks // ignore: cast_nullable_to_non_nullable
              as MemberPacks?,
    ) as $Val);
  }

  /// Create a copy of SubscriptionDashboard
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlanCountersCopyWith<$Res> get planCounters {
    return $PlanCountersCopyWith<$Res>(_value.planCounters, (value) {
      return _then(_value.copyWith(planCounters: value) as $Val);
    });
  }

  /// Create a copy of SubscriptionDashboard
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MemberPacksCopyWith<$Res>? get memberPacks {
    if (_value.memberPacks == null) {
      return null;
    }

    return $MemberPacksCopyWith<$Res>(_value.memberPacks!, (value) {
      return _then(_value.copyWith(memberPacks: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SubscriptionDashboardImplCopyWith<$Res>
    implements $SubscriptionDashboardCopyWith<$Res> {
  factory _$$SubscriptionDashboardImplCopyWith(
          _$SubscriptionDashboardImpl value,
          $Res Function(_$SubscriptionDashboardImpl) then) =
      __$$SubscriptionDashboardImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String homeId,
      HomePremiumStatus status,
      String? plan,
      DateTime? endsAt,
      DateTime? restoreUntil,
      bool autoRenew,
      String? currentPayerUid,
      PlanCounters planCounters,
      String? tier,
      int? maxMembers,
      MemberPacks? memberPacks});

  @override
  $PlanCountersCopyWith<$Res> get planCounters;
  @override
  $MemberPacksCopyWith<$Res>? get memberPacks;
}

/// @nodoc
class __$$SubscriptionDashboardImplCopyWithImpl<$Res>
    extends _$SubscriptionDashboardCopyWithImpl<$Res,
        _$SubscriptionDashboardImpl>
    implements _$$SubscriptionDashboardImplCopyWith<$Res> {
  __$$SubscriptionDashboardImplCopyWithImpl(_$SubscriptionDashboardImpl _value,
      $Res Function(_$SubscriptionDashboardImpl) _then)
      : super(_value, _then);

  /// Create a copy of SubscriptionDashboard
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? homeId = null,
    Object? status = null,
    Object? plan = freezed,
    Object? endsAt = freezed,
    Object? restoreUntil = freezed,
    Object? autoRenew = null,
    Object? currentPayerUid = freezed,
    Object? planCounters = null,
    Object? tier = freezed,
    Object? maxMembers = freezed,
    Object? memberPacks = freezed,
  }) {
    return _then(_$SubscriptionDashboardImpl(
      homeId: null == homeId
          ? _value.homeId
          : homeId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as HomePremiumStatus,
      plan: freezed == plan
          ? _value.plan
          : plan // ignore: cast_nullable_to_non_nullable
              as String?,
      endsAt: freezed == endsAt
          ? _value.endsAt
          : endsAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      restoreUntil: freezed == restoreUntil
          ? _value.restoreUntil
          : restoreUntil // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      autoRenew: null == autoRenew
          ? _value.autoRenew
          : autoRenew // ignore: cast_nullable_to_non_nullable
              as bool,
      currentPayerUid: freezed == currentPayerUid
          ? _value.currentPayerUid
          : currentPayerUid // ignore: cast_nullable_to_non_nullable
              as String?,
      planCounters: null == planCounters
          ? _value.planCounters
          : planCounters // ignore: cast_nullable_to_non_nullable
              as PlanCounters,
      tier: freezed == tier
          ? _value.tier
          : tier // ignore: cast_nullable_to_non_nullable
              as String?,
      maxMembers: freezed == maxMembers
          ? _value.maxMembers
          : maxMembers // ignore: cast_nullable_to_non_nullable
              as int?,
      memberPacks: freezed == memberPacks
          ? _value.memberPacks
          : memberPacks // ignore: cast_nullable_to_non_nullable
              as MemberPacks?,
    ));
  }
}

/// @nodoc

class _$SubscriptionDashboardImpl extends _SubscriptionDashboard {
  const _$SubscriptionDashboardImpl(
      {required this.homeId,
      required this.status,
      required this.plan,
      required this.endsAt,
      required this.restoreUntil,
      required this.autoRenew,
      required this.currentPayerUid,
      required this.planCounters,
      this.tier,
      this.maxMembers,
      this.memberPacks})
      : super._();

  @override
  final String homeId;
  @override
  final HomePremiumStatus status;
  @override
  final String? plan;
  @override
  final DateTime? endsAt;
  @override
  final DateTime? restoreUntil;
  @override
  final bool autoRenew;
  @override
  final String? currentPayerUid;
  @override
  final PlanCounters planCounters;
// Tier efectivo + tope, denormalizados por el backend en el dashboard
// (`premiumFlags`). `tier` es 'pareja'|'familia'|'grupo'|'free'|null (null
// con el flag de tiers OFF o dashboard legacy). El cliente solo los lee.
  @override
  final String? tier;
  @override
  final int? maxMembers;
// Packs de miembro activos (`premiumFlags.memberPacks`). null en dashboards
// legacy o con el flag de packs OFF. El cliente solo los lee.
  @override
  final MemberPacks? memberPacks;

  @override
  String toString() {
    return 'SubscriptionDashboard(homeId: $homeId, status: $status, plan: $plan, endsAt: $endsAt, restoreUntil: $restoreUntil, autoRenew: $autoRenew, currentPayerUid: $currentPayerUid, planCounters: $planCounters, tier: $tier, maxMembers: $maxMembers, memberPacks: $memberPacks)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SubscriptionDashboardImpl &&
            (identical(other.homeId, homeId) || other.homeId == homeId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.plan, plan) || other.plan == plan) &&
            (identical(other.endsAt, endsAt) || other.endsAt == endsAt) &&
            (identical(other.restoreUntil, restoreUntil) ||
                other.restoreUntil == restoreUntil) &&
            (identical(other.autoRenew, autoRenew) ||
                other.autoRenew == autoRenew) &&
            (identical(other.currentPayerUid, currentPayerUid) ||
                other.currentPayerUid == currentPayerUid) &&
            (identical(other.planCounters, planCounters) ||
                other.planCounters == planCounters) &&
            (identical(other.tier, tier) || other.tier == tier) &&
            (identical(other.maxMembers, maxMembers) ||
                other.maxMembers == maxMembers) &&
            (identical(other.memberPacks, memberPacks) ||
                other.memberPacks == memberPacks));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      homeId,
      status,
      plan,
      endsAt,
      restoreUntil,
      autoRenew,
      currentPayerUid,
      planCounters,
      tier,
      maxMembers,
      memberPacks);

  /// Create a copy of SubscriptionDashboard
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SubscriptionDashboardImplCopyWith<_$SubscriptionDashboardImpl>
      get copyWith => __$$SubscriptionDashboardImplCopyWithImpl<
          _$SubscriptionDashboardImpl>(this, _$identity);
}

abstract class _SubscriptionDashboard extends SubscriptionDashboard {
  const factory _SubscriptionDashboard(
      {required final String homeId,
      required final HomePremiumStatus status,
      required final String? plan,
      required final DateTime? endsAt,
      required final DateTime? restoreUntil,
      required final bool autoRenew,
      required final String? currentPayerUid,
      required final PlanCounters planCounters,
      final String? tier,
      final int? maxMembers,
      final MemberPacks? memberPacks}) = _$SubscriptionDashboardImpl;
  const _SubscriptionDashboard._() : super._();

  @override
  String get homeId;
  @override
  HomePremiumStatus get status;
  @override
  String? get plan;
  @override
  DateTime? get endsAt;
  @override
  DateTime? get restoreUntil;
  @override
  bool get autoRenew;
  @override
  String? get currentPayerUid;
  @override
  PlanCounters
      get planCounters; // Tier efectivo + tope, denormalizados por el backend en el dashboard
// (`premiumFlags`). `tier` es 'pareja'|'familia'|'grupo'|'free'|null (null
// con el flag de tiers OFF o dashboard legacy). El cliente solo los lee.
  @override
  String? get tier;
  @override
  int?
      get maxMembers; // Packs de miembro activos (`premiumFlags.memberPacks`). null en dashboards
// legacy o con el flag de packs OFF. El cliente solo los lee.
  @override
  MemberPacks? get memberPacks;

  /// Create a copy of SubscriptionDashboard
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SubscriptionDashboardImplCopyWith<_$SubscriptionDashboardImpl>
      get copyWith => throw _privateConstructorUsedError;
}
