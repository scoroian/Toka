// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vacation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$memberVacationHash() => r'71b98a265544ea344ef9b1b71b853ca6d2a5e32e';

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

/// See also [memberVacation].
@ProviderFor(memberVacation)
const memberVacationProvider = MemberVacationFamily();

/// See also [memberVacation].
class MemberVacationFamily extends Family<AsyncValue<Vacation?>> {
  /// See also [memberVacation].
  const MemberVacationFamily();

  /// See also [memberVacation].
  MemberVacationProvider call({
    required String homeId,
    required String uid,
  }) {
    return MemberVacationProvider(
      homeId: homeId,
      uid: uid,
    );
  }

  @override
  MemberVacationProvider getProviderOverride(
    covariant MemberVacationProvider provider,
  ) {
    return call(
      homeId: provider.homeId,
      uid: provider.uid,
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
  String? get name => r'memberVacationProvider';
}

/// See also [memberVacation].
class MemberVacationProvider extends AutoDisposeStreamProvider<Vacation?> {
  /// See also [memberVacation].
  MemberVacationProvider({
    required String homeId,
    required String uid,
  }) : this._internal(
          (ref) => memberVacation(
            ref as MemberVacationRef,
            homeId: homeId,
            uid: uid,
          ),
          from: memberVacationProvider,
          name: r'memberVacationProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$memberVacationHash,
          dependencies: MemberVacationFamily._dependencies,
          allTransitiveDependencies:
              MemberVacationFamily._allTransitiveDependencies,
          homeId: homeId,
          uid: uid,
        );

  MemberVacationProvider._internal(
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
    Stream<Vacation?> Function(MemberVacationRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MemberVacationProvider._internal(
        (ref) => create(ref as MemberVacationRef),
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
  AutoDisposeStreamProviderElement<Vacation?> createElement() {
    return _MemberVacationProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MemberVacationProvider &&
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
mixin MemberVacationRef on AutoDisposeStreamProviderRef<Vacation?> {
  /// The parameter `homeId` of this provider.
  String get homeId;

  /// The parameter `uid` of this provider.
  String get uid;
}

class _MemberVacationProviderElement
    extends AutoDisposeStreamProviderElement<Vacation?> with MemberVacationRef {
  _MemberVacationProviderElement(super.provider);

  @override
  String get homeId => (origin as MemberVacationProvider).homeId;
  @override
  String get uid => (origin as MemberVacationProvider).uid;
}

String _$vacationNotifierHash() => r'd075ae9a88aab7efb42d460cc21bf94b590624fb';

/// See also [VacationNotifier].
@ProviderFor(VacationNotifier)
final vacationNotifierProvider =
    AutoDisposeNotifierProvider<VacationNotifier, AsyncValue<void>>.internal(
  VacationNotifier.new,
  name: r'vacationNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$vacationNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$VacationNotifier = AutoDisposeNotifier<AsyncValue<void>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
