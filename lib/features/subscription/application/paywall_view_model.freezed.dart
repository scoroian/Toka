// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'paywall_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$PaywallVMState {
  bool get purchasedSuccessfully => throw _privateConstructorUsedError;
  String? get purchaseError => throw _privateConstructorUsedError;

  /// Create a copy of _PaywallVMState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$PaywallVMStateCopyWith<_PaywallVMState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$PaywallVMStateCopyWith<$Res> {
  factory _$PaywallVMStateCopyWith(
          _PaywallVMState value, $Res Function(_PaywallVMState) then) =
      __$PaywallVMStateCopyWithImpl<$Res, _PaywallVMState>;
  @useResult
  $Res call({bool purchasedSuccessfully, String? purchaseError});
}

/// @nodoc
class __$PaywallVMStateCopyWithImpl<$Res, $Val extends _PaywallVMState>
    implements _$PaywallVMStateCopyWith<$Res> {
  __$PaywallVMStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of _PaywallVMState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? purchasedSuccessfully = null,
    Object? purchaseError = freezed,
  }) {
    return _then(_value.copyWith(
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
abstract class _$$_PaywallVMStateImplCopyWith<$Res>
    implements _$PaywallVMStateCopyWith<$Res> {
  factory _$$_PaywallVMStateImplCopyWith(_$_PaywallVMStateImpl value,
          $Res Function(_$_PaywallVMStateImpl) then) =
      __$$_PaywallVMStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool purchasedSuccessfully, String? purchaseError});
}

/// @nodoc
class __$$_PaywallVMStateImplCopyWithImpl<$Res>
    extends __$PaywallVMStateCopyWithImpl<$Res, _$_PaywallVMStateImpl>
    implements _$$_PaywallVMStateImplCopyWith<$Res> {
  __$$_PaywallVMStateImplCopyWithImpl(
      _$_PaywallVMStateImpl _value, $Res Function(_$_PaywallVMStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of _PaywallVMState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? purchasedSuccessfully = null,
    Object? purchaseError = freezed,
  }) {
    return _then(_$_PaywallVMStateImpl(
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

class _$_PaywallVMStateImpl implements __PaywallVMState {
  const _$_PaywallVMStateImpl(
      {this.purchasedSuccessfully = false, this.purchaseError});

  @override
  @JsonKey()
  final bool purchasedSuccessfully;
  @override
  final String? purchaseError;

  @override
  String toString() {
    return '_PaywallVMState(purchasedSuccessfully: $purchasedSuccessfully, purchaseError: $purchaseError)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_PaywallVMStateImpl &&
            (identical(other.purchasedSuccessfully, purchasedSuccessfully) ||
                other.purchasedSuccessfully == purchasedSuccessfully) &&
            (identical(other.purchaseError, purchaseError) ||
                other.purchaseError == purchaseError));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, purchasedSuccessfully, purchaseError);

  /// Create a copy of _PaywallVMState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$_PaywallVMStateImplCopyWith<_$_PaywallVMStateImpl> get copyWith =>
      __$$_PaywallVMStateImplCopyWithImpl<_$_PaywallVMStateImpl>(
          this, _$identity);
}

abstract class __PaywallVMState implements _PaywallVMState {
  const factory __PaywallVMState(
      {final bool purchasedSuccessfully,
      final String? purchaseError}) = _$_PaywallVMStateImpl;

  @override
  bool get purchasedSuccessfully;
  @override
  String? get purchaseError;

  /// Create a copy of _PaywallVMState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$_PaywallVMStateImplCopyWith<_$_PaywallVMStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
