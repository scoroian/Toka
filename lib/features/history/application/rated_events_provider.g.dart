// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rated_events_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$ratedEventIdsHash() => r'eac79a68e4f314da28184077fab772149ee60a1f';

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

/// See also [ratedEventIds].
@ProviderFor(ratedEventIds)
const ratedEventIdsProvider = RatedEventIdsFamily();

/// See also [ratedEventIds].
class RatedEventIdsFamily extends Family<AsyncValue<Set<String>>> {
  /// See also [ratedEventIds].
  const RatedEventIdsFamily();

  /// See also [ratedEventIds].
  RatedEventIdsProvider call({
    required String homeId,
    required String currentUid,
  }) {
    return RatedEventIdsProvider(
      homeId: homeId,
      currentUid: currentUid,
    );
  }

  @override
  RatedEventIdsProvider getProviderOverride(
    covariant RatedEventIdsProvider provider,
  ) {
    return call(
      homeId: provider.homeId,
      currentUid: provider.currentUid,
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
  String? get name => r'ratedEventIdsProvider';
}

/// See also [ratedEventIds].
class RatedEventIdsProvider extends AutoDisposeStreamProvider<Set<String>> {
  /// See also [ratedEventIds].
  RatedEventIdsProvider({
    required String homeId,
    required String currentUid,
  }) : this._internal(
          (ref) => ratedEventIds(
            ref as RatedEventIdsRef,
            homeId: homeId,
            currentUid: currentUid,
          ),
          from: ratedEventIdsProvider,
          name: r'ratedEventIdsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$ratedEventIdsHash,
          dependencies: RatedEventIdsFamily._dependencies,
          allTransitiveDependencies:
              RatedEventIdsFamily._allTransitiveDependencies,
          homeId: homeId,
          currentUid: currentUid,
        );

  RatedEventIdsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.homeId,
    required this.currentUid,
  }) : super.internal();

  final String homeId;
  final String currentUid;

  @override
  Override overrideWith(
    Stream<Set<String>> Function(RatedEventIdsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RatedEventIdsProvider._internal(
        (ref) => create(ref as RatedEventIdsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        homeId: homeId,
        currentUid: currentUid,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<Set<String>> createElement() {
    return _RatedEventIdsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RatedEventIdsProvider &&
        other.homeId == homeId &&
        other.currentUid == currentUid;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, homeId.hashCode);
    hash = _SystemHash.combine(hash, currentUid.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin RatedEventIdsRef on AutoDisposeStreamProviderRef<Set<String>> {
  /// The parameter `homeId` of this provider.
  String get homeId;

  /// The parameter `currentUid` of this provider.
  String get currentUid;
}

class _RatedEventIdsProviderElement
    extends AutoDisposeStreamProviderElement<Set<String>>
    with RatedEventIdsRef {
  _RatedEventIdsProviderElement(super.provider);

  @override
  String get homeId => (origin as RatedEventIdsProvider).homeId;
  @override
  String get currentUid => (origin as RatedEventIdsProvider).currentUid;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
