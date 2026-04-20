// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_settings_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notificationSettingsViewModelHash() =>
    r'36e59e8223a587f728d8635056647d33faee5dc6';

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

/// See also [notificationSettingsViewModel].
@ProviderFor(notificationSettingsViewModel)
const notificationSettingsViewModelProvider =
    NotificationSettingsViewModelFamily();

/// See also [notificationSettingsViewModel].
class NotificationSettingsViewModelFamily
    extends Family<NotificationSettingsViewModel> {
  /// See also [notificationSettingsViewModel].
  const NotificationSettingsViewModelFamily();

  /// See also [notificationSettingsViewModel].
  NotificationSettingsViewModelProvider call(
    String homeId,
    String uid,
  ) {
    return NotificationSettingsViewModelProvider(
      homeId,
      uid,
    );
  }

  @override
  NotificationSettingsViewModelProvider getProviderOverride(
    covariant NotificationSettingsViewModelProvider provider,
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
  String? get name => r'notificationSettingsViewModelProvider';
}

/// See also [notificationSettingsViewModel].
class NotificationSettingsViewModelProvider
    extends AutoDisposeProvider<NotificationSettingsViewModel> {
  /// See also [notificationSettingsViewModel].
  NotificationSettingsViewModelProvider(
    String homeId,
    String uid,
  ) : this._internal(
          (ref) => notificationSettingsViewModel(
            ref as NotificationSettingsViewModelRef,
            homeId,
            uid,
          ),
          from: notificationSettingsViewModelProvider,
          name: r'notificationSettingsViewModelProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$notificationSettingsViewModelHash,
          dependencies: NotificationSettingsViewModelFamily._dependencies,
          allTransitiveDependencies:
              NotificationSettingsViewModelFamily._allTransitiveDependencies,
          homeId: homeId,
          uid: uid,
        );

  NotificationSettingsViewModelProvider._internal(
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
    NotificationSettingsViewModel Function(
            NotificationSettingsViewModelRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: NotificationSettingsViewModelProvider._internal(
        (ref) => create(ref as NotificationSettingsViewModelRef),
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
  AutoDisposeProviderElement<NotificationSettingsViewModel> createElement() {
    return _NotificationSettingsViewModelProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NotificationSettingsViewModelProvider &&
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
mixin NotificationSettingsViewModelRef
    on AutoDisposeProviderRef<NotificationSettingsViewModel> {
  /// The parameter `homeId` of this provider.
  String get homeId;

  /// The parameter `uid` of this provider.
  String get uid;
}

class _NotificationSettingsViewModelProviderElement
    extends AutoDisposeProviderElement<NotificationSettingsViewModel>
    with NotificationSettingsViewModelRef {
  _NotificationSettingsViewModelProviderElement(super.provider);

  @override
  String get homeId => (origin as NotificationSettingsViewModelProvider).homeId;
  @override
  String get uid => (origin as NotificationSettingsViewModelProvider).uid;
}

String _$notificationSettingsViewModelNotifierHash() =>
    r'a980d1921fed0702bf0cd166af6678b84c1aabf9';

abstract class _$NotificationSettingsViewModelNotifier
    extends BuildlessAutoDisposeNotifier<_NotifVMState> {
  late final String homeId;
  late final String uid;

  _NotifVMState build(
    String homeId,
    String uid,
  );
}

/// See also [NotificationSettingsViewModelNotifier].
@ProviderFor(NotificationSettingsViewModelNotifier)
const notificationSettingsViewModelNotifierProvider =
    NotificationSettingsViewModelNotifierFamily();

/// See also [NotificationSettingsViewModelNotifier].
class NotificationSettingsViewModelNotifierFamily
    extends Family<_NotifVMState> {
  /// See also [NotificationSettingsViewModelNotifier].
  const NotificationSettingsViewModelNotifierFamily();

  /// See also [NotificationSettingsViewModelNotifier].
  NotificationSettingsViewModelNotifierProvider call(
    String homeId,
    String uid,
  ) {
    return NotificationSettingsViewModelNotifierProvider(
      homeId,
      uid,
    );
  }

  @override
  NotificationSettingsViewModelNotifierProvider getProviderOverride(
    covariant NotificationSettingsViewModelNotifierProvider provider,
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
  String? get name => r'notificationSettingsViewModelNotifierProvider';
}

/// See also [NotificationSettingsViewModelNotifier].
class NotificationSettingsViewModelNotifierProvider
    extends AutoDisposeNotifierProviderImpl<
        NotificationSettingsViewModelNotifier, _NotifVMState> {
  /// See also [NotificationSettingsViewModelNotifier].
  NotificationSettingsViewModelNotifierProvider(
    String homeId,
    String uid,
  ) : this._internal(
          () => NotificationSettingsViewModelNotifier()
            ..homeId = homeId
            ..uid = uid,
          from: notificationSettingsViewModelNotifierProvider,
          name: r'notificationSettingsViewModelNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$notificationSettingsViewModelNotifierHash,
          dependencies:
              NotificationSettingsViewModelNotifierFamily._dependencies,
          allTransitiveDependencies: NotificationSettingsViewModelNotifierFamily
              ._allTransitiveDependencies,
          homeId: homeId,
          uid: uid,
        );

  NotificationSettingsViewModelNotifierProvider._internal(
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
  _NotifVMState runNotifierBuild(
    covariant NotificationSettingsViewModelNotifier notifier,
  ) {
    return notifier.build(
      homeId,
      uid,
    );
  }

  @override
  Override overrideWith(
      NotificationSettingsViewModelNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: NotificationSettingsViewModelNotifierProvider._internal(
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
  AutoDisposeNotifierProviderElement<NotificationSettingsViewModelNotifier,
      _NotifVMState> createElement() {
    return _NotificationSettingsViewModelNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NotificationSettingsViewModelNotifierProvider &&
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
mixin NotificationSettingsViewModelNotifierRef
    on AutoDisposeNotifierProviderRef<_NotifVMState> {
  /// The parameter `homeId` of this provider.
  String get homeId;

  /// The parameter `uid` of this provider.
  String get uid;
}

class _NotificationSettingsViewModelNotifierProviderElement
    extends AutoDisposeNotifierProviderElement<
        NotificationSettingsViewModelNotifier,
        _NotifVMState> with NotificationSettingsViewModelNotifierRef {
  _NotificationSettingsViewModelNotifierProviderElement(super.provider);

  @override
  String get homeId =>
      (origin as NotificationSettingsViewModelNotifierProvider).homeId;
  @override
  String get uid =>
      (origin as NotificationSettingsViewModelNotifierProvider).uid;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
