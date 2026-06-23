// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_diagnostics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$HomeDiagnostics {
  String get homeId => throw _privateConstructorUsedError;
  String? get generatedAt => throw _privateConstructorUsedError;
  String? get requestedBy => throw _privateConstructorUsedError;
  DiagHome? get home => throw _privateConstructorUsedError;
  int get memberCount => throw _privateConstructorUsedError;
  List<DiagMember> get members => throw _privateConstructorUsedError;
  List<DiagTask> get upcomingTasks => throw _privateConstructorUsedError;
  List<DiagEvent> get recentEvents => throw _privateConstructorUsedError;

  /// Create a copy of HomeDiagnostics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HomeDiagnosticsCopyWith<HomeDiagnostics> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HomeDiagnosticsCopyWith<$Res> {
  factory $HomeDiagnosticsCopyWith(
          HomeDiagnostics value, $Res Function(HomeDiagnostics) then) =
      _$HomeDiagnosticsCopyWithImpl<$Res, HomeDiagnostics>;
  @useResult
  $Res call(
      {String homeId,
      String? generatedAt,
      String? requestedBy,
      DiagHome? home,
      int memberCount,
      List<DiagMember> members,
      List<DiagTask> upcomingTasks,
      List<DiagEvent> recentEvents});

  $DiagHomeCopyWith<$Res>? get home;
}

/// @nodoc
class _$HomeDiagnosticsCopyWithImpl<$Res, $Val extends HomeDiagnostics>
    implements $HomeDiagnosticsCopyWith<$Res> {
  _$HomeDiagnosticsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HomeDiagnostics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? homeId = null,
    Object? generatedAt = freezed,
    Object? requestedBy = freezed,
    Object? home = freezed,
    Object? memberCount = null,
    Object? members = null,
    Object? upcomingTasks = null,
    Object? recentEvents = null,
  }) {
    return _then(_value.copyWith(
      homeId: null == homeId
          ? _value.homeId
          : homeId // ignore: cast_nullable_to_non_nullable
              as String,
      generatedAt: freezed == generatedAt
          ? _value.generatedAt
          : generatedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      requestedBy: freezed == requestedBy
          ? _value.requestedBy
          : requestedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      home: freezed == home
          ? _value.home
          : home // ignore: cast_nullable_to_non_nullable
              as DiagHome?,
      memberCount: null == memberCount
          ? _value.memberCount
          : memberCount // ignore: cast_nullable_to_non_nullable
              as int,
      members: null == members
          ? _value.members
          : members // ignore: cast_nullable_to_non_nullable
              as List<DiagMember>,
      upcomingTasks: null == upcomingTasks
          ? _value.upcomingTasks
          : upcomingTasks // ignore: cast_nullable_to_non_nullable
              as List<DiagTask>,
      recentEvents: null == recentEvents
          ? _value.recentEvents
          : recentEvents // ignore: cast_nullable_to_non_nullable
              as List<DiagEvent>,
    ) as $Val);
  }

  /// Create a copy of HomeDiagnostics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DiagHomeCopyWith<$Res>? get home {
    if (_value.home == null) {
      return null;
    }

    return $DiagHomeCopyWith<$Res>(_value.home!, (value) {
      return _then(_value.copyWith(home: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$HomeDiagnosticsImplCopyWith<$Res>
    implements $HomeDiagnosticsCopyWith<$Res> {
  factory _$$HomeDiagnosticsImplCopyWith(_$HomeDiagnosticsImpl value,
          $Res Function(_$HomeDiagnosticsImpl) then) =
      __$$HomeDiagnosticsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String homeId,
      String? generatedAt,
      String? requestedBy,
      DiagHome? home,
      int memberCount,
      List<DiagMember> members,
      List<DiagTask> upcomingTasks,
      List<DiagEvent> recentEvents});

  @override
  $DiagHomeCopyWith<$Res>? get home;
}

/// @nodoc
class __$$HomeDiagnosticsImplCopyWithImpl<$Res>
    extends _$HomeDiagnosticsCopyWithImpl<$Res, _$HomeDiagnosticsImpl>
    implements _$$HomeDiagnosticsImplCopyWith<$Res> {
  __$$HomeDiagnosticsImplCopyWithImpl(
      _$HomeDiagnosticsImpl _value, $Res Function(_$HomeDiagnosticsImpl) _then)
      : super(_value, _then);

  /// Create a copy of HomeDiagnostics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? homeId = null,
    Object? generatedAt = freezed,
    Object? requestedBy = freezed,
    Object? home = freezed,
    Object? memberCount = null,
    Object? members = null,
    Object? upcomingTasks = null,
    Object? recentEvents = null,
  }) {
    return _then(_$HomeDiagnosticsImpl(
      homeId: null == homeId
          ? _value.homeId
          : homeId // ignore: cast_nullable_to_non_nullable
              as String,
      generatedAt: freezed == generatedAt
          ? _value.generatedAt
          : generatedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      requestedBy: freezed == requestedBy
          ? _value.requestedBy
          : requestedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      home: freezed == home
          ? _value.home
          : home // ignore: cast_nullable_to_non_nullable
              as DiagHome?,
      memberCount: null == memberCount
          ? _value.memberCount
          : memberCount // ignore: cast_nullable_to_non_nullable
              as int,
      members: null == members
          ? _value._members
          : members // ignore: cast_nullable_to_non_nullable
              as List<DiagMember>,
      upcomingTasks: null == upcomingTasks
          ? _value._upcomingTasks
          : upcomingTasks // ignore: cast_nullable_to_non_nullable
              as List<DiagTask>,
      recentEvents: null == recentEvents
          ? _value._recentEvents
          : recentEvents // ignore: cast_nullable_to_non_nullable
              as List<DiagEvent>,
    ));
  }
}

/// @nodoc

class _$HomeDiagnosticsImpl implements _HomeDiagnostics {
  const _$HomeDiagnosticsImpl(
      {required this.homeId,
      required this.generatedAt,
      required this.requestedBy,
      required this.home,
      required this.memberCount,
      required final List<DiagMember> members,
      required final List<DiagTask> upcomingTasks,
      required final List<DiagEvent> recentEvents})
      : _members = members,
        _upcomingTasks = upcomingTasks,
        _recentEvents = recentEvents;

  @override
  final String homeId;
  @override
  final String? generatedAt;
  @override
  final String? requestedBy;
  @override
  final DiagHome? home;
  @override
  final int memberCount;
  final List<DiagMember> _members;
  @override
  List<DiagMember> get members {
    if (_members is EqualUnmodifiableListView) return _members;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_members);
  }

  final List<DiagTask> _upcomingTasks;
  @override
  List<DiagTask> get upcomingTasks {
    if (_upcomingTasks is EqualUnmodifiableListView) return _upcomingTasks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_upcomingTasks);
  }

  final List<DiagEvent> _recentEvents;
  @override
  List<DiagEvent> get recentEvents {
    if (_recentEvents is EqualUnmodifiableListView) return _recentEvents;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_recentEvents);
  }

  @override
  String toString() {
    return 'HomeDiagnostics(homeId: $homeId, generatedAt: $generatedAt, requestedBy: $requestedBy, home: $home, memberCount: $memberCount, members: $members, upcomingTasks: $upcomingTasks, recentEvents: $recentEvents)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HomeDiagnosticsImpl &&
            (identical(other.homeId, homeId) || other.homeId == homeId) &&
            (identical(other.generatedAt, generatedAt) ||
                other.generatedAt == generatedAt) &&
            (identical(other.requestedBy, requestedBy) ||
                other.requestedBy == requestedBy) &&
            (identical(other.home, home) || other.home == home) &&
            (identical(other.memberCount, memberCount) ||
                other.memberCount == memberCount) &&
            const DeepCollectionEquality().equals(other._members, _members) &&
            const DeepCollectionEquality()
                .equals(other._upcomingTasks, _upcomingTasks) &&
            const DeepCollectionEquality()
                .equals(other._recentEvents, _recentEvents));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      homeId,
      generatedAt,
      requestedBy,
      home,
      memberCount,
      const DeepCollectionEquality().hash(_members),
      const DeepCollectionEquality().hash(_upcomingTasks),
      const DeepCollectionEquality().hash(_recentEvents));

  /// Create a copy of HomeDiagnostics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HomeDiagnosticsImplCopyWith<_$HomeDiagnosticsImpl> get copyWith =>
      __$$HomeDiagnosticsImplCopyWithImpl<_$HomeDiagnosticsImpl>(
          this, _$identity);
}

abstract class _HomeDiagnostics implements HomeDiagnostics {
  const factory _HomeDiagnostics(
      {required final String homeId,
      required final String? generatedAt,
      required final String? requestedBy,
      required final DiagHome? home,
      required final int memberCount,
      required final List<DiagMember> members,
      required final List<DiagTask> upcomingTasks,
      required final List<DiagEvent> recentEvents}) = _$HomeDiagnosticsImpl;

  @override
  String get homeId;
  @override
  String? get generatedAt;
  @override
  String? get requestedBy;
  @override
  DiagHome? get home;
  @override
  int get memberCount;
  @override
  List<DiagMember> get members;
  @override
  List<DiagTask> get upcomingTasks;
  @override
  List<DiagEvent> get recentEvents;

  /// Create a copy of HomeDiagnostics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HomeDiagnosticsImplCopyWith<_$HomeDiagnosticsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$DiagHome {
  String? get name => throw _privateConstructorUsedError;
  String get premiumStatus => throw _privateConstructorUsedError;
  String? get premiumPlan => throw _privateConstructorUsedError;
  String? get premiumEndsAt => throw _privateConstructorUsedError;
  String? get restoreUntil => throw _privateConstructorUsedError;
  String? get ownerUid => throw _privateConstructorUsedError;
  String? get currentPayerUid => throw _privateConstructorUsedError;
  String? get timezone => throw _privateConstructorUsedError;
  bool? get autoRenewEnabled => throw _privateConstructorUsedError;

  /// Create a copy of DiagHome
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DiagHomeCopyWith<DiagHome> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DiagHomeCopyWith<$Res> {
  factory $DiagHomeCopyWith(DiagHome value, $Res Function(DiagHome) then) =
      _$DiagHomeCopyWithImpl<$Res, DiagHome>;
  @useResult
  $Res call(
      {String? name,
      String premiumStatus,
      String? premiumPlan,
      String? premiumEndsAt,
      String? restoreUntil,
      String? ownerUid,
      String? currentPayerUid,
      String? timezone,
      bool? autoRenewEnabled});
}

/// @nodoc
class _$DiagHomeCopyWithImpl<$Res, $Val extends DiagHome>
    implements $DiagHomeCopyWith<$Res> {
  _$DiagHomeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DiagHome
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = freezed,
    Object? premiumStatus = null,
    Object? premiumPlan = freezed,
    Object? premiumEndsAt = freezed,
    Object? restoreUntil = freezed,
    Object? ownerUid = freezed,
    Object? currentPayerUid = freezed,
    Object? timezone = freezed,
    Object? autoRenewEnabled = freezed,
  }) {
    return _then(_value.copyWith(
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      premiumStatus: null == premiumStatus
          ? _value.premiumStatus
          : premiumStatus // ignore: cast_nullable_to_non_nullable
              as String,
      premiumPlan: freezed == premiumPlan
          ? _value.premiumPlan
          : premiumPlan // ignore: cast_nullable_to_non_nullable
              as String?,
      premiumEndsAt: freezed == premiumEndsAt
          ? _value.premiumEndsAt
          : premiumEndsAt // ignore: cast_nullable_to_non_nullable
              as String?,
      restoreUntil: freezed == restoreUntil
          ? _value.restoreUntil
          : restoreUntil // ignore: cast_nullable_to_non_nullable
              as String?,
      ownerUid: freezed == ownerUid
          ? _value.ownerUid
          : ownerUid // ignore: cast_nullable_to_non_nullable
              as String?,
      currentPayerUid: freezed == currentPayerUid
          ? _value.currentPayerUid
          : currentPayerUid // ignore: cast_nullable_to_non_nullable
              as String?,
      timezone: freezed == timezone
          ? _value.timezone
          : timezone // ignore: cast_nullable_to_non_nullable
              as String?,
      autoRenewEnabled: freezed == autoRenewEnabled
          ? _value.autoRenewEnabled
          : autoRenewEnabled // ignore: cast_nullable_to_non_nullable
              as bool?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DiagHomeImplCopyWith<$Res>
    implements $DiagHomeCopyWith<$Res> {
  factory _$$DiagHomeImplCopyWith(
          _$DiagHomeImpl value, $Res Function(_$DiagHomeImpl) then) =
      __$$DiagHomeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? name,
      String premiumStatus,
      String? premiumPlan,
      String? premiumEndsAt,
      String? restoreUntil,
      String? ownerUid,
      String? currentPayerUid,
      String? timezone,
      bool? autoRenewEnabled});
}

/// @nodoc
class __$$DiagHomeImplCopyWithImpl<$Res>
    extends _$DiagHomeCopyWithImpl<$Res, _$DiagHomeImpl>
    implements _$$DiagHomeImplCopyWith<$Res> {
  __$$DiagHomeImplCopyWithImpl(
      _$DiagHomeImpl _value, $Res Function(_$DiagHomeImpl) _then)
      : super(_value, _then);

  /// Create a copy of DiagHome
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = freezed,
    Object? premiumStatus = null,
    Object? premiumPlan = freezed,
    Object? premiumEndsAt = freezed,
    Object? restoreUntil = freezed,
    Object? ownerUid = freezed,
    Object? currentPayerUid = freezed,
    Object? timezone = freezed,
    Object? autoRenewEnabled = freezed,
  }) {
    return _then(_$DiagHomeImpl(
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      premiumStatus: null == premiumStatus
          ? _value.premiumStatus
          : premiumStatus // ignore: cast_nullable_to_non_nullable
              as String,
      premiumPlan: freezed == premiumPlan
          ? _value.premiumPlan
          : premiumPlan // ignore: cast_nullable_to_non_nullable
              as String?,
      premiumEndsAt: freezed == premiumEndsAt
          ? _value.premiumEndsAt
          : premiumEndsAt // ignore: cast_nullable_to_non_nullable
              as String?,
      restoreUntil: freezed == restoreUntil
          ? _value.restoreUntil
          : restoreUntil // ignore: cast_nullable_to_non_nullable
              as String?,
      ownerUid: freezed == ownerUid
          ? _value.ownerUid
          : ownerUid // ignore: cast_nullable_to_non_nullable
              as String?,
      currentPayerUid: freezed == currentPayerUid
          ? _value.currentPayerUid
          : currentPayerUid // ignore: cast_nullable_to_non_nullable
              as String?,
      timezone: freezed == timezone
          ? _value.timezone
          : timezone // ignore: cast_nullable_to_non_nullable
              as String?,
      autoRenewEnabled: freezed == autoRenewEnabled
          ? _value.autoRenewEnabled
          : autoRenewEnabled // ignore: cast_nullable_to_non_nullable
              as bool?,
    ));
  }
}

/// @nodoc

class _$DiagHomeImpl implements _DiagHome {
  const _$DiagHomeImpl(
      {required this.name,
      required this.premiumStatus,
      required this.premiumPlan,
      required this.premiumEndsAt,
      required this.restoreUntil,
      required this.ownerUid,
      required this.currentPayerUid,
      required this.timezone,
      required this.autoRenewEnabled});

  @override
  final String? name;
  @override
  final String premiumStatus;
  @override
  final String? premiumPlan;
  @override
  final String? premiumEndsAt;
  @override
  final String? restoreUntil;
  @override
  final String? ownerUid;
  @override
  final String? currentPayerUid;
  @override
  final String? timezone;
  @override
  final bool? autoRenewEnabled;

  @override
  String toString() {
    return 'DiagHome(name: $name, premiumStatus: $premiumStatus, premiumPlan: $premiumPlan, premiumEndsAt: $premiumEndsAt, restoreUntil: $restoreUntil, ownerUid: $ownerUid, currentPayerUid: $currentPayerUid, timezone: $timezone, autoRenewEnabled: $autoRenewEnabled)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DiagHomeImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.premiumStatus, premiumStatus) ||
                other.premiumStatus == premiumStatus) &&
            (identical(other.premiumPlan, premiumPlan) ||
                other.premiumPlan == premiumPlan) &&
            (identical(other.premiumEndsAt, premiumEndsAt) ||
                other.premiumEndsAt == premiumEndsAt) &&
            (identical(other.restoreUntil, restoreUntil) ||
                other.restoreUntil == restoreUntil) &&
            (identical(other.ownerUid, ownerUid) ||
                other.ownerUid == ownerUid) &&
            (identical(other.currentPayerUid, currentPayerUid) ||
                other.currentPayerUid == currentPayerUid) &&
            (identical(other.timezone, timezone) ||
                other.timezone == timezone) &&
            (identical(other.autoRenewEnabled, autoRenewEnabled) ||
                other.autoRenewEnabled == autoRenewEnabled));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      name,
      premiumStatus,
      premiumPlan,
      premiumEndsAt,
      restoreUntil,
      ownerUid,
      currentPayerUid,
      timezone,
      autoRenewEnabled);

  /// Create a copy of DiagHome
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DiagHomeImplCopyWith<_$DiagHomeImpl> get copyWith =>
      __$$DiagHomeImplCopyWithImpl<_$DiagHomeImpl>(this, _$identity);
}

abstract class _DiagHome implements DiagHome {
  const factory _DiagHome(
      {required final String? name,
      required final String premiumStatus,
      required final String? premiumPlan,
      required final String? premiumEndsAt,
      required final String? restoreUntil,
      required final String? ownerUid,
      required final String? currentPayerUid,
      required final String? timezone,
      required final bool? autoRenewEnabled}) = _$DiagHomeImpl;

  @override
  String? get name;
  @override
  String get premiumStatus;
  @override
  String? get premiumPlan;
  @override
  String? get premiumEndsAt;
  @override
  String? get restoreUntil;
  @override
  String? get ownerUid;
  @override
  String? get currentPayerUid;
  @override
  String? get timezone;
  @override
  bool? get autoRenewEnabled;

  /// Create a copy of DiagHome
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DiagHomeImplCopyWith<_$DiagHomeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$DiagMember {
  String get uid => throw _privateConstructorUsedError;
  String? get nickname => throw _privateConstructorUsedError;
  String? get role => throw _privateConstructorUsedError;
  String? get status => throw _privateConstructorUsedError;
  String? get billingState => throw _privateConstructorUsedError;
  int get tasksCompleted => throw _privateConstructorUsedError;
  double get averageScore => throw _privateConstructorUsedError;
  int get ratingsCount => throw _privateConstructorUsedError;
  int get currentStreak => throw _privateConstructorUsedError;
  String? get phoneVisibility => throw _privateConstructorUsedError;
  bool get hasPhone => throw _privateConstructorUsedError;
  bool get hasFcmToken => throw _privateConstructorUsedError;

  /// Create a copy of DiagMember
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DiagMemberCopyWith<DiagMember> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DiagMemberCopyWith<$Res> {
  factory $DiagMemberCopyWith(
          DiagMember value, $Res Function(DiagMember) then) =
      _$DiagMemberCopyWithImpl<$Res, DiagMember>;
  @useResult
  $Res call(
      {String uid,
      String? nickname,
      String? role,
      String? status,
      String? billingState,
      int tasksCompleted,
      double averageScore,
      int ratingsCount,
      int currentStreak,
      String? phoneVisibility,
      bool hasPhone,
      bool hasFcmToken});
}

/// @nodoc
class _$DiagMemberCopyWithImpl<$Res, $Val extends DiagMember>
    implements $DiagMemberCopyWith<$Res> {
  _$DiagMemberCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DiagMember
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? nickname = freezed,
    Object? role = freezed,
    Object? status = freezed,
    Object? billingState = freezed,
    Object? tasksCompleted = null,
    Object? averageScore = null,
    Object? ratingsCount = null,
    Object? currentStreak = null,
    Object? phoneVisibility = freezed,
    Object? hasPhone = null,
    Object? hasFcmToken = null,
  }) {
    return _then(_value.copyWith(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      nickname: freezed == nickname
          ? _value.nickname
          : nickname // ignore: cast_nullable_to_non_nullable
              as String?,
      role: freezed == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String?,
      status: freezed == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      billingState: freezed == billingState
          ? _value.billingState
          : billingState // ignore: cast_nullable_to_non_nullable
              as String?,
      tasksCompleted: null == tasksCompleted
          ? _value.tasksCompleted
          : tasksCompleted // ignore: cast_nullable_to_non_nullable
              as int,
      averageScore: null == averageScore
          ? _value.averageScore
          : averageScore // ignore: cast_nullable_to_non_nullable
              as double,
      ratingsCount: null == ratingsCount
          ? _value.ratingsCount
          : ratingsCount // ignore: cast_nullable_to_non_nullable
              as int,
      currentStreak: null == currentStreak
          ? _value.currentStreak
          : currentStreak // ignore: cast_nullable_to_non_nullable
              as int,
      phoneVisibility: freezed == phoneVisibility
          ? _value.phoneVisibility
          : phoneVisibility // ignore: cast_nullable_to_non_nullable
              as String?,
      hasPhone: null == hasPhone
          ? _value.hasPhone
          : hasPhone // ignore: cast_nullable_to_non_nullable
              as bool,
      hasFcmToken: null == hasFcmToken
          ? _value.hasFcmToken
          : hasFcmToken // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DiagMemberImplCopyWith<$Res>
    implements $DiagMemberCopyWith<$Res> {
  factory _$$DiagMemberImplCopyWith(
          _$DiagMemberImpl value, $Res Function(_$DiagMemberImpl) then) =
      __$$DiagMemberImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String uid,
      String? nickname,
      String? role,
      String? status,
      String? billingState,
      int tasksCompleted,
      double averageScore,
      int ratingsCount,
      int currentStreak,
      String? phoneVisibility,
      bool hasPhone,
      bool hasFcmToken});
}

/// @nodoc
class __$$DiagMemberImplCopyWithImpl<$Res>
    extends _$DiagMemberCopyWithImpl<$Res, _$DiagMemberImpl>
    implements _$$DiagMemberImplCopyWith<$Res> {
  __$$DiagMemberImplCopyWithImpl(
      _$DiagMemberImpl _value, $Res Function(_$DiagMemberImpl) _then)
      : super(_value, _then);

  /// Create a copy of DiagMember
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? nickname = freezed,
    Object? role = freezed,
    Object? status = freezed,
    Object? billingState = freezed,
    Object? tasksCompleted = null,
    Object? averageScore = null,
    Object? ratingsCount = null,
    Object? currentStreak = null,
    Object? phoneVisibility = freezed,
    Object? hasPhone = null,
    Object? hasFcmToken = null,
  }) {
    return _then(_$DiagMemberImpl(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      nickname: freezed == nickname
          ? _value.nickname
          : nickname // ignore: cast_nullable_to_non_nullable
              as String?,
      role: freezed == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String?,
      status: freezed == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      billingState: freezed == billingState
          ? _value.billingState
          : billingState // ignore: cast_nullable_to_non_nullable
              as String?,
      tasksCompleted: null == tasksCompleted
          ? _value.tasksCompleted
          : tasksCompleted // ignore: cast_nullable_to_non_nullable
              as int,
      averageScore: null == averageScore
          ? _value.averageScore
          : averageScore // ignore: cast_nullable_to_non_nullable
              as double,
      ratingsCount: null == ratingsCount
          ? _value.ratingsCount
          : ratingsCount // ignore: cast_nullable_to_non_nullable
              as int,
      currentStreak: null == currentStreak
          ? _value.currentStreak
          : currentStreak // ignore: cast_nullable_to_non_nullable
              as int,
      phoneVisibility: freezed == phoneVisibility
          ? _value.phoneVisibility
          : phoneVisibility // ignore: cast_nullable_to_non_nullable
              as String?,
      hasPhone: null == hasPhone
          ? _value.hasPhone
          : hasPhone // ignore: cast_nullable_to_non_nullable
              as bool,
      hasFcmToken: null == hasFcmToken
          ? _value.hasFcmToken
          : hasFcmToken // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$DiagMemberImpl implements _DiagMember {
  const _$DiagMemberImpl(
      {required this.uid,
      required this.nickname,
      required this.role,
      required this.status,
      required this.billingState,
      required this.tasksCompleted,
      required this.averageScore,
      required this.ratingsCount,
      required this.currentStreak,
      required this.phoneVisibility,
      required this.hasPhone,
      required this.hasFcmToken});

  @override
  final String uid;
  @override
  final String? nickname;
  @override
  final String? role;
  @override
  final String? status;
  @override
  final String? billingState;
  @override
  final int tasksCompleted;
  @override
  final double averageScore;
  @override
  final int ratingsCount;
  @override
  final int currentStreak;
  @override
  final String? phoneVisibility;
  @override
  final bool hasPhone;
  @override
  final bool hasFcmToken;

  @override
  String toString() {
    return 'DiagMember(uid: $uid, nickname: $nickname, role: $role, status: $status, billingState: $billingState, tasksCompleted: $tasksCompleted, averageScore: $averageScore, ratingsCount: $ratingsCount, currentStreak: $currentStreak, phoneVisibility: $phoneVisibility, hasPhone: $hasPhone, hasFcmToken: $hasFcmToken)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DiagMemberImpl &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.nickname, nickname) ||
                other.nickname == nickname) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.billingState, billingState) ||
                other.billingState == billingState) &&
            (identical(other.tasksCompleted, tasksCompleted) ||
                other.tasksCompleted == tasksCompleted) &&
            (identical(other.averageScore, averageScore) ||
                other.averageScore == averageScore) &&
            (identical(other.ratingsCount, ratingsCount) ||
                other.ratingsCount == ratingsCount) &&
            (identical(other.currentStreak, currentStreak) ||
                other.currentStreak == currentStreak) &&
            (identical(other.phoneVisibility, phoneVisibility) ||
                other.phoneVisibility == phoneVisibility) &&
            (identical(other.hasPhone, hasPhone) ||
                other.hasPhone == hasPhone) &&
            (identical(other.hasFcmToken, hasFcmToken) ||
                other.hasFcmToken == hasFcmToken));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      uid,
      nickname,
      role,
      status,
      billingState,
      tasksCompleted,
      averageScore,
      ratingsCount,
      currentStreak,
      phoneVisibility,
      hasPhone,
      hasFcmToken);

  /// Create a copy of DiagMember
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DiagMemberImplCopyWith<_$DiagMemberImpl> get copyWith =>
      __$$DiagMemberImplCopyWithImpl<_$DiagMemberImpl>(this, _$identity);
}

abstract class _DiagMember implements DiagMember {
  const factory _DiagMember(
      {required final String uid,
      required final String? nickname,
      required final String? role,
      required final String? status,
      required final String? billingState,
      required final int tasksCompleted,
      required final double averageScore,
      required final int ratingsCount,
      required final int currentStreak,
      required final String? phoneVisibility,
      required final bool hasPhone,
      required final bool hasFcmToken}) = _$DiagMemberImpl;

  @override
  String get uid;
  @override
  String? get nickname;
  @override
  String? get role;
  @override
  String? get status;
  @override
  String? get billingState;
  @override
  int get tasksCompleted;
  @override
  double get averageScore;
  @override
  int get ratingsCount;
  @override
  int get currentStreak;
  @override
  String? get phoneVisibility;
  @override
  bool get hasPhone;
  @override
  bool get hasFcmToken;

  /// Create a copy of DiagMember
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DiagMemberImplCopyWith<_$DiagMemberImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$DiagTask {
  String get taskId => throw _privateConstructorUsedError;
  String? get title => throw _privateConstructorUsedError;
  String? get status => throw _privateConstructorUsedError;
  String? get nextDueAt => throw _privateConstructorUsedError;
  String? get currentAssigneeUid => throw _privateConstructorUsedError;
  String? get recurrenceType => throw _privateConstructorUsedError;

  /// Create a copy of DiagTask
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DiagTaskCopyWith<DiagTask> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DiagTaskCopyWith<$Res> {
  factory $DiagTaskCopyWith(DiagTask value, $Res Function(DiagTask) then) =
      _$DiagTaskCopyWithImpl<$Res, DiagTask>;
  @useResult
  $Res call(
      {String taskId,
      String? title,
      String? status,
      String? nextDueAt,
      String? currentAssigneeUid,
      String? recurrenceType});
}

/// @nodoc
class _$DiagTaskCopyWithImpl<$Res, $Val extends DiagTask>
    implements $DiagTaskCopyWith<$Res> {
  _$DiagTaskCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DiagTask
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? taskId = null,
    Object? title = freezed,
    Object? status = freezed,
    Object? nextDueAt = freezed,
    Object? currentAssigneeUid = freezed,
    Object? recurrenceType = freezed,
  }) {
    return _then(_value.copyWith(
      taskId: null == taskId
          ? _value.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      status: freezed == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      nextDueAt: freezed == nextDueAt
          ? _value.nextDueAt
          : nextDueAt // ignore: cast_nullable_to_non_nullable
              as String?,
      currentAssigneeUid: freezed == currentAssigneeUid
          ? _value.currentAssigneeUid
          : currentAssigneeUid // ignore: cast_nullable_to_non_nullable
              as String?,
      recurrenceType: freezed == recurrenceType
          ? _value.recurrenceType
          : recurrenceType // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DiagTaskImplCopyWith<$Res>
    implements $DiagTaskCopyWith<$Res> {
  factory _$$DiagTaskImplCopyWith(
          _$DiagTaskImpl value, $Res Function(_$DiagTaskImpl) then) =
      __$$DiagTaskImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String taskId,
      String? title,
      String? status,
      String? nextDueAt,
      String? currentAssigneeUid,
      String? recurrenceType});
}

/// @nodoc
class __$$DiagTaskImplCopyWithImpl<$Res>
    extends _$DiagTaskCopyWithImpl<$Res, _$DiagTaskImpl>
    implements _$$DiagTaskImplCopyWith<$Res> {
  __$$DiagTaskImplCopyWithImpl(
      _$DiagTaskImpl _value, $Res Function(_$DiagTaskImpl) _then)
      : super(_value, _then);

  /// Create a copy of DiagTask
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? taskId = null,
    Object? title = freezed,
    Object? status = freezed,
    Object? nextDueAt = freezed,
    Object? currentAssigneeUid = freezed,
    Object? recurrenceType = freezed,
  }) {
    return _then(_$DiagTaskImpl(
      taskId: null == taskId
          ? _value.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      status: freezed == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      nextDueAt: freezed == nextDueAt
          ? _value.nextDueAt
          : nextDueAt // ignore: cast_nullable_to_non_nullable
              as String?,
      currentAssigneeUid: freezed == currentAssigneeUid
          ? _value.currentAssigneeUid
          : currentAssigneeUid // ignore: cast_nullable_to_non_nullable
              as String?,
      recurrenceType: freezed == recurrenceType
          ? _value.recurrenceType
          : recurrenceType // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$DiagTaskImpl implements _DiagTask {
  const _$DiagTaskImpl(
      {required this.taskId,
      required this.title,
      required this.status,
      required this.nextDueAt,
      required this.currentAssigneeUid,
      required this.recurrenceType});

  @override
  final String taskId;
  @override
  final String? title;
  @override
  final String? status;
  @override
  final String? nextDueAt;
  @override
  final String? currentAssigneeUid;
  @override
  final String? recurrenceType;

  @override
  String toString() {
    return 'DiagTask(taskId: $taskId, title: $title, status: $status, nextDueAt: $nextDueAt, currentAssigneeUid: $currentAssigneeUid, recurrenceType: $recurrenceType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DiagTaskImpl &&
            (identical(other.taskId, taskId) || other.taskId == taskId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.nextDueAt, nextDueAt) ||
                other.nextDueAt == nextDueAt) &&
            (identical(other.currentAssigneeUid, currentAssigneeUid) ||
                other.currentAssigneeUid == currentAssigneeUid) &&
            (identical(other.recurrenceType, recurrenceType) ||
                other.recurrenceType == recurrenceType));
  }

  @override
  int get hashCode => Object.hash(runtimeType, taskId, title, status, nextDueAt,
      currentAssigneeUid, recurrenceType);

  /// Create a copy of DiagTask
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DiagTaskImplCopyWith<_$DiagTaskImpl> get copyWith =>
      __$$DiagTaskImplCopyWithImpl<_$DiagTaskImpl>(this, _$identity);
}

abstract class _DiagTask implements DiagTask {
  const factory _DiagTask(
      {required final String taskId,
      required final String? title,
      required final String? status,
      required final String? nextDueAt,
      required final String? currentAssigneeUid,
      required final String? recurrenceType}) = _$DiagTaskImpl;

  @override
  String get taskId;
  @override
  String? get title;
  @override
  String? get status;
  @override
  String? get nextDueAt;
  @override
  String? get currentAssigneeUid;
  @override
  String? get recurrenceType;

  /// Create a copy of DiagTask
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DiagTaskImplCopyWith<_$DiagTaskImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$DiagEvent {
  String get eventId => throw _privateConstructorUsedError;
  String? get eventType => throw _privateConstructorUsedError;
  String? get taskId => throw _privateConstructorUsedError;
  String? get performerUid => throw _privateConstructorUsedError;
  String? get createdAt => throw _privateConstructorUsedError;

  /// Create a copy of DiagEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DiagEventCopyWith<DiagEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DiagEventCopyWith<$Res> {
  factory $DiagEventCopyWith(DiagEvent value, $Res Function(DiagEvent) then) =
      _$DiagEventCopyWithImpl<$Res, DiagEvent>;
  @useResult
  $Res call(
      {String eventId,
      String? eventType,
      String? taskId,
      String? performerUid,
      String? createdAt});
}

/// @nodoc
class _$DiagEventCopyWithImpl<$Res, $Val extends DiagEvent>
    implements $DiagEventCopyWith<$Res> {
  _$DiagEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DiagEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? eventId = null,
    Object? eventType = freezed,
    Object? taskId = freezed,
    Object? performerUid = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      eventId: null == eventId
          ? _value.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String,
      eventType: freezed == eventType
          ? _value.eventType
          : eventType // ignore: cast_nullable_to_non_nullable
              as String?,
      taskId: freezed == taskId
          ? _value.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String?,
      performerUid: freezed == performerUid
          ? _value.performerUid
          : performerUid // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DiagEventImplCopyWith<$Res>
    implements $DiagEventCopyWith<$Res> {
  factory _$$DiagEventImplCopyWith(
          _$DiagEventImpl value, $Res Function(_$DiagEventImpl) then) =
      __$$DiagEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String eventId,
      String? eventType,
      String? taskId,
      String? performerUid,
      String? createdAt});
}

/// @nodoc
class __$$DiagEventImplCopyWithImpl<$Res>
    extends _$DiagEventCopyWithImpl<$Res, _$DiagEventImpl>
    implements _$$DiagEventImplCopyWith<$Res> {
  __$$DiagEventImplCopyWithImpl(
      _$DiagEventImpl _value, $Res Function(_$DiagEventImpl) _then)
      : super(_value, _then);

  /// Create a copy of DiagEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? eventId = null,
    Object? eventType = freezed,
    Object? taskId = freezed,
    Object? performerUid = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$DiagEventImpl(
      eventId: null == eventId
          ? _value.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String,
      eventType: freezed == eventType
          ? _value.eventType
          : eventType // ignore: cast_nullable_to_non_nullable
              as String?,
      taskId: freezed == taskId
          ? _value.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String?,
      performerUid: freezed == performerUid
          ? _value.performerUid
          : performerUid // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$DiagEventImpl implements _DiagEvent {
  const _$DiagEventImpl(
      {required this.eventId,
      required this.eventType,
      required this.taskId,
      required this.performerUid,
      required this.createdAt});

  @override
  final String eventId;
  @override
  final String? eventType;
  @override
  final String? taskId;
  @override
  final String? performerUid;
  @override
  final String? createdAt;

  @override
  String toString() {
    return 'DiagEvent(eventId: $eventId, eventType: $eventType, taskId: $taskId, performerUid: $performerUid, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DiagEventImpl &&
            (identical(other.eventId, eventId) || other.eventId == eventId) &&
            (identical(other.eventType, eventType) ||
                other.eventType == eventType) &&
            (identical(other.taskId, taskId) || other.taskId == taskId) &&
            (identical(other.performerUid, performerUid) ||
                other.performerUid == performerUid) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, eventId, eventType, taskId, performerUid, createdAt);

  /// Create a copy of DiagEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DiagEventImplCopyWith<_$DiagEventImpl> get copyWith =>
      __$$DiagEventImplCopyWithImpl<_$DiagEventImpl>(this, _$identity);
}

abstract class _DiagEvent implements DiagEvent {
  const factory _DiagEvent(
      {required final String eventId,
      required final String? eventType,
      required final String? taskId,
      required final String? performerUid,
      required final String? createdAt}) = _$DiagEventImpl;

  @override
  String get eventId;
  @override
  String? get eventType;
  @override
  String? get taskId;
  @override
  String? get performerUid;
  @override
  String? get createdAt;

  /// Create a copy of DiagEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DiagEventImplCopyWith<_$DiagEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
