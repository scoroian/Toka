// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_profile_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$memberProfileViewModelHash() =>
    r'1432f812b5bd9ec084764cc53b14f4564b173e6b';

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
