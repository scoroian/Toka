// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_settings_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notificationSettingsHash() =>
    r'9fb8b2e4c4900237817f3900bf90a09b35acfdb1';

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

/// Stream unificado que emite una nueva vista cuando cambian las prefs del
/// miembro, el `subscriptionDashboard` (premium) o la autorización de
/// sistema. Al dejarlo `keepAlive`, la vista conserva los datos previos
/// mientras Firestore entrega la siguiente emisión, evitando el salto a
/// estado "deshabilitado" durante la transición.
///
/// Copied from [notificationSettings].
@ProviderFor(notificationSettings)
const notificationSettingsProvider = NotificationSettingsFamily();

/// Stream unificado que emite una nueva vista cuando cambian las prefs del
/// miembro, el `subscriptionDashboard` (premium) o la autorización de
/// sistema. Al dejarlo `keepAlive`, la vista conserva los datos previos
/// mientras Firestore entrega la siguiente emisión, evitando el salto a
/// estado "deshabilitado" durante la transición.
///
/// Copied from [notificationSettings].
class NotificationSettingsFamily
    extends Family<AsyncValue<NotificationSettingsView>> {
  /// Stream unificado que emite una nueva vista cuando cambian las prefs del
  /// miembro, el `subscriptionDashboard` (premium) o la autorización de
  /// sistema. Al dejarlo `keepAlive`, la vista conserva los datos previos
  /// mientras Firestore entrega la siguiente emisión, evitando el salto a
  /// estado "deshabilitado" durante la transición.
  ///
  /// Copied from [notificationSettings].
  const NotificationSettingsFamily();

  /// Stream unificado que emite una nueva vista cuando cambian las prefs del
  /// miembro, el `subscriptionDashboard` (premium) o la autorización de
  /// sistema. Al dejarlo `keepAlive`, la vista conserva los datos previos
  /// mientras Firestore entrega la siguiente emisión, evitando el salto a
  /// estado "deshabilitado" durante la transición.
  ///
  /// Copied from [notificationSettings].
  NotificationSettingsProvider call(
    String homeId,
    String uid,
  ) {
    return NotificationSettingsProvider(
      homeId,
      uid,
    );
  }

  @override
  NotificationSettingsProvider getProviderOverride(
    covariant NotificationSettingsProvider provider,
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
  String? get name => r'notificationSettingsProvider';
}

/// Stream unificado que emite una nueva vista cuando cambian las prefs del
/// miembro, el `subscriptionDashboard` (premium) o la autorización de
/// sistema. Al dejarlo `keepAlive`, la vista conserva los datos previos
/// mientras Firestore entrega la siguiente emisión, evitando el salto a
/// estado "deshabilitado" durante la transición.
///
/// Copied from [notificationSettings].
class NotificationSettingsProvider
    extends StreamProvider<NotificationSettingsView> {
  /// Stream unificado que emite una nueva vista cuando cambian las prefs del
  /// miembro, el `subscriptionDashboard` (premium) o la autorización de
  /// sistema. Al dejarlo `keepAlive`, la vista conserva los datos previos
  /// mientras Firestore entrega la siguiente emisión, evitando el salto a
  /// estado "deshabilitado" durante la transición.
  ///
  /// Copied from [notificationSettings].
  NotificationSettingsProvider(
    String homeId,
    String uid,
  ) : this._internal(
          (ref) => notificationSettings(
            ref as NotificationSettingsRef,
            homeId,
            uid,
          ),
          from: notificationSettingsProvider,
          name: r'notificationSettingsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$notificationSettingsHash,
          dependencies: NotificationSettingsFamily._dependencies,
          allTransitiveDependencies:
              NotificationSettingsFamily._allTransitiveDependencies,
          homeId: homeId,
          uid: uid,
        );

  NotificationSettingsProvider._internal(
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
    Stream<NotificationSettingsView> Function(NotificationSettingsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: NotificationSettingsProvider._internal(
        (ref) => create(ref as NotificationSettingsRef),
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
  StreamProviderElement<NotificationSettingsView> createElement() {
    return _NotificationSettingsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NotificationSettingsProvider &&
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
mixin NotificationSettingsRef on StreamProviderRef<NotificationSettingsView> {
  /// The parameter `homeId` of this provider.
  String get homeId;

  /// The parameter `uid` of this provider.
  String get uid;
}

class _NotificationSettingsProviderElement
    extends StreamProviderElement<NotificationSettingsView>
    with NotificationSettingsRef {
  _NotificationSettingsProviderElement(super.provider);

  @override
  String get homeId => (origin as NotificationSettingsProvider).homeId;
  @override
  String get uid => (origin as NotificationSettingsProvider).uid;
}

String _$notificationSettingsActionsHash() =>
    r'61dbaa1477ccd7d858549dc2b37af2cd1163eb9f';

/// Action-only provider: aislado del stream para que guardar preferencias no
/// provoque un rebuild de la vista (que ya lo hace el stream cuando Firestore
/// propaga el cambio).
///
/// Copied from [NotificationSettingsActions].
@ProviderFor(NotificationSettingsActions)
final notificationSettingsActionsProvider =
    AutoDisposeNotifierProvider<NotificationSettingsActions, void>.internal(
  NotificationSettingsActions.new,
  name: r'notificationSettingsActionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationSettingsActionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$NotificationSettingsActions = AutoDisposeNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
