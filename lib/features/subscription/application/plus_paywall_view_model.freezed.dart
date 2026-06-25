// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'plus_paywall_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$PlusPaywallState {
  BillingCycle get cycle => throw _privateConstructorUsedError;
  bool get purchasedSuccessfully => throw _privateConstructorUsedError;
  String? get purchaseError => throw _privateConstructorUsedError;

  /// Create a copy of _PlusPaywallState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$PlusPaywallStateCopyWith<_PlusPaywallState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$PlusPaywallStateCopyWith<$Res> {
  factory _$PlusPaywallStateCopyWith(
          _PlusPaywallState value, $Res Function(_PlusPaywallState) then) =
      __$PlusPaywallStateCopyWithImpl<$Res, _PlusPaywallState>;
  @useResult
  $Res call(
      {BillingCycle cycle, bool purchasedSuccessfully, String? purchaseError});
}

/// @nodoc
class __$PlusPaywallStateCopyWithImpl<$Res, $Val extends _PlusPaywallState>
    implements _$PlusPaywallStateCopyWith<$Res> {
  __$PlusPaywallStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of _PlusPaywallState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cycle = null,
    Object? purchasedSuccessfully = null,
    Object? purchaseError = freezed,
  }) {
    return _then(_value.copyWith(
      cycle: null == cycle
          ? _value.cycle
          : cycle // ignore: cast_nullable_to_non_nullable
              as BillingCycle,
      purchasedSuccessfully: null == purchasedSuccessfully
          ? _value.purchasedSuccessfully
          : purchasedSuccessfully // ignore: cast_nullable_to_non_nullable
              as bool,
      purchaseError: freezed == purchaseError
          ? _value.purchaseError
          : purchaseError // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_PlusPaywallStateImplCopyWith<$Res>
    implements _$PlusPaywallStateCopyWith<$Res> {
  factory _$$_PlusPaywallStateImplCopyWith(_$_PlusPaywallStateImpl value,
          $Res Function(_$_PlusPaywallStateImpl) then) =
      __$$_PlusPaywallStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {BillingCycle cycle, bool purchasedSuccessfully, String? purchaseError});
}

/// @nodoc
class __$$_PlusPaywallStateImplCopyWithImpl<$Res>
    extends __$PlusPaywallStateCopyWithImpl<$Res, _$_PlusPaywallStateImpl>
    implements _$$_PlusPaywallStateImplCopyWith<$Res> {
  __$$_PlusPaywallStateImplCopyWithImpl(_$_PlusPaywallStateImpl _value,
      $Res Function(_$_PlusPaywallStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of _PlusPaywallState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cycle = null,
    Object? purchasedSuccessfully = null,
    Object? purchaseError = freezed,
  }) {
    return _then(_$_PlusPaywallStateImpl(
      cycle: null == cycle
          ? _value.cycle
          : cycle // ignore: cast_nullable_to_non_nullable
              as BillingCycle,
      purchasedSuccessfully: null == purchasedSuccessfully
          ? _value.purchasedSuccessfully
          : purchasedSuccessfully // ignore: cast_nullable_to_non_nullable
              as bool,
      purchaseError: freezed == purchaseError
          ? _value.purchaseError
          : purchaseError // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$_PlusPaywallStateImpl implements __PlusPaywallState {
  const _$_PlusPaywallStateImpl(
      {this.cycle = BillingCycle.annual,
      this.purchasedSuccessfully = false,
      this.purchaseError});

  @override
  @JsonKey()
  final BillingCycle cycle;
  @override
  @JsonKey()
  final bool purchasedSuccessfully;
  @override
  final String? purchaseError;

  @override
  String toString() {
    return '_PlusPaywallState(cycle: $cycle, purchasedSuccessfully: $purchasedSuccessfully, purchaseError: $purchaseError)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_PlusPaywallStateImpl &&
            (identical(other.cycle, cycle) || other.cycle == cycle) &&
            (identical(other.purchasedSuccessfully, purchasedSuccessfully) ||
                other.purchasedSuccessfully == purchasedSuccessfully) &&
            (identical(other.purchaseError, purchaseError) ||
                other.purchaseError == purchaseError));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, cycle, purchasedSuccessfully, purchaseError);

  /// Create a copy of _PlusPaywallState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$_PlusPaywallStateImplCopyWith<_$_PlusPaywallStateImpl> get copyWith =>
      __$$_PlusPaywallStateImplCopyWithImpl<_$_PlusPaywallStateImpl>(
          this, _$identity);
}

abstract class __PlusPaywallState implements _PlusPaywallState {
  const factory __PlusPaywallState(
      {final BillingCycle cycle,
      final bool purchasedSuccessfully,
      final String? purchaseError}) = _$_PlusPaywallStateImpl;

  @override
  BillingCycle get cycle;
  @override
  bool get purchasedSuccessfully;
  @override
  String? get purchaseError;

  /// Create a copy of _PlusPaywallState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$_PlusPaywallStateImplCopyWith<_$_PlusPaywallStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
