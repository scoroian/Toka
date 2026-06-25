// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$supportRepositoryHash() => r'389890e42d9c4ade354d12bf420e9d7f87f86975';

/// See also [supportRepository].
@ProviderFor(supportRepository)
final supportRepositoryProvider = Provider<SupportRepository>.internal(
  supportRepository,
  name: r'supportRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$supportRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SupportRepositoryRef = ProviderRef<SupportRepository>;
String _$isSupportAgentHash() => r'9745396bebe1374b682a54469b148e71ef448eb9';

/// True si la cuenta autenticada tiene el custom claim `support`. Gatea la
/// entrada de Ajustes y la propia pantalla (defensa en profundidad; el backend
/// vuelve a exigir el claim + App Check).
///
/// Copied from [isSupportAgent].
@ProviderFor(isSupportAgent)
final isSupportAgentProvider = AutoDisposeFutureProvider<bool>.internal(
  isSupportAgent,
  name: r'isSupportAgentProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isSupportAgentHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsSupportAgentRef = AutoDisposeFutureProviderRef<bool>;
String _$homeDiagnosticsHash() => r'e1cb71404606ac5cf00e10cdb602acbc1e3da5ee';

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

/// Diagnóstico de un hogar concreto (se re-ejecuta al cambiar homeId).
///
/// Copied from [homeDiagnostics].
@ProviderFor(homeDiagnostics)
const homeDiagnosticsProvider = HomeDiagnosticsFamily();

/// Diagnóstico de un hogar concreto (se re-ejecuta al cambiar homeId).
///
/// Copied from [homeDiagnostics].
class HomeDiagnosticsFamily extends Family<AsyncValue<HomeDiagnostics>> {
  /// Diagnóstico de un hogar concreto (se re-ejecuta al cambiar homeId).
  ///
  /// Copied from [homeDiagnostics].
  const HomeDiagnosticsFamily();

  /// Diagnóstico de un hogar concreto (se re-ejecuta al cambiar homeId).
  ///
  /// Copied from [homeDiagnostics].
  HomeDiagnosticsProvider call(
    String homeId,
  ) {
    return HomeDiagnosticsProvider(
      homeId,
    );
  }

  @override
  HomeDiagnosticsProvider getProviderOverride(
    covariant HomeDiagnosticsProvider provider,
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
  String? get name => r'homeDiagnosticsProvider';
}

/// Diagnóstico de un hogar concreto (se re-ejecuta al cambiar homeId).
///
/// Copied from [homeDiagnostics].
class HomeDiagnosticsProvider
    extends AutoDisposeFutureProvider<HomeDiagnostics> {
  /// Diagnóstico de un hogar concreto (se re-ejecuta al cambiar homeId).
  ///
  /// Copied from [homeDiagnostics].
  HomeDiagnosticsProvider(
    String homeId,
  ) : this._internal(
          (ref) => homeDiagnostics(
            ref as HomeDiagnosticsRef,
            homeId,
          ),
          from: homeDiagnosticsProvider,
          name: r'homeDiagnosticsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$homeDiagnosticsHash,
          dependencies: HomeDiagnosticsFamily._dependencies,
          allTransitiveDependencies:
              HomeDiagnosticsFamily._allTransitiveDependencies,
          homeId: homeId,
        );

  HomeDiagnosticsProvider._internal(
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
    FutureOr<HomeDiagnostics> Function(HomeDiagnosticsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HomeDiagnosticsProvider._internal(
        (ref) => create(ref as HomeDiagnosticsRef),
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
  AutoDisposeFutureProviderElement<HomeDiagnostics> createElement() {
    return _HomeDiagnosticsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HomeDiagnosticsProvider && other.homeId == homeId;
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
mixin HomeDiagnosticsRef on AutoDisposeFutureProviderRef<HomeDiagnostics> {
  /// The parameter `homeId` of this provider.
  String get homeId;
}

class _HomeDiagnosticsProviderElement
    extends AutoDisposeFutureProviderElement<HomeDiagnostics>
    with HomeDiagnosticsRef {
  _HomeDiagnosticsProviderElement(super.provider);

  @override
  String get homeId => (origin as HomeDiagnosticsProvider).homeId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
