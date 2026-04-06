// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'members_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$membersRepositoryHash() => r'853dfc29e192d200d20f2b21b296c2f6042362a2';

/// See also [membersRepository].
@ProviderFor(membersRepository)
final membersRepositoryProvider = Provider<MembersRepository>.internal(
  membersRepository,
  name: r'membersRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$membersRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MembersRepositoryRef = ProviderRef<MembersRepository>;
String _$homeMembersHash() => r'7b703ba8e8a49d17b58c06034e9154f42c60dc02';

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

/// See also [homeMembers].
@ProviderFor(homeMembers)
const homeMembersProvider = HomeMembersFamily();

/// See also [homeMembers].
class HomeMembersFamily extends Family<AsyncValue<List<Member>>> {
  /// See also [homeMembers].
  const HomeMembersFamily();

  /// See also [homeMembers].
  HomeMembersProvider call(
    String homeId,
  ) {
    return HomeMembersProvider(
      homeId,
    );
  }

  @override
  HomeMembersProvider getProviderOverride(
    covariant HomeMembersProvider provider,
  ) {
    return call(
      provider.homeId,
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
  String? get name => r'homeMembersProvider';
}

/// See also [homeMembers].
class HomeMembersProvider extends AutoDisposeStreamProvider<List<Member>> {
  /// See also [homeMembers].
  HomeMembersProvider(
    String homeId,
  ) : this._internal(
          (ref) => homeMembers(
            ref as HomeMembersRef,
            homeId,
          ),
          from: homeMembersProvider,
          name: r'homeMembersProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$homeMembersHash,
          dependencies: HomeMembersFamily._dependencies,
          allTransitiveDependencies:
              HomeMembersFamily._allTransitiveDependencies,
          homeId: homeId,
        );

  HomeMembersProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.homeId,
  }) : super.internal();

  final String homeId;

  @override
  Override overrideWith(
    Stream<List<Member>> Function(HomeMembersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HomeMembersProvider._internal(
        (ref) => create(ref as HomeMembersRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        homeId: homeId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<Member>> createElement() {
    return _HomeMembersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HomeMembersProvider && other.homeId == homeId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, homeId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin HomeMembersRef on AutoDisposeStreamProviderRef<List<Member>> {
  /// The parameter `homeId` of this provider.
  String get homeId;
}

class _HomeMembersProviderElement
    extends AutoDisposeStreamProviderElement<List<Member>> with HomeMembersRef {
  _HomeMembersProviderElement(super.provider);

  @override
  String get homeId => (origin as HomeMembersProvider).homeId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
