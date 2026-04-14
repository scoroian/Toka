// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$profileRepositoryHash() => r'81a6fd36bb59fc963ee16176acc1d54b36ec552c';

/// See also [profileRepository].
@ProviderFor(profileRepository)
final profileRepositoryProvider = Provider<ProfileRepository>.internal(
  profileRepository,
  name: r'profileRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$profileRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProfileRepositoryRef = ProviderRef<ProfileRepository>;
String _$userProfileHash() => r'805d70843444bf13042130564ab9a4a5eacd66f3';

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

/// See also [userProfile].
@ProviderFor(userProfile)
const userProfileProvider = UserProfileFamily();

/// See also [userProfile].
class UserProfileFamily extends Family<AsyncValue<UserProfile>> {
  /// See also [userProfile].
  const UserProfileFamily();

  /// See also [userProfile].
  UserProfileProvider call(
    String uid,
  ) {
    return UserProfileProvider(
      uid,
    );
  }

  @override
  UserProfileProvider getProviderOverride(
    covariant UserProfileProvider provider,
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
  String? get name => r'userProfileProvider';
}

/// See also [userProfile].
class UserProfileProvider extends AutoDisposeStreamProvider<UserProfile> {
  /// See also [userProfile].
  UserProfileProvider(
    String uid,
  ) : this._internal(
          (ref) => userProfile(
            ref as UserProfileRef,
            uid,
          ),
          from: userProfileProvider,
          name: r'userProfileProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$userProfileHash,
          dependencies: UserProfileFamily._dependencies,
          allTransitiveDependencies:
              UserProfileFamily._allTransitiveDependencies,
          uid: uid,
        );

  UserProfileProvider._internal(
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
    Stream<UserProfile> Function(UserProfileRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserProfileProvider._internal(
        (ref) => create(ref as UserProfileRef),
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
  AutoDisposeStreamProviderElement<UserProfile> createElement() {
    return _UserProfileProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserProfileProvider && other.uid == uid;
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
mixin UserProfileRef on AutoDisposeStreamProviderRef<UserProfile> {
  /// The parameter `uid` of this provider.
  String get uid;
}

class _UserProfileProviderElement
    extends AutoDisposeStreamProviderElement<UserProfile> with UserProfileRef {
  _UserProfileProviderElement(super.provider);

  @override
  String get uid => (origin as UserProfileProvider).uid;
}

String _$profileEditorHash() => r'2be70e5fc0d19bb640fba576d58c9b8ca46a812b';

/// See also [ProfileEditor].
@ProviderFor(ProfileEditor)
final profileEditorProvider =
    AutoDisposeNotifierProvider<ProfileEditor, AsyncValue<void>>.internal(
  ProfileEditor.new,
  name: r'profileEditorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$profileEditorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ProfileEditor = AutoDisposeNotifier<AsyncValue<void>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
