// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vacation_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$vacationViewModelHash() => r'a9573c738473cba20b38f8b3d69bff582e12928c';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [vacationViewModel].
@ProviderFor(vacationViewModel)
const vacationViewModelProvider = VacationViewModelFamily();

/// See also [vacationViewModel].
class VacationViewModelFamily extends Family<VacationViewModel> {
  /// See also [vacationViewModel].
  const VacationViewModelFamily();

  /// See also [vacationViewModel].
  VacationViewModelProvider call(
    String homeId,
    String uid,
  ) {
    return VacationViewModelProvider(
      homeId,
      uid,
    );
  }

  @override
  VacationViewModelProvider getProviderOverride(
    covariant VacationViewModelProvider provider,
  ) {
    return call(
      provider.homeId,
      provider.uid,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'vacationViewModelProvider';
}

/// See also [vacationViewModel].
class VacationViewModelProvider extends AutoDisposeProvider<VacationViewModel> {
  /// See also [vacationViewModel].
  VacationViewModelProvider(
    String homeId,
    String uid,
  ) : this._internal(
          (ref) => vacationViewModel(
            ref as VacationViewModelRef,
            homeId,
            uid,
          ),
          from: vacationViewModelProvider,
          name: r'vacationViewModelProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$vacationViewModelHash,
          dependencies: VacationViewModelFamily._dependencies,
          allTransitiveDependencies:
              VacationViewModelFamily._allTransitiveDependencies,
          homeId: homeId,
          uid: uid,
        );

  VacationViewModelProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.homeId,
    required this.uid,
  }) : super.internal();

  final String homeId;
  final String uid;

  @override
  Override overrideWith(
    VacationViewModel Function(VacationViewModelRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: VacationViewModelProvider._internal(
        (ref) => create(ref as VacationViewModelRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        homeId: homeId,
        uid: uid,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<VacationViewModel> createElement() {
    return _VacationViewModelProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is VacationViewModelProvider &&
        other.homeId == homeId &&
        other.uid == uid;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, homeId.hashCode);
    hash = _SystemHash.combine(hash, uid.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin VacationViewModelRef on AutoDisposeProviderRef<VacationViewModel> {
  /// The parameter `homeId` of this provider.
  String get homeId;

  /// The parameter `uid` of this provider.
  String get uid;
}

class _VacationViewModelProviderElement
    extends AutoDisposeProviderElement<VacationViewModel>
    with VacationViewModelRef {
  _VacationViewModelProviderElement(super.provider);

  @override
  String get homeId => (origin as VacationViewModelProvider).homeId;
  @override
  String get uid => (origin as VacationViewModelProvider).uid;
}

String _$vacationViewModelNotifierHash() =>
    r'da6867de4e4a06e8fe31c82f9df20a7fde00cc5b';

abstract class _$VacationViewModelNotifier
    extends BuildlessAutoDisposeNotifier<_VacationVMState> {
  late final String homeId;
  late final String uid;

  _VacationVMState build(
    String homeId,
    String uid,
  );
}

/// See also [VacationViewModelNotifier].
@ProviderFor(VacationViewModelNotifier)
const vacationViewModelNotifierProvider = VacationViewModelNotifierFamily();

/// See also [VacationViewModelNotifier].
class VacationViewModelNotifierFamily extends Family<_VacationVMState> {
  /// See also [VacationViewModelNotifier].
  const VacationViewModelNotifierFamily();

  /// See also [VacationViewModelNotifier].
  VacationViewModelNotifierProvider call(
    String homeId,
    String uid,
  ) {
    return VacationViewModelNotifierProvider(
      homeId,
      uid,
    );
  }

  @override
  VacationViewModelNotifierProvider getProviderOverride(
    covariant VacationViewModelNotifierProvider provider,
  ) {
    return call(
      provider.homeId,
      provider.uid,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'vacationViewModelNotifierProvider';
}

/// See also [VacationViewModelNotifier].
class VacationViewModelNotifierProvider extends AutoDisposeNotifierProviderImpl<
    VacationViewModelNotifier, _VacationVMState> {
  /// See also [VacationViewModelNotifier].
  VacationViewModelNotifierProvider(
    String homeId,
    String uid,
  ) : this._internal(
          () => VacationViewModelNotifier()
            ..homeId = homeId
            ..uid = uid,
          from: vacationViewModelNotifierProvider,
          name: r'vacationViewModelNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$vacationViewModelNotifierHash,
          dependencies: VacationViewModelNotifierFamily._dependencies,
          allTransitiveDependencies:
              VacationViewModelNotifierFamily._allTransitiveDependencies,
          homeId: homeId,
          uid: uid,
        );

  VacationViewModelNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.homeId,
    required this.uid,
  }) : super.internal();

  final String homeId;
  final String uid;

  @override
  _VacationVMState runNotifierBuild(
    covariant VacationViewModelNotifier notifier,
  ) {
    return notifier.build(
      homeId,
      uid,
    );
  }

  @override
  Override overrideWith(VacationViewModelNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: VacationViewModelNotifierProvider._internal(
        () => create()
          ..homeId = homeId
          ..uid = uid,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        homeId: homeId,
        uid: uid,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<VacationViewModelNotifier,
      _VacationVMState> createElement() {
    return _VacationViewModelNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is VacationViewModelNotifierProvider &&
        other.homeId == homeId &&
        other.uid == uid;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, homeId.hashCode);
    hash = _SystemHash.combine(hash, uid.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin VacationViewModelNotifierRef
    on AutoDisposeNotifierProviderRef<_VacationVMState> {
  /// The parameter `homeId` of this provider.
  String get homeId;

  /// The parameter `uid` of this provider.
  String get uid;
}

class _VacationViewModelNotifierProviderElement
    extends AutoDisposeNotifierProviderElement<VacationViewModelNotifier,
        _VacationVMState> with VacationViewModelNotifierRef {
  _VacationViewModelNotifierProviderElement(super.provider);

  @override
  String get homeId => (origin as VacationViewModelNotifierProvider).homeId;
  @override
  String get uid => (origin as VacationViewModelNotifierProvider).uid;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
