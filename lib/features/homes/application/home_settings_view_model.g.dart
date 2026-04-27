// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_settings_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$homeSettingsViewModelHash() =>
    r'8d8ec49f9e6b2c662f4a62b7b08f63a0a69ad597';

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

/// See also [homeSettingsViewModel].
@ProviderFor(homeSettingsViewModel)
const homeSettingsViewModelProvider = HomeSettingsViewModelFamily();

/// See also [homeSettingsViewModel].
class HomeSettingsViewModelFamily extends Family<HomeSettingsViewModel> {
  /// See also [homeSettingsViewModel].
  const HomeSettingsViewModelFamily();

  /// See also [homeSettingsViewModel].
  HomeSettingsViewModelProvider call(
    AppLocalizations l10n,
  ) {
    return HomeSettingsViewModelProvider(
      l10n,
    );
  }

  @override
  HomeSettingsViewModelProvider getProviderOverride(
    covariant HomeSettingsViewModelProvider provider,
  ) {
    return call(
      provider.l10n,
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
  String? get name => r'homeSettingsViewModelProvider';
}

/// See also [homeSettingsViewModel].
class HomeSettingsViewModelProvider
    extends AutoDisposeProvider<HomeSettingsViewModel> {
  /// See also [homeSettingsViewModel].
  HomeSettingsViewModelProvider(
    AppLocalizations l10n,
  ) : this._internal(
          (ref) => homeSettingsViewModel(
            ref as HomeSettingsViewModelRef,
            l10n,
          ),
          from: homeSettingsViewModelProvider,
          name: r'homeSettingsViewModelProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$homeSettingsViewModelHash,
          dependencies: HomeSettingsViewModelFamily._dependencies,
          allTransitiveDependencies:
              HomeSettingsViewModelFamily._allTransitiveDependencies,
          l10n: l10n,
        );

  HomeSettingsViewModelProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.l10n,
  }) : super.internal();

  final AppLocalizations l10n;

  @override
  Override overrideWith(
    HomeSettingsViewModel Function(HomeSettingsViewModelRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HomeSettingsViewModelProvider._internal(
        (ref) => create(ref as HomeSettingsViewModelRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        l10n: l10n,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<HomeSettingsViewModel> createElement() {
    return _HomeSettingsViewModelProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HomeSettingsViewModelProvider && other.l10n == l10n;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, l10n.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin HomeSettingsViewModelRef
    on AutoDisposeProviderRef<HomeSettingsViewModel> {
  /// The parameter `l10n` of this provider.
  AppLocalizations get l10n;
}

class _HomeSettingsViewModelProviderElement
    extends AutoDisposeProviderElement<HomeSettingsViewModel>
    with HomeSettingsViewModelRef {
  _HomeSettingsViewModelProviderElement(super.provider);

  @override
  AppLocalizations get l10n => (origin as HomeSettingsViewModelProvider).l10n;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
