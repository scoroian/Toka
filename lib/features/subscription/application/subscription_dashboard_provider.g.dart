// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_dashboard_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$subscriptionDashboardHash() =>
    r'74f5b01e5686548a358be86d022d7b5f82d069e2';

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

/// Stream en vivo del estado de suscripción del hogar actual.
///
/// Combina dos snapshots de Firestore:
///   - `homes/{homeId}` — fuente de verdad de `premiumStatus`, `premiumPlan`,
///     `premiumEndsAt`, `restoreUntil`, `autoRenewEnabled`, `currentPayerUid`.
///     Se actualiza desde `syncEntitlement`, `debugSetPremiumStatus` y los
///     cron de rescate/downgrade.
///   - `homes/{homeId}/views/dashboard` — sólo se usa para extraer
///     `planCounters`.
///
/// Cada cambio en cualquiera de los dos documentos re-emite el
/// [SubscriptionDashboard], de modo que la pantalla Suscripción refleja el
/// cambio sin pull-to-refresh (BUG-12).
///
/// Copied from [subscriptionDashboard].
@ProviderFor(subscriptionDashboard)
const subscriptionDashboardProvider = SubscriptionDashboardFamily();

/// Stream en vivo del estado de suscripción del hogar actual.
///
/// Combina dos snapshots de Firestore:
///   - `homes/{homeId}` — fuente de verdad de `premiumStatus`, `premiumPlan`,
///     `premiumEndsAt`, `restoreUntil`, `autoRenewEnabled`, `currentPayerUid`.
///     Se actualiza desde `syncEntitlement`, `debugSetPremiumStatus` y los
///     cron de rescate/downgrade.
///   - `homes/{homeId}/views/dashboard` — sólo se usa para extraer
///     `planCounters`.
///
/// Cada cambio en cualquiera de los dos documentos re-emite el
/// [SubscriptionDashboard], de modo que la pantalla Suscripción refleja el
/// cambio sin pull-to-refresh (BUG-12).
///
/// Copied from [subscriptionDashboard].
class SubscriptionDashboardFamily
    extends Family<AsyncValue<SubscriptionDashboard>> {
  /// Stream en vivo del estado de suscripción del hogar actual.
  ///
  /// Combina dos snapshots de Firestore:
  ///   - `homes/{homeId}` — fuente de verdad de `premiumStatus`, `premiumPlan`,
  ///     `premiumEndsAt`, `restoreUntil`, `autoRenewEnabled`, `currentPayerUid`.
  ///     Se actualiza desde `syncEntitlement`, `debugSetPremiumStatus` y los
  ///     cron de rescate/downgrade.
  ///   - `homes/{homeId}/views/dashboard` — sólo se usa para extraer
  ///     `planCounters`.
  ///
  /// Cada cambio en cualquiera de los dos documentos re-emite el
  /// [SubscriptionDashboard], de modo que la pantalla Suscripción refleja el
  /// cambio sin pull-to-refresh (BUG-12).
  ///
  /// Copied from [subscriptionDashboard].
  const SubscriptionDashboardFamily();

  /// Stream en vivo del estado de suscripción del hogar actual.
  ///
  /// Combina dos snapshots de Firestore:
  ///   - `homes/{homeId}` — fuente de verdad de `premiumStatus`, `premiumPlan`,
  ///     `premiumEndsAt`, `restoreUntil`, `autoRenewEnabled`, `currentPayerUid`.
  ///     Se actualiza desde `syncEntitlement`, `debugSetPremiumStatus` y los
  ///     cron de rescate/downgrade.
  ///   - `homes/{homeId}/views/dashboard` — sólo se usa para extraer
  ///     `planCounters`.
  ///
  /// Cada cambio en cualquiera de los dos documentos re-emite el
  /// [SubscriptionDashboard], de modo que la pantalla Suscripción refleja el
  /// cambio sin pull-to-refresh (BUG-12).
  ///
  /// Copied from [subscriptionDashboard].
  SubscriptionDashboardProvider call({
    FirebaseFirestore? firestoreOverride,
  }) {
    return SubscriptionDashboardProvider(
      firestoreOverride: firestoreOverride,
    );
  }

  @override
  SubscriptionDashboardProvider getProviderOverride(
    covariant SubscriptionDashboardProvider provider,
  ) {
    return call(
      firestoreOverride: provider.firestoreOverride,
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
  String? get name => r'subscriptionDashboardProvider';
}

/// Stream en vivo del estado de suscripción del hogar actual.
///
/// Combina dos snapshots de Firestore:
///   - `homes/{homeId}` — fuente de verdad de `premiumStatus`, `premiumPlan`,
///     `premiumEndsAt`, `restoreUntil`, `autoRenewEnabled`, `currentPayerUid`.
///     Se actualiza desde `syncEntitlement`, `debugSetPremiumStatus` y los
///     cron de rescate/downgrade.
///   - `homes/{homeId}/views/dashboard` — sólo se usa para extraer
///     `planCounters`.
///
/// Cada cambio en cualquiera de los dos documentos re-emite el
/// [SubscriptionDashboard], de modo que la pantalla Suscripción refleja el
/// cambio sin pull-to-refresh (BUG-12).
///
/// Copied from [subscriptionDashboard].
class SubscriptionDashboardProvider
    extends StreamProvider<SubscriptionDashboard> {
  /// Stream en vivo del estado de suscripción del hogar actual.
  ///
  /// Combina dos snapshots de Firestore:
  ///   - `homes/{homeId}` — fuente de verdad de `premiumStatus`, `premiumPlan`,
  ///     `premiumEndsAt`, `restoreUntil`, `autoRenewEnabled`, `currentPayerUid`.
  ///     Se actualiza desde `syncEntitlement`, `debugSetPremiumStatus` y los
  ///     cron de rescate/downgrade.
  ///   - `homes/{homeId}/views/dashboard` — sólo se usa para extraer
  ///     `planCounters`.
  ///
  /// Cada cambio en cualquiera de los dos documentos re-emite el
  /// [SubscriptionDashboard], de modo que la pantalla Suscripción refleja el
  /// cambio sin pull-to-refresh (BUG-12).
  ///
  /// Copied from [subscriptionDashboard].
  SubscriptionDashboardProvider({
    FirebaseFirestore? firestoreOverride,
  }) : this._internal(
          (ref) => subscriptionDashboard(
            ref as SubscriptionDashboardRef,
            firestoreOverride: firestoreOverride,
          ),
          from: subscriptionDashboardProvider,
          name: r'subscriptionDashboardProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$subscriptionDashboardHash,
          dependencies: SubscriptionDashboardFamily._dependencies,
          allTransitiveDependencies:
              SubscriptionDashboardFamily._allTransitiveDependencies,
          firestoreOverride: firestoreOverride,
        );

  SubscriptionDashboardProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.firestoreOverride,
  }) : super.internal();

  final FirebaseFirestore? firestoreOverride;

  @override
  Override overrideWith(
    Stream<SubscriptionDashboard> Function(SubscriptionDashboardRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SubscriptionDashboardProvider._internal(
        (ref) => create(ref as SubscriptionDashboardRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        firestoreOverride: firestoreOverride,
      ),
    );
  }

  @override
  StreamProviderElement<SubscriptionDashboard> createElement() {
    return _SubscriptionDashboardProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SubscriptionDashboardProvider &&
        other.firestoreOverride == firestoreOverride;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, firestoreOverride.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SubscriptionDashboardRef on StreamProviderRef<SubscriptionDashboard> {
  /// The parameter `firestoreOverride` of this provider.
  FirebaseFirestore? get firestoreOverride;
}

class _SubscriptionDashboardProviderElement
    extends StreamProviderElement<SubscriptionDashboard>
    with SubscriptionDashboardRef {
  _SubscriptionDashboardProviderElement(super.provider);

  @override
  FirebaseFirestore? get firestoreOverride =>
      (origin as SubscriptionDashboardProvider).firestoreOverride;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
