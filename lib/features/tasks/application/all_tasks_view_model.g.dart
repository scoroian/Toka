// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'all_tasks_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$allTasksViewModelHash() => r'5e990c5adefa5c17a4b3d51e44df70cd02e2c9ad';

/// See also [allTasksViewModel].
@ProviderFor(allTasksViewModel)
final allTasksViewModelProvider =
    AutoDisposeProvider<AllTasksViewModel>.internal(
  allTasksViewModel,
  name: r'allTasksViewModelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$allTasksViewModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllTasksViewModelRef = AutoDisposeProviderRef<AllTasksViewModel>;
String _$allTasksFilterNotifierHash() =>
    r'2c7a92202946f6b06a40191e7bcfaf37ca106af8';

/// See also [AllTasksFilterNotifier].
@ProviderFor(AllTasksFilterNotifier)
final allTasksFilterNotifierProvider = AutoDisposeNotifierProvider<
    AllTasksFilterNotifier, AllTasksFilter>.internal(
  AllTasksFilterNotifier.new,
  name: r'allTasksFilterNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$allTasksFilterNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AllTasksFilterNotifier = AutoDisposeNotifier<AllTasksFilter>;
String _$allTasksSelectionNotifierHash() =>
    r'dd4a888dce3be60546594340078cd859584605cb';

/// See also [AllTasksSelectionNotifier].
@ProviderFor(AllTasksSelectionNotifier)
final allTasksSelectionNotifierProvider = AutoDisposeNotifierProvider<
    AllTasksSelectionNotifier, Set<String>>.internal(
  AllTasksSelectionNotifier.new,
  name: r'allTasksSelectionNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$allTasksSelectionNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AllTasksSelectionNotifier = AutoDisposeNotifier<Set<String>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
