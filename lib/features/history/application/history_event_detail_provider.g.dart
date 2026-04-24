// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_event_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$historyEventDetailHash() =>
    r'74bd80b20d68b9582df1f82274a7c7099af870f1';

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

/// Stream del evento con sus reviews asociadas.
///
/// Implementación: escuchamos el evento y refetcheamos reviews en cada cambio.
/// El volumen típico (≤ n_miembros del hogar) mantiene el coste bajo. Si subiera,
/// se puede introducir un snapshot concurrente de la subcolección.
///
/// Copied from [historyEventDetail].
@ProviderFor(historyEventDetail)
const historyEventDetailProvider = HistoryEventDetailFamily();

/// Stream del evento con sus reviews asociadas.
///
/// Implementación: escuchamos el evento y refetcheamos reviews en cada cambio.
/// El volumen típico (≤ n_miembros del hogar) mantiene el coste bajo. Si subiera,
/// se puede introducir un snapshot concurrente de la subcolección.
///
/// Copied from [historyEventDetail].
class HistoryEventDetailFamily extends Family<AsyncValue<HistoryEventDetail>> {
  /// Stream del evento con sus reviews asociadas.
  ///
  /// Implementación: escuchamos el evento y refetcheamos reviews en cada cambio.
  /// El volumen típico (≤ n_miembros del hogar) mantiene el coste bajo. Si subiera,
  /// se puede introducir un snapshot concurrente de la subcolección.
  ///
  /// Copied from [historyEventDetail].
  const HistoryEventDetailFamily();

  /// Stream del evento con sus reviews asociadas.
  ///
  /// Implementación: escuchamos el evento y refetcheamos reviews en cada cambio.
  /// El volumen típico (≤ n_miembros del hogar) mantiene el coste bajo. Si subiera,
  /// se puede introducir un snapshot concurrente de la subcolección.
  ///
  /// Copied from [historyEventDetail].
  HistoryEventDetailProvider call({
    required String homeId,
    required String eventId,
  }) {
    return HistoryEventDetailProvider(
      homeId: homeId,
      eventId: eventId,
    );
  }

  @override
  HistoryEventDetailProvider getProviderOverride(
    covariant HistoryEventDetailProvider provider,
  ) {
    return call(
      homeId: provider.homeId,
      eventId: provider.eventId,
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
  String? get name => r'historyEventDetailProvider';
}

/// Stream del evento con sus reviews asociadas.
///
/// Implementación: escuchamos el evento y refetcheamos reviews en cada cambio.
/// El volumen típico (≤ n_miembros del hogar) mantiene el coste bajo. Si subiera,
/// se puede introducir un snapshot concurrente de la subcolección.
///
/// Copied from [historyEventDetail].
class HistoryEventDetailProvider
    extends AutoDisposeStreamProvider<HistoryEventDetail> {
  /// Stream del evento con sus reviews asociadas.
  ///
  /// Implementación: escuchamos el evento y refetcheamos reviews en cada cambio.
  /// El volumen típico (≤ n_miembros del hogar) mantiene el coste bajo. Si subiera,
  /// se puede introducir un snapshot concurrente de la subcolección.
  ///
  /// Copied from [historyEventDetail].
  HistoryEventDetailProvider({
    required String homeId,
    required String eventId,
  }) : this._internal(
          (ref) => historyEventDetail(
            ref as HistoryEventDetailRef,
            homeId: homeId,
            eventId: eventId,
          ),
          from: historyEventDetailProvider,
          name: r'historyEventDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$historyEventDetailHash,
          dependencies: HistoryEventDetailFamily._dependencies,
          allTransitiveDependencies:
              HistoryEventDetailFamily._allTransitiveDependencies,
          homeId: homeId,
          eventId: eventId,
        );

  HistoryEventDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.homeId,
    required this.eventId,
  }) : super.internal();

  final String homeId;
  final String eventId;

  @override
  Override overrideWith(
    Stream<HistoryEventDetail> Function(HistoryEventDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HistoryEventDetailProvider._internal(
        (ref) => create(ref as HistoryEventDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        homeId: homeId,
        eventId: eventId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<HistoryEventDetail> createElement() {
    return _HistoryEventDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HistoryEventDetailProvider &&
        other.homeId == homeId &&
        other.eventId == eventId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, homeId.hashCode);
    hash = _SystemHash.combine(hash, eventId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin HistoryEventDetailRef
    on AutoDisposeStreamProviderRef<HistoryEventDetail> {
  /// The parameter `homeId` of this provider.
  String get homeId;

  /// The parameter `eventId` of this provider.
  String get eventId;
}

class _HistoryEventDetailProviderElement
    extends AutoDisposeStreamProviderElement<HistoryEventDetail>
    with HistoryEventDetailRef {
  _HistoryEventDetailProviderElement(super.provider);

  @override
  String get homeId => (origin as HistoryEventDetailProvider).homeId;
  @override
  String get eventId => (origin as HistoryEventDetailProvider).eventId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
