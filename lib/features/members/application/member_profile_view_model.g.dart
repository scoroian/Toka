// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_profile_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$memberDetailHash() => r'0280c6efcaca6a1c000cb0ebf57bd6795c458b56';

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

/// See also [memberDetail].
@ProviderFor(memberDetail)
const memberDetailProvider = MemberDetailFamily();

/// See also [memberDetail].
class MemberDetailFamily extends Family<AsyncValue<Member>> {
  /// See also [memberDetail].
  const MemberDetailFamily();

  /// See also [memberDetail].
  MemberDetailProvider call(
    String homeId,
    String uid,
  ) {
    return MemberDetailProvider(
      homeId,
      uid,
    );
  }

  @override
  MemberDetailProvider getProviderOverride(
    covariant MemberDetailProvider provider,
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
  String? get name => r'memberDetailProvider';
}

/// See also [memberDetail].
class MemberDetailProvider extends AutoDisposeFutureProvider<Member> {
  /// See also [memberDetail].
  MemberDetailProvider(
    String homeId,
    String uid,
  ) : this._internal(
          (ref) => memberDetail(
            ref as MemberDetailRef,
            homeId,
            uid,
          ),
          from: memberDetailProvider,
          name: r'memberDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$memberDetailHash,
          dependencies: MemberDetailFamily._dependencies,
          allTransitiveDependencies:
              MemberDetailFamily._allTransitiveDependencies,
          homeId: homeId,
          uid: uid,
        );

  MemberDetailProvider._internal(
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
    FutureOr<Member> Function(MemberDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MemberDetailProvider._internal(
        (ref) => create(ref as MemberDetailRef),
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
  AutoDisposeFutureProviderElement<Member> createElement() {
    return _MemberDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MemberDetailProvider &&
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
mixin MemberDetailRef on AutoDisposeFutureProviderRef<Member> {
  /// The parameter `homeId` of this provider.
  String get homeId;

  /// The parameter `uid` of this provider.
  String get uid;
}

class _MemberDetailProviderElement
    extends AutoDisposeFutureProviderElement<Member> with MemberDetailRef {
  _MemberDetailProviderElement(super.provider);

  @override
  String get homeId => (origin as MemberDetailProvider).homeId;
  @override
  String get uid => (origin as MemberDetailProvider).uid;
}

String _$memberProfileViewModelHash() =>
    r'85579e7e8e78d9c021af8905f6e18ed2f7a9b2f0';

/// See also [memberProfileViewModel].
@ProviderFor(memberProfileViewModel)
const memberProfileViewModelProvider = MemberProfileViewModelFamily();

/// See also [memberProfileViewModel].
class MemberProfileViewModelFamily extends Family<MemberProfileViewModel> {
  /// See also [memberProfileViewModel].
  const MemberProfileViewModelFamily();

  /// See also [memberProfileViewModel].
  MemberProfileViewModelProvider call({
    required String homeId,
    required String memberUid,
  }) {
    return MemberProfileViewModelProvider(
      homeId: homeId,
      memberUid: memberUid,
    );
  }

  @override
  MemberProfileViewModelProvider getProviderOverride(
    covariant MemberProfileViewModelProvider provider,
  ) {
    return call(
      homeId: provider.homeId,
      memberUid: provider.memberUid,
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
  String? get name => r'memberProfileViewModelProvider';
}

/// See also [memberProfileViewModel].
class MemberProfileViewModelProvider
    extends AutoDisposeProvider<MemberProfileViewModel> {
  /// See also [memberProfileViewModel].
  MemberProfileViewModelProvider({
    required String homeId,
    required String memberUid,
  }) : this._internal(
          (ref) => memberProfileViewModel(
            ref as MemberProfileViewModelRef,
            homeId: homeId,
            memberUid: memberUid,
          ),
          from: memberProfileViewModelProvider,
          name: r'memberProfileViewModelProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$memberProfileViewModelHash,
          dependencies: MemberProfileViewModelFamily._dependencies,
          allTransitiveDependencies:
              MemberProfileViewModelFamily._allTransitiveDependencies,
          homeId: homeId,
          memberUid: memberUid,
        );

  MemberProfileViewModelProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.homeId,
    required this.memberUid,
  }) : super.internal();

  final String homeId;
  final String memberUid;

  @override
  Override overrideWith(
    MemberProfileViewModel Function(MemberProfileViewModelRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MemberProfileViewModelProvider._internal(
        (ref) => create(ref as MemberProfileViewModelRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        homeId: homeId,
        memberUid: memberUid,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<MemberProfileViewModel> createElement() {
    return _MemberProfileViewModelProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MemberProfileViewModelProvider &&
        other.homeId == homeId &&
        other.memberUid == memberUid;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, homeId.hashCode);
    hash = _SystemHash.combine(hash, memberUid.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MemberProfileViewModelRef
    on AutoDisposeProviderRef<MemberProfileViewModel> {
  /// The parameter `homeId` of this provider.
  String get homeId;

  /// The parameter `memberUid` of this provider.
  String get memberUid;
}

class _MemberProfileViewModelProviderElement
    extends AutoDisposeProviderElement<MemberProfileViewModel>
    with MemberProfileViewModelRef {
  _MemberProfileViewModelProviderElement(super.provider);

  @override
  String get homeId => (origin as MemberProfileViewModelProvider).homeId;
  @override
  String get memberUid => (origin as MemberProfileViewModelProvider).memberUid;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
