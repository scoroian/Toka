// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'member.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Member {
  String get uid => throw _privateConstructorUsedError;
  String get homeId => throw _privateConstructorUsedError;
  String get nickname => throw _privateConstructorUsedError;
  String? get photoUrl => throw _privateConstructorUsedError;
  String? get bio => throw _privateConstructorUsedError;
  String? get phone => throw _privateConstructorUsedError;
  String get phoneVisibility => throw _privateConstructorUsedError;
  MemberRole get role => throw _privateConstructorUsedError;
  MemberStatus get status => throw _privateConstructorUsedError;
  DateTime get joinedAt => throw _privateConstructorUsedError;
  int get tasksCompleted => throw _privateConstructorUsedError;
  int get passedCount => throw _privateConstructorUsedError;
  double get complianceRate => throw _privateConstructorUsedError;
  int get currentStreak => throw _privateConstructorUsedError;
  double get averageScore => throw _privateConstructorUsedError;

  /// Create a copy of Member
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MemberCopyWith<Member> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MemberCopyWith<$Res> {
  factory $MemberCopyWith(Member value, $Res Function(Member) then) =
      _$MemberCopyWithImpl<$Res, Member>;
  @useResult
  $Res call(
      {String uid,
      String homeId,
      String nickname,
      String? photoUrl,
      String? bio,
      String? phone,
      String phoneVisibility,
      MemberRole role,
      MemberStatus status,
      DateTime joinedAt,
      int tasksCompleted,
      int passedCount,
      double complianceRate,
      int currentStreak,
      double averageScore});
}

/// @nodoc
class _$MemberCopyWithImpl<$Res, $Val extends Member>
    implements $MemberCopyWith<$Res> {
  _$MemberCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Member
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? homeId = null,
    Object? nickname = null,
    Object? photoUrl = freezed,
    Object? bio = freezed,
    Object? phone = freezed,
    Object? phoneVisibility = null,
    Object? role = null,
    Object? status = null,
    Object? joinedAt = null,
    Object? tasksCompleted = null,
    Object? passedCount = null,
    Object? complianceRate = null,
    Object? currentStreak = null,
    Object? averageScore = null,
  }) {
    return _then(_value.copyWith(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      homeId: null == homeId
          ? _value.homeId
          : homeId // ignore: cast_nullable_to_non_nullable
              as String,
      nickname: null == nickname
          ? _value.nickname
          : nickname // ignore: cast_nullable_to_non_nullable
              as String,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      bio: freezed == bio
          ? _value.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
      phone: freezed == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      phoneVisibility: null == phoneVisibility
          ? _value.phoneVisibility
          : phoneVisibility // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as MemberRole,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as MemberStatus,
      joinedAt: null == joinedAt
          ? _value.joinedAt
          : joinedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      tasksCompleted: null == tasksCompleted
          ? _value.tasksCompleted
          : tasksCompleted // ignore: cast_nullable_to_non_nullable
              as int,
      passedCount: null == passedCount
          ? _value.passedCount
          : passedCount // ignore: cast_nullable_to_non_nullable
              as int,
      complianceRate: null == complianceRate
          ? _value.complianceRate
          : complianceRate // ignore: cast_nullable_to_non_nullable
              as double,
      currentStreak: null == currentStreak
          ? _value.currentStreak
          : currentStreak // ignore: cast_nullable_to_non_nullable
              as int,
      averageScore: null == averageScore
          ? _value.averageScore
          : averageScore // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MemberImplCopyWith<$Res> implements $MemberCopyWith<$Res> {
  factory _$$MemberImplCopyWith(
          _$MemberImpl value, $Res Function(_$MemberImpl) then) =
      __$$MemberImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String uid,
      String homeId,
      String nickname,
      String? photoUrl,
      String? bio,
      String? phone,
      String phoneVisibility,
      MemberRole role,
      MemberStatus status,
      DateTime joinedAt,
      int tasksCompleted,
      int passedCount,
      double complianceRate,
      int currentStreak,
      double averageScore});
}

/// @nodoc
class __$$MemberImplCopyWithImpl<$Res>
    extends _$MemberCopyWithImpl<$Res, _$MemberImpl>
    implements _$$MemberImplCopyWith<$Res> {
  __$$MemberImplCopyWithImpl(
      _$MemberImpl _value, $Res Function(_$MemberImpl) _then)
      : super(_value, _then);

  /// Create a copy of Member
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? homeId = null,
    Object? nickname = null,
    Object? photoUrl = freezed,
    Object? bio = freezed,
    Object? phone = freezed,
    Object? phoneVisibility = null,
    Object? role = null,
    Object? status = null,
    Object? joinedAt = null,
    Object? tasksCompleted = null,
    Object? passedCount = null,
    Object? complianceRate = null,
    Object? currentStreak = null,
    Object? averageScore = null,
  }) {
    return _then(_$MemberImpl(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      homeId: null == homeId
          ? _value.homeId
          : homeId // ignore: cast_nullable_to_non_nullable
              as String,
      nickname: null == nickname
          ? _value.nickname
          : nickname // ignore: cast_nullable_to_non_nullable
              as String,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      bio: freezed == bio
          ? _value.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
      phone: freezed == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      phoneVisibility: null == phoneVisibility
          ? _value.phoneVisibility
          : phoneVisibility // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as MemberRole,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as MemberStatus,
      joinedAt: null == joinedAt
          ? _value.joinedAt
          : joinedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      tasksCompleted: null == tasksCompleted
          ? _value.tasksCompleted
          : tasksCompleted // ignore: cast_nullable_to_non_nullable
              as int,
      passedCount: null == passedCount
          ? _value.passedCount
          : passedCount // ignore: cast_nullable_to_non_nullable
              as int,
      complianceRate: null == complianceRate
          ? _value.complianceRate
          : complianceRate // ignore: cast_nullable_to_non_nullable
              as double,
      currentStreak: null == currentStreak
          ? _value.currentStreak
          : currentStreak // ignore: cast_nullable_to_non_nullable
              as int,
      averageScore: null == averageScore
          ? _value.averageScore
          : averageScore // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc

class _$MemberImpl implements _Member {
  const _$MemberImpl(
      {required this.uid,
      required this.homeId,
      required this.nickname,
      required this.photoUrl,
      required this.bio,
      required this.phone,
      required this.phoneVisibility,
      required this.role,
      required this.status,
      required this.joinedAt,
      required this.tasksCompleted,
      required this.passedCount,
      required this.complianceRate,
      required this.currentStreak,
      required this.averageScore});

  @override
  final String uid;
  @override
  final String homeId;
  @override
  final String nickname;
  @override
  final String? photoUrl;
  @override
  final String? bio;
  @override
  final String? phone;
  @override
  final String phoneVisibility;
  @override
  final MemberRole role;
  @override
  final MemberStatus status;
  @override
  final DateTime joinedAt;
  @override
  final int tasksCompleted;
  @override
  final int passedCount;
  @override
  final double complianceRate;
  @override
  final int currentStreak;
  @override
  final double averageScore;

  @override
  String toString() {
    return 'Member(uid: $uid, homeId: $homeId, nickname: $nickname, photoUrl: $photoUrl, bio: $bio, phone: $phone, phoneVisibility: $phoneVisibility, role: $role, status: $status, joinedAt: $joinedAt, tasksCompleted: $tasksCompleted, passedCount: $passedCount, complianceRate: $complianceRate, currentStreak: $currentStreak, averageScore: $averageScore)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MemberImpl &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.homeId, homeId) || other.homeId == homeId) &&
            (identical(other.nickname, nickname) ||
                other.nickname == nickname) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.bio, bio) || other.bio == bio) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.phoneVisibility, phoneVisibility) ||
                other.phoneVisibility == phoneVisibility) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.joinedAt, joinedAt) ||
                other.joinedAt == joinedAt) &&
            (identical(other.tasksCompleted, tasksCompleted) ||
                other.tasksCompleted == tasksCompleted) &&
            (identical(other.passedCount, passedCount) ||
                other.passedCount == passedCount) &&
            (identical(other.complianceRate, complianceRate) ||
                other.complianceRate == complianceRate) &&
            (identical(other.currentStreak, currentStreak) ||
                other.currentStreak == currentStreak) &&
            (identical(other.averageScore, averageScore) ||
                other.averageScore == averageScore));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      uid,
      homeId,
      nickname,
      photoUrl,
      bio,
      phone,
      phoneVisibility,
      role,
      status,
      joinedAt,
      tasksCompleted,
      passedCount,
      complianceRate,
      currentStreak,
      averageScore);

  /// Create a copy of Member
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MemberImplCopyWith<_$MemberImpl> get copyWith =>
      __$$MemberImplCopyWithImpl<_$MemberImpl>(this, _$identity);
}

abstract class _Member implements Member {
  const factory _Member(
      {required final String uid,
      required final String homeId,
      required final String nickname,
      required final String? photoUrl,
      required final String? bio,
      required final String? phone,
      required final String phoneVisibility,
      required final MemberRole role,
      required final MemberStatus status,
      required final DateTime joinedAt,
      required final int tasksCompleted,
      required final int passedCount,
      required final double complianceRate,
      required final int currentStreak,
      required final double averageScore}) = _$MemberImpl;

  @override
  String get uid;
  @override
  String get homeId;
  @override
  String get nickname;
  @override
  String? get photoUrl;
  @override
  String? get bio;
  @override
  String? get phone;
  @override
  String get phoneVisibility;
  @override
  MemberRole get role;
  @override
  MemberStatus get status;
  @override
  DateTime get joinedAt;
  @override
  int get tasksCompleted;
  @override
  int get passedCount;
  @override
  double get complianceRate;
  @override
  int get currentStreak;
  @override
  double get averageScore;

  /// Create a copy of Member
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MemberImplCopyWith<_$MemberImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
