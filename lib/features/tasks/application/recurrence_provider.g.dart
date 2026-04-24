// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurrence_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$upcomingOccurrencesHash() =>
    r'63bb7e2fe8c9538331449f338a519a419be0cea7';

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

/// See also [upcomingOccurrences].
@ProviderFor(upcomingOccurrences)
const upcomingOccurrencesProvider = UpcomingOccurrencesFamily();

/// See also [upcomingOccurrences].
class UpcomingOccurrencesFamily extends Family<List<DateTime>> {
  /// See also [upcomingOccurrences].
  const UpcomingOccurrencesFamily();

  /// See also [upcomingOccurrences].
  UpcomingOccurrencesProvider call(
    RecurrenceRule? rule,
  ) {
    return UpcomingOccurrencesProvider(
      rule,
    );
  }

  @override
  UpcomingOccurrencesProvider getProviderOverride(
    covariant UpcomingOccurrencesProvider provider,
  ) {
    return call(
      provider.rule,
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
  String? get name => r'upcomingOccurrencesProvider';
}

/// See also [upcomingOccurrences].
class UpcomingOccurrencesProvider extends AutoDisposeProvider<List<DateTime>> {
  /// See also [upcomingOccurrences].
  UpcomingOccurrencesProvider(
    RecurrenceRule? rule,
  ) : this._internal(
          (ref) => upcomingOccurrences(
            ref as UpcomingOccurrencesRef,
            rule,
          ),
          from: upcomingOccurrencesProvider,
          name: r'upcomingOccurrencesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$upcomingOccurrencesHash,
          dependencies: UpcomingOccurrencesFamily._dependencies,
          allTransitiveDependencies:
              UpcomingOccurrencesFamily._allTransitiveDependencies,
          rule: rule,
        );

  UpcomingOccurrencesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.rule,
  }) : super.internal();

  final RecurrenceRule? rule;

  @override
  Override overrideWith(
    List<DateTime> Function(UpcomingOccurrencesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UpcomingOccurrencesProvider._internal(
        (ref) => create(ref as UpcomingOccurrencesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        rule: rule,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<List<DateTime>> createElement() {
    return _UpcomingOccurrencesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UpcomingOccurrencesProvider && other.rule == rule;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, rule.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UpcomingOccurrencesRef on AutoDisposeProviderRef<List<DateTime>> {
  /// The parameter `rule` of this provider.
  RecurrenceRule? get rule;
}

class _UpcomingOccurrencesProviderElement
    extends AutoDisposeProviderElement<List<DateTime>>
    with UpcomingOccurrencesRef {
  _UpcomingOccurrencesProviderElement(super.provider);

  @override
  RecurrenceRule? get rule => (origin as UpcomingOccurrencesProvider).rule;
}

String _$recurrenceNotifierHash() =>
    r'5e37495d587be544cacbf2fbea41d294122fd4a5';

/// See also [RecurrenceNotifier].
@ProviderFor(RecurrenceNotifier)
final recurrenceNotifierProvider = AutoDisposeNotifierProvider<
    RecurrenceNotifier, RecurrenceFormState>.internal(
  RecurrenceNotifier.new,
  name: r'recurrenceNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$recurrenceNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$RecurrenceNotifier = AutoDisposeNotifier<RecurrenceFormState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
