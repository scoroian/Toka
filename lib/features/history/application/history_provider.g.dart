// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$historyRepositoryHash() => r'f0c9132a445c35f789d217a31cd9d7f910847cdb';

/// See also [historyRepository].
@ProviderFor(historyRepository)
final historyRepositoryProvider = Provider<HistoryRepository>.internal(
  historyRepository,
  name: r'historyRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$historyRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HistoryRepositoryRef = ProviderRef<HistoryRepository>;
String _$historyNotifierHash() => r'6882879465b9a919504b0dbb59fda87a4ba9f256';

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

abstract class _$HistoryNotifier
    extends BuildlessAutoDisposeNotifier<AsyncValue<List<TaskEvent>>> {
  late final String homeId;

  AsyncValue<List<TaskEvent>> build(
    String homeId,
  );
}

/// See also [HistoryNotifier].
@ProviderFor(HistoryNotifier)
const historyNotifierProvider = HistoryNotifierFamily();

/// See also [HistoryNotifier].
class HistoryNotifierFamily extends Family<AsyncValue<List<TaskEvent>>> {
  /// See also [HistoryNotifier].
  const HistoryNotifierFamily();

  /// See also [HistoryNotifier].
  HistoryNotifierProvider call(
    String homeId,
  ) {
    return HistoryNotifierProvider(
      homeId,
    );
  }

  @override
  HistoryNotifierProvider getProviderOverride(
    covariant HistoryNotifierProvider provider,
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
  String? get name => r'historyNotifierProvider';
}

/// See also [HistoryNotifier].
class HistoryNotifierProvider extends AutoDisposeNotifierProviderImpl<
    HistoryNotifier, AsyncValue<List<TaskEvent>>> {
  /// See also [HistoryNotifier].
  HistoryNotifierProvider(
    String homeId,
  ) : this._internal(
          () => HistoryNotifier()..homeId = homeId,
          from: historyNotifierProvider,
          name: r'historyNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$historyNotifierHash,
          dependencies: HistoryNotifierFamily._dependencies,
          allTransitiveDependencies:
              HistoryNotifierFamily._allTransitiveDependencies,
          homeId: homeId,
        );

  HistoryNotifierProvider._internal(
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
  AsyncValue<List<TaskEvent>> runNotifierBuild(
    covariant HistoryNotifier notifier,
  ) {
    return notifier.build(
      homeId,
    );
  }

  @override
  Override overrideWith(HistoryNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: HistoryNotifierProvider._internal(
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
  AutoDisposeNotifierProviderElement<HistoryNotifier,
      AsyncValue<List<TaskEvent>>> createElement() {
    return _HistoryNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HistoryNotifierProvider && other.homeId == homeId;
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
mixin HistoryNotifierRef
    on AutoDisposeNotifierProviderRef<AsyncValue<List<TaskEvent>>> {
  /// The parameter `homeId` of this provider.
  String get homeId;
}

class _HistoryNotifierProviderElement
    extends AutoDisposeNotifierProviderElement<HistoryNotifier,
        AsyncValue<List<TaskEvent>>> with HistoryNotifierRef {
  _HistoryNotifierProviderElement(super.provider);

  @override
  String get homeId => (origin as HistoryNotifierProvider).homeId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
