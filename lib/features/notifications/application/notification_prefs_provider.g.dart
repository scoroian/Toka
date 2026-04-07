// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_prefs_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notificationPrefsRepositoryHash() =>
    r'8c33f32052f42104c02af3f4b8a3a61ba1844e78';

/// See also [notificationPrefsRepository].
@ProviderFor(notificationPrefsRepository)
final notificationPrefsRepositoryProvider =
    Provider<NotificationPrefsRepository>.internal(
  notificationPrefsRepository,
  name: r'notificationPrefsRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationPrefsRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotificationPrefsRepositoryRef
    = ProviderRef<NotificationPrefsRepository>;
String _$notificationPrefsHash() => r'd07cdb65d822df2f4aa10a4295828d69e19534c9';

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

/// See also [notificationPrefs].
@ProviderFor(notificationPrefs)
const notificationPrefsProvider = NotificationPrefsFamily();

/// See also [notificationPrefs].
class NotificationPrefsFamily
    extends Family<AsyncValue<NotificationPreferences>> {
  /// See also [notificationPrefs].
  const NotificationPrefsFamily();

  /// See also [notificationPrefs].
  NotificationPrefsProvider call({
    required String homeId,
    required String uid,
  }) {
    return NotificationPrefsProvider(
      homeId: homeId,
      uid: uid,
    );
  }

  @override
  NotificationPrefsProvider getProviderOverride(
    covariant NotificationPrefsProvider provider,
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
  String? get name => r'notificationPrefsProvider';
}

/// See also [notificationPrefs].
class NotificationPrefsProvider
    extends AutoDisposeStreamProvider<NotificationPreferences> {
  /// See also [notificationPrefs].
  NotificationPrefsProvider({
    required String homeId,
    required String uid,
  }) : this._internal(
          (ref) => notificationPrefs(
            ref as NotificationPrefsRef,
            homeId: homeId,
            uid: uid,
          ),
          from: notificationPrefsProvider,
          name: r'notificationPrefsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$notificationPrefsHash,
          dependencies: NotificationPrefsFamily._dependencies,
          allTransitiveDependencies:
              NotificationPrefsFamily._allTransitiveDependencies,
          homeId: homeId,
          uid: uid,
        );

  NotificationPrefsProvider._internal(
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
    Stream<NotificationPreferences> Function(NotificationPrefsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: NotificationPrefsProvider._internal(
        (ref) => create(ref as NotificationPrefsRef),
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
  AutoDisposeStreamProviderElement<NotificationPreferences> createElement() {
    return _NotificationPrefsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NotificationPrefsProvider &&
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
mixin NotificationPrefsRef
    on AutoDisposeStreamProviderRef<NotificationPreferences> {
  /// The parameter `homeId` of this provider.
  String get homeId;

  /// The parameter `uid` of this provider.
  String get uid;
}

class _NotificationPrefsProviderElement
    extends AutoDisposeStreamProviderElement<NotificationPreferences>
    with NotificationPrefsRef {
  _NotificationPrefsProviderElement(super.provider);

  @override
  String get homeId => (origin as NotificationPrefsProvider).homeId;
  @override
  String get uid => (origin as NotificationPrefsProvider).uid;
}

String _$fcmTokenInitHash() => r'3828ee03ca43a1bfa59c998f2b0878a964bea1e8';

/// See also [fcmTokenInit].
@ProviderFor(fcmTokenInit)
final fcmTokenInitProvider = Provider<void>.internal(
  fcmTokenInit,
  name: r'fcmTokenInitProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$fcmTokenInitHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FcmTokenInitRef = ProviderRef<void>;
String _$notificationPrefsNotifierHash() =>
    r'16ac310942a5e4d4e590d010a5a19fba917a62f7';

/// See also [NotificationPrefsNotifier].
@ProviderFor(NotificationPrefsNotifier)
final notificationPrefsNotifierProvider = AutoDisposeNotifierProvider<
    NotificationPrefsNotifier, AsyncValue<void>>.internal(
  NotificationPrefsNotifier.new,
  name: r'notificationPrefsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationPrefsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$NotificationPrefsNotifier = AutoDisposeNotifier<AsyncValue<void>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
