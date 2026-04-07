// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_radar_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$memberRadarHash() => r'3540c5439fba0363cb7069fcfc394fc9687dac6c';

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

/// See also [memberRadar].
@ProviderFor(memberRadar)
const memberRadarProvider = MemberRadarFamily();

/// See also [memberRadar].
class MemberRadarFamily extends Family<AsyncValue<List<RadarEntry>>> {
  /// See also [memberRadar].
  const MemberRadarFamily();

  /// See also [memberRadar].
  MemberRadarProvider call({
    required String homeId,
    required String uid,
  }) {
    return MemberRadarProvider(
      homeId: homeId,
      uid: uid,
    );
  }

  @override
  MemberRadarProvider getProviderOverride(
    covariant MemberRadarProvider provider,
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
  String? get name => r'memberRadarProvider';
}

/// See also [memberRadar].
class MemberRadarProvider extends AutoDisposeFutureProvider<List<RadarEntry>> {
  /// See also [memberRadar].
  MemberRadarProvider({
    required String homeId,
    required String uid,
  }) : this._internal(
          (ref) => memberRadar(
            ref as MemberRadarRef,
            homeId: homeId,
            uid: uid,
          ),
          from: memberRadarProvider,
          name: r'memberRadarProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$memberRadarHash,
          dependencies: MemberRadarFamily._dependencies,
          allTransitiveDependencies:
              MemberRadarFamily._allTransitiveDependencies,
          homeId: homeId,
          uid: uid,
        );

  MemberRadarProvider._internal(
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
    FutureOr<List<RadarEntry>> Function(MemberRadarRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MemberRadarProvider._internal(
        (ref) => create(ref as MemberRadarRef),
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
  AutoDisposeFutureProviderElement<List<RadarEntry>> createElement() {
    return _MemberRadarProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MemberRadarProvider &&
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
mixin MemberRadarRef on AutoDisposeFutureProviderRef<List<RadarEntry>> {
  /// The parameter `homeId` of this provider.
  String get homeId;

  /// The parameter `uid` of this provider.
  String get uid;
}

class _MemberRadarProviderElement
    extends AutoDisposeFutureProviderElement<List<RadarEntry>>
    with MemberRadarRef {
  _MemberRadarProviderElement(super.provider);

  @override
  String get homeId => (origin as MemberRadarProvider).homeId;
  @override
  String get uid => (origin as MemberRadarProvider).uid;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
