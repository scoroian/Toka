// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tasks_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$tasksRepositoryHash() => r'6350600041ccb34d6b426db11d4da0a9935d39ff';

/// See also [tasksRepository].
@ProviderFor(tasksRepository)
final tasksRepositoryProvider = Provider<TasksRepository>.internal(
  tasksRepository,
  name: r'tasksRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$tasksRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TasksRepositoryRef = ProviderRef<TasksRepository>;
String _$homeTasksHash() => r'9abf66298cbfcee377da2a29bcc131d9a0aa719c';

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

/// See also [homeTasks].
@ProviderFor(homeTasks)
const homeTasksProvider = HomeTasksFamily();

/// See also [homeTasks].
class HomeTasksFamily extends Family<AsyncValue<List<Task>>> {
  /// See also [homeTasks].
  const HomeTasksFamily();

  /// See also [homeTasks].
  HomeTasksProvider call(
    String homeId,
  ) {
    return HomeTasksProvider(
      homeId,
    );
  }

  @override
  HomeTasksProvider getProviderOverride(
    covariant HomeTasksProvider provider,
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
  String? get name => r'homeTasksProvider';
}

/// See also [homeTasks].
class HomeTasksProvider extends AutoDisposeStreamProvider<List<Task>> {
  /// See also [homeTasks].
  HomeTasksProvider(
    String homeId,
  ) : this._internal(
          (ref) => homeTasks(
            ref as HomeTasksRef,
            homeId,
          ),
          from: homeTasksProvider,
          name: r'homeTasksProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$homeTasksHash,
          dependencies: HomeTasksFamily._dependencies,
          allTransitiveDependencies: HomeTasksFamily._allTransitiveDependencies,
          homeId: homeId,
        );

  HomeTasksProvider._internal(
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
    Stream<List<Task>> Function(HomeTasksRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HomeTasksProvider._internal(
        (ref) => create(ref as HomeTasksRef),
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
  AutoDisposeStreamProviderElement<List<Task>> createElement() {
    return _HomeTasksProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HomeTasksProvider && other.homeId == homeId;
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
mixin HomeTasksRef on AutoDisposeStreamProviderRef<List<Task>> {
  /// The parameter `homeId` of this provider.
  String get homeId;
}

class _HomeTasksProviderElement
    extends AutoDisposeStreamProviderElement<List<Task>> with HomeTasksRef {
  _HomeTasksProviderElement(super.provider);

  @override
  String get homeId => (origin as HomeTasksProvider).homeId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
