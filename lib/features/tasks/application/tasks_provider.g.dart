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
String _$homeTasksHash() => r'5cedf3f487a9661f04c11f46032a4ed6e089e3d0';

/// See also [homeTasks].
@ProviderFor(homeTasks)
final homeTasksProvider = AutoDisposeStreamProvider<List<Task>>.internal(
  homeTasks,
  name: r'homeTasksProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$homeTasksHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HomeTasksRef = AutoDisposeStreamProviderRef<List<Task>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
