// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rated_events_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$ratedEventIdsHash() => r'eac79a68e4f314da28184077fab772149ee60a1f';

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

/// IDs de eventos que el usuario actual YA ha valorado, leídos en vivo desde
/// `homes/{homeId}/memberReviews/{currentUid}.ratedEventIds` (lo escribe la
/// Cloud Function `submitReview`).
///
/// Copied from [ratedEventIds].
@ProviderFor(ratedEventIds)
const ratedEventIdsProvider = RatedEventIdsFamily();

/// IDs de eventos que el usuario actual YA ha valorado, leídos en vivo desde
/// `homes/{homeId}/memberReviews/{currentUid}.ratedEventIds` (lo escribe la
/// Cloud Function `submitReview`).
///
/// Copied from [ratedEventIds].
class RatedEventIdsFamily extends Family<AsyncValue<Set<String>>> {
  /// IDs de eventos que el usuario actual YA ha valorado, leídos en vivo desde
  /// `homes/{homeId}/memberReviews/{currentUid}.ratedEventIds` (lo escribe la
  /// Cloud Function `submitReview`).
  ///
  /// Copied from [ratedEventIds].
  const RatedEventIdsFamily();

  /// IDs de eventos que el usuario actual YA ha valorado, leídos en vivo desde
  /// `homes/{homeId}/memberReviews/{currentUid}.ratedEventIds` (lo escribe la
  /// Cloud Function `submitReview`).
  ///
  /// Copied from [ratedEventIds].
  RatedEventIdsProvider call({
    required String homeId,
    required String currentUid,
  }) {
    return RatedEventIdsProvider(
      homeId: homeId,
      currentUid: currentUid,
    );
  }

  @override
  RatedEventIdsProvider getProviderOverride(
    covariant RatedEventIdsProvider provider,
  ) {
    return call(
      homeId: provider.homeId,
      currentUid: provider.currentUid,
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
  String? get name => r'ratedEventIdsProvider';
}

/// IDs de eventos que el usuario actual YA ha valorado, leídos en vivo desde
/// `homes/{homeId}/memberReviews/{currentUid}.ratedEventIds` (lo escribe la
/// Cloud Function `submitReview`).
///
/// Copied from [ratedEventIds].
class RatedEventIdsProvider extends AutoDisposeStreamProvider<Set<String>> {
  /// IDs de eventos que el usuario actual YA ha valorado, leídos en vivo desde
  /// `homes/{homeId}/memberReviews/{currentUid}.ratedEventIds` (lo escribe la
  /// Cloud Function `submitReview`).
  ///
  /// Copied from [ratedEventIds].
  RatedEventIdsProvider({
    required String homeId,
    required String currentUid,
  }) : this._internal(
          (ref) => ratedEventIds(
            ref as RatedEventIdsRef,
            homeId: homeId,
            currentUid: currentUid,
          ),
          from: ratedEventIdsProvider,
          name: r'ratedEventIdsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$ratedEventIdsHash,
          dependencies: RatedEventIdsFamily._dependencies,
          allTransitiveDependencies:
              RatedEventIdsFamily._allTransitiveDependencies,
          homeId: homeId,
          currentUid: currentUid,
        );

  RatedEventIdsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.homeId,
    required this.currentUid,
  }) : super.internal();

  final String homeId;
  final String currentUid;

  @override
  Override overrideWith(
    Stream<Set<String>> Function(RatedEventIdsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RatedEventIdsProvider._internal(
        (ref) => create(ref as RatedEventIdsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        homeId: homeId,
        currentUid: currentUid,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<Set<String>> createElement() {
    return _RatedEventIdsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RatedEventIdsProvider &&
        other.homeId == homeId &&
        other.currentUid == currentUid;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, homeId.hashCode);
    hash = _SystemHash.combine(hash, currentUid.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin RatedEventIdsRef on AutoDisposeStreamProviderRef<Set<String>> {
  /// The parameter `homeId` of this provider.
  String get homeId;

  /// The parameter `currentUid` of this provider.
  String get currentUid;
}

class _RatedEventIdsProviderElement
    extends AutoDisposeStreamProviderElement<Set<String>>
    with RatedEventIdsRef {
  _RatedEventIdsProviderElement(super.provider);

  @override
  String get homeId => (origin as RatedEventIdsProvider).homeId;
  @override
  String get currentUid => (origin as RatedEventIdsProvider).currentUid;
}

String _$optimisticRatedEventIdsHash() =>
    r'35a949860082bf42972c4855c99738f658ac502a';

abstract class _$OptimisticRatedEventIds
    extends BuildlessAutoDisposeNotifier<Set<String>> {
  late final String homeId;

  Set<String> build(
    String homeId,
  );
}

/// Conjunto optimista de eventos valorados durante esta sesión de Historial.
///
/// `submitReview` escribe `ratedEventIds` en Firestore, pero el `snapshots()`
/// de [ratedEventIds] puede tardar uno o varios segundos en propagar el cambio
/// al cliente (round-trip callable → commit de la transacción → listener). Para
/// que el botón "Valorar" pase a "valorado" en el acto, tras un envío exitoso
/// registramos aquí el `eventId` y lo fusionamos con el stream en
/// `historyViewModel`. Siempre es un subconjunto de lo que acabará llegando por
/// Firestore, así que no introduce incoherencias entre dispositivos.
///
/// Copied from [OptimisticRatedEventIds].
@ProviderFor(OptimisticRatedEventIds)
const optimisticRatedEventIdsProvider = OptimisticRatedEventIdsFamily();

/// Conjunto optimista de eventos valorados durante esta sesión de Historial.
///
/// `submitReview` escribe `ratedEventIds` en Firestore, pero el `snapshots()`
/// de [ratedEventIds] puede tardar uno o varios segundos en propagar el cambio
/// al cliente (round-trip callable → commit de la transacción → listener). Para
/// que el botón "Valorar" pase a "valorado" en el acto, tras un envío exitoso
/// registramos aquí el `eventId` y lo fusionamos con el stream en
/// `historyViewModel`. Siempre es un subconjunto de lo que acabará llegando por
/// Firestore, así que no introduce incoherencias entre dispositivos.
///
/// Copied from [OptimisticRatedEventIds].
class OptimisticRatedEventIdsFamily extends Family<Set<String>> {
  /// Conjunto optimista de eventos valorados durante esta sesión de Historial.
  ///
  /// `submitReview` escribe `ratedEventIds` en Firestore, pero el `snapshots()`
  /// de [ratedEventIds] puede tardar uno o varios segundos en propagar el cambio
  /// al cliente (round-trip callable → commit de la transacción → listener). Para
  /// que el botón "Valorar" pase a "valorado" en el acto, tras un envío exitoso
  /// registramos aquí el `eventId` y lo fusionamos con el stream en
  /// `historyViewModel`. Siempre es un subconjunto de lo que acabará llegando por
  /// Firestore, así que no introduce incoherencias entre dispositivos.
  ///
  /// Copied from [OptimisticRatedEventIds].
  const OptimisticRatedEventIdsFamily();

  /// Conjunto optimista de eventos valorados durante esta sesión de Historial.
  ///
  /// `submitReview` escribe `ratedEventIds` en Firestore, pero el `snapshots()`
  /// de [ratedEventIds] puede tardar uno o varios segundos en propagar el cambio
  /// al cliente (round-trip callable → commit de la transacción → listener). Para
  /// que el botón "Valorar" pase a "valorado" en el acto, tras un envío exitoso
  /// registramos aquí el `eventId` y lo fusionamos con el stream en
  /// `historyViewModel`. Siempre es un subconjunto de lo que acabará llegando por
  /// Firestore, así que no introduce incoherencias entre dispositivos.
  ///
  /// Copied from [OptimisticRatedEventIds].
  OptimisticRatedEventIdsProvider call(
    String homeId,
  ) {
    return OptimisticRatedEventIdsProvider(
      homeId,
    );
  }

  @override
  OptimisticRatedEventIdsProvider getProviderOverride(
    covariant OptimisticRatedEventIdsProvider provider,
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
  String? get name => r'optimisticRatedEventIdsProvider';
}

/// Conjunto optimista de eventos valorados durante esta sesión de Historial.
///
/// `submitReview` escribe `ratedEventIds` en Firestore, pero el `snapshots()`
/// de [ratedEventIds] puede tardar uno o varios segundos en propagar el cambio
/// al cliente (round-trip callable → commit de la transacción → listener). Para
/// que el botón "Valorar" pase a "valorado" en el acto, tras un envío exitoso
/// registramos aquí el `eventId` y lo fusionamos con el stream en
/// `historyViewModel`. Siempre es un subconjunto de lo que acabará llegando por
/// Firestore, así que no introduce incoherencias entre dispositivos.
///
/// Copied from [OptimisticRatedEventIds].
class OptimisticRatedEventIdsProvider extends AutoDisposeNotifierProviderImpl<
    OptimisticRatedEventIds, Set<String>> {
  /// Conjunto optimista de eventos valorados durante esta sesión de Historial.
  ///
  /// `submitReview` escribe `ratedEventIds` en Firestore, pero el `snapshots()`
  /// de [ratedEventIds] puede tardar uno o varios segundos en propagar el cambio
  /// al cliente (round-trip callable → commit de la transacción → listener). Para
  /// que el botón "Valorar" pase a "valorado" en el acto, tras un envío exitoso
  /// registramos aquí el `eventId` y lo fusionamos con el stream en
  /// `historyViewModel`. Siempre es un subconjunto de lo que acabará llegando por
  /// Firestore, así que no introduce incoherencias entre dispositivos.
  ///
  /// Copied from [OptimisticRatedEventIds].
  OptimisticRatedEventIdsProvider(
    String homeId,
  ) : this._internal(
          () => OptimisticRatedEventIds()..homeId = homeId,
          from: optimisticRatedEventIdsProvider,
          name: r'optimisticRatedEventIdsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$optimisticRatedEventIdsHash,
          dependencies: OptimisticRatedEventIdsFamily._dependencies,
          allTransitiveDependencies:
              OptimisticRatedEventIdsFamily._allTransitiveDependencies,
          homeId: homeId,
        );

  OptimisticRatedEventIdsProvider._internal(
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
  Set<String> runNotifierBuild(
    covariant OptimisticRatedEventIds notifier,
  ) {
    return notifier.build(
      homeId,
    );
  }

  @override
  Override overrideWith(OptimisticRatedEventIds Function() create) {
    return ProviderOverride(
      origin: this,
      override: OptimisticRatedEventIdsProvider._internal(
        () => create()..homeId = homeId,
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
  AutoDisposeNotifierProviderElement<OptimisticRatedEventIds, Set<String>>
      createElement() {
    return _OptimisticRatedEventIdsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is OptimisticRatedEventIdsProvider && other.homeId == homeId;
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
mixin OptimisticRatedEventIdsRef
    on AutoDisposeNotifierProviderRef<Set<String>> {
  /// The parameter `homeId` of this provider.
  String get homeId;
}

class _OptimisticRatedEventIdsProviderElement
    extends AutoDisposeNotifierProviderElement<OptimisticRatedEventIds,
        Set<String>> with OptimisticRatedEventIdsRef {
  _OptimisticRatedEventIdsProviderElement(super.provider);

  @override
  String get homeId => (origin as OptimisticRatedEventIdsProvider).homeId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
