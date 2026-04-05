// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'homes_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$homesRepositoryHash() => r'600623ef5b27971e0a3481f4eaf45b6f0ef5ae0a';

/// See also [homesRepository].
@ProviderFor(homesRepository)
final homesRepositoryProvider = Provider<HomesRepository>.internal(
  homesRepository,
  name: r'homesRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$homesRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HomesRepositoryRef = ProviderRef<HomesRepository>;
String _$userMembershipsHash() => r'87e727473d3a27922e6447b2ea139d57faa17525';

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

/// See also [userMemberships].
@ProviderFor(userMemberships)
const userMembershipsProvider = UserMembershipsFamily();

/// See also [userMemberships].
class UserMembershipsFamily extends Family<AsyncValue<List<HomeMembership>>> {
  /// See also [userMemberships].
  const UserMembershipsFamily();

  /// See also [userMemberships].
  UserMembershipsProvider call(
    String uid,
  ) {
    return UserMembershipsProvider(
      uid,
    );
  }

  @override
  UserMembershipsProvider getProviderOverride(
    covariant UserMembershipsProvider provider,
  ) {
    return call(
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
  String? get name => r'userMembershipsProvider';
}

/// See also [userMemberships].
class UserMembershipsProvider
    extends AutoDisposeStreamProvider<List<HomeMembership>> {
  /// See also [userMemberships].
  UserMembershipsProvider(
    String uid,
  ) : this._internal(
          (ref) => userMemberships(
            ref as UserMembershipsRef,
            uid,
          ),
          from: userMembershipsProvider,
          name: r'userMembershipsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$userMembershipsHash,
          dependencies: UserMembershipsFamily._dependencies,
          allTransitiveDependencies:
              UserMembershipsFamily._allTransitiveDependencies,
          uid: uid,
        );

  UserMembershipsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.uid,
  }) : super.internal();

  final String uid;

  @override
  Override overrideWith(
    Stream<List<HomeMembership>> Function(UserMembershipsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserMembershipsProvider._internal(
        (ref) => create(ref as UserMembershipsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        uid: uid,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<HomeMembership>> createElement() {
    return _UserMembershipsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserMembershipsProvider && other.uid == uid;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, uid.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UserMembershipsRef on AutoDisposeStreamProviderRef<List<HomeMembership>> {
  /// The parameter `uid` of this provider.
  String get uid;
}

class _UserMembershipsProviderElement
    extends AutoDisposeStreamProviderElement<List<HomeMembership>>
    with UserMembershipsRef {
  _UserMembershipsProviderElement(super.provider);

  @override
  String get uid => (origin as UserMembershipsProvider).uid;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
