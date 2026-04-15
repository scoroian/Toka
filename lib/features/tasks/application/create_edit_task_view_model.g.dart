// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_edit_task_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$createEditTaskViewModelHash() =>
    r'8bdc74d1396bd783cb7d98f96aa1eb327ccd3f48';

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

/// See also [createEditTaskViewModel].
@ProviderFor(createEditTaskViewModel)
const createEditTaskViewModelProvider = CreateEditTaskViewModelFamily();

/// See also [createEditTaskViewModel].
class CreateEditTaskViewModelFamily extends Family<CreateEditTaskViewModel> {
  /// See also [createEditTaskViewModel].
  const CreateEditTaskViewModelFamily();

  /// See also [createEditTaskViewModel].
  CreateEditTaskViewModelProvider call(
    String? editTaskId,
  ) {
    return CreateEditTaskViewModelProvider(
      editTaskId,
    );
  }

  @override
  CreateEditTaskViewModelProvider getProviderOverride(
    covariant CreateEditTaskViewModelProvider provider,
  ) {
    return call(
      provider.editTaskId,
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
  String? get name => r'createEditTaskViewModelProvider';
}

/// See also [createEditTaskViewModel].
class CreateEditTaskViewModelProvider
    extends AutoDisposeProvider<CreateEditTaskViewModel> {
  /// See also [createEditTaskViewModel].
  CreateEditTaskViewModelProvider(
    String? editTaskId,
  ) : this._internal(
          (ref) => createEditTaskViewModel(
            ref as CreateEditTaskViewModelRef,
            editTaskId,
          ),
          from: createEditTaskViewModelProvider,
          name: r'createEditTaskViewModelProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$createEditTaskViewModelHash,
          dependencies: CreateEditTaskViewModelFamily._dependencies,
          allTransitiveDependencies:
              CreateEditTaskViewModelFamily._allTransitiveDependencies,
          editTaskId: editTaskId,
        );

  CreateEditTaskViewModelProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.editTaskId,
  }) : super.internal();

  final String? editTaskId;

  @override
  Override overrideWith(
    CreateEditTaskViewModel Function(CreateEditTaskViewModelRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CreateEditTaskViewModelProvider._internal(
        (ref) => create(ref as CreateEditTaskViewModelRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        editTaskId: editTaskId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<CreateEditTaskViewModel> createElement() {
    return _CreateEditTaskViewModelProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CreateEditTaskViewModelProvider &&
        other.editTaskId == editTaskId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, editTaskId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CreateEditTaskViewModelRef
    on AutoDisposeProviderRef<CreateEditTaskViewModel> {
  /// The parameter `editTaskId` of this provider.
  String? get editTaskId;
}

class _CreateEditTaskViewModelProviderElement
    extends AutoDisposeProviderElement<CreateEditTaskViewModel>
    with CreateEditTaskViewModelRef {
  _CreateEditTaskViewModelProviderElement(super.provider);

  @override
  String? get editTaskId =>
      (origin as CreateEditTaskViewModelProvider).editTaskId;
}

String _$createEditTaskViewModelNotifierHash() =>
    r'a0592226d6a193e45621a7ce99b53a88ffe728d5';

abstract class _$CreateEditTaskViewModelNotifier
    extends BuildlessAutoDisposeNotifier<_CreateEditVMState> {
  late final String? editTaskId;

  _CreateEditVMState build(
    String? editTaskId,
  );
}

/// See also [CreateEditTaskViewModelNotifier].
@ProviderFor(CreateEditTaskViewModelNotifier)
const createEditTaskViewModelNotifierProvider =
    CreateEditTaskViewModelNotifierFamily();

/// See also [CreateEditTaskViewModelNotifier].
class CreateEditTaskViewModelNotifierFamily extends Family<_CreateEditVMState> {
  /// See also [CreateEditTaskViewModelNotifier].
  const CreateEditTaskViewModelNotifierFamily();

  /// See also [CreateEditTaskViewModelNotifier].
  CreateEditTaskViewModelNotifierProvider call(
    String? editTaskId,
  ) {
    return CreateEditTaskViewModelNotifierProvider(
      editTaskId,
    );
  }

  @override
  CreateEditTaskViewModelNotifierProvider getProviderOverride(
    covariant CreateEditTaskViewModelNotifierProvider provider,
  ) {
    return call(
      provider.editTaskId,
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
  String? get name => r'createEditTaskViewModelNotifierProvider';
}

/// See also [CreateEditTaskViewModelNotifier].
class CreateEditTaskViewModelNotifierProvider
    extends AutoDisposeNotifierProviderImpl<CreateEditTaskViewModelNotifier,
        _CreateEditVMState> {
  /// See also [CreateEditTaskViewModelNotifier].
  CreateEditTaskViewModelNotifierProvider(
    String? editTaskId,
  ) : this._internal(
          () => CreateEditTaskViewModelNotifier()..editTaskId = editTaskId,
          from: createEditTaskViewModelNotifierProvider,
          name: r'createEditTaskViewModelNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$createEditTaskViewModelNotifierHash,
          dependencies: CreateEditTaskViewModelNotifierFamily._dependencies,
          allTransitiveDependencies:
              CreateEditTaskViewModelNotifierFamily._allTransitiveDependencies,
          editTaskId: editTaskId,
        );

  CreateEditTaskViewModelNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.editTaskId,
  }) : super.internal();

  final String? editTaskId;

  @override
  _CreateEditVMState runNotifierBuild(
    covariant CreateEditTaskViewModelNotifier notifier,
  ) {
    return notifier.build(
      editTaskId,
    );
  }

  @override
  Override overrideWith(CreateEditTaskViewModelNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: CreateEditTaskViewModelNotifierProvider._internal(
        () => create()..editTaskId = editTaskId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        editTaskId: editTaskId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<CreateEditTaskViewModelNotifier,
      _CreateEditVMState> createElement() {
    return _CreateEditTaskViewModelNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CreateEditTaskViewModelNotifierProvider &&
        other.editTaskId == editTaskId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, editTaskId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CreateEditTaskViewModelNotifierRef
    on AutoDisposeNotifierProviderRef<_CreateEditVMState> {
  /// The parameter `editTaskId` of this provider.
  String? get editTaskId;
}

class _CreateEditTaskViewModelNotifierProviderElement
    extends AutoDisposeNotifierProviderElement<CreateEditTaskViewModelNotifier,
        _CreateEditVMState> with CreateEditTaskViewModelNotifierRef {
  _CreateEditTaskViewModelNotifierProviderElement(super.provider);

  @override
  String? get editTaskId =>
      (origin as CreateEditTaskViewModelNotifierProvider).editTaskId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
