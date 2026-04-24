// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_reviews_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$memberVisibleReviewsHash() =>
    r'6c6f395f456514dce81b500e2a4cf3bc32f1fbd9';

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

/// Devuelve hasta 5 reviews visibles para `viewerUid` sobre `memberUid`.
///
/// Política de visibilidad:
/// - Si `viewerUid == memberUid`: devuelve las últimas 5 reviews recibidas por
///   él (es performer) — rules permiten leerlas todas.
/// - Si no: devuelve las últimas 5 reviews que `viewerUid` ha escrito sobre
///   `memberUid`. Si no ha escrito ninguna, lista vacía.
///
/// Devuelve lista vacía si faltan parámetros (p.ej. viewer anónimo).
///
/// Copied from [memberVisibleReviews].
@ProviderFor(memberVisibleReviews)
const memberVisibleReviewsProvider = MemberVisibleReviewsFamily();

/// Devuelve hasta 5 reviews visibles para `viewerUid` sobre `memberUid`.
///
/// Política de visibilidad:
/// - Si `viewerUid == memberUid`: devuelve las últimas 5 reviews recibidas por
///   él (es performer) — rules permiten leerlas todas.
/// - Si no: devuelve las últimas 5 reviews que `viewerUid` ha escrito sobre
///   `memberUid`. Si no ha escrito ninguna, lista vacía.
///
/// Devuelve lista vacía si faltan parámetros (p.ej. viewer anónimo).
///
/// Copied from [memberVisibleReviews].
class MemberVisibleReviewsFamily
    extends Family<AsyncValue<List<MemberReviewSummary>>> {
  /// Devuelve hasta 5 reviews visibles para `viewerUid` sobre `memberUid`.
  ///
  /// Política de visibilidad:
  /// - Si `viewerUid == memberUid`: devuelve las últimas 5 reviews recibidas por
  ///   él (es performer) — rules permiten leerlas todas.
  /// - Si no: devuelve las últimas 5 reviews que `viewerUid` ha escrito sobre
  ///   `memberUid`. Si no ha escrito ninguna, lista vacía.
  ///
  /// Devuelve lista vacía si faltan parámetros (p.ej. viewer anónimo).
  ///
  /// Copied from [memberVisibleReviews].
  const MemberVisibleReviewsFamily();

  /// Devuelve hasta 5 reviews visibles para `viewerUid` sobre `memberUid`.
  ///
  /// Política de visibilidad:
  /// - Si `viewerUid == memberUid`: devuelve las últimas 5 reviews recibidas por
  ///   él (es performer) — rules permiten leerlas todas.
  /// - Si no: devuelve las últimas 5 reviews que `viewerUid` ha escrito sobre
  ///   `memberUid`. Si no ha escrito ninguna, lista vacía.
  ///
  /// Devuelve lista vacía si faltan parámetros (p.ej. viewer anónimo).
  ///
  /// Copied from [memberVisibleReviews].
  MemberVisibleReviewsProvider call({
    required String memberUid,
    required String viewerUid,
  }) {
    return MemberVisibleReviewsProvider(
      memberUid: memberUid,
      viewerUid: viewerUid,
    );
  }

  @override
  MemberVisibleReviewsProvider getProviderOverride(
    covariant MemberVisibleReviewsProvider provider,
  ) {
    return call(
      memberUid: provider.memberUid,
      viewerUid: provider.viewerUid,
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
  String? get name => r'memberVisibleReviewsProvider';
}

/// Devuelve hasta 5 reviews visibles para `viewerUid` sobre `memberUid`.
///
/// Política de visibilidad:
/// - Si `viewerUid == memberUid`: devuelve las últimas 5 reviews recibidas por
///   él (es performer) — rules permiten leerlas todas.
/// - Si no: devuelve las últimas 5 reviews que `viewerUid` ha escrito sobre
///   `memberUid`. Si no ha escrito ninguna, lista vacía.
///
/// Devuelve lista vacía si faltan parámetros (p.ej. viewer anónimo).
///
/// Copied from [memberVisibleReviews].
class MemberVisibleReviewsProvider
    extends AutoDisposeFutureProvider<List<MemberReviewSummary>> {
  /// Devuelve hasta 5 reviews visibles para `viewerUid` sobre `memberUid`.
  ///
  /// Política de visibilidad:
  /// - Si `viewerUid == memberUid`: devuelve las últimas 5 reviews recibidas por
  ///   él (es performer) — rules permiten leerlas todas.
  /// - Si no: devuelve las últimas 5 reviews que `viewerUid` ha escrito sobre
  ///   `memberUid`. Si no ha escrito ninguna, lista vacía.
  ///
  /// Devuelve lista vacía si faltan parámetros (p.ej. viewer anónimo).
  ///
  /// Copied from [memberVisibleReviews].
  MemberVisibleReviewsProvider({
    required String memberUid,
    required String viewerUid,
  }) : this._internal(
          (ref) => memberVisibleReviews(
            ref as MemberVisibleReviewsRef,
            memberUid: memberUid,
            viewerUid: viewerUid,
          ),
          from: memberVisibleReviewsProvider,
          name: r'memberVisibleReviewsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$memberVisibleReviewsHash,
          dependencies: MemberVisibleReviewsFamily._dependencies,
          allTransitiveDependencies:
              MemberVisibleReviewsFamily._allTransitiveDependencies,
          memberUid: memberUid,
          viewerUid: viewerUid,
        );

  MemberVisibleReviewsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.memberUid,
    required this.viewerUid,
  }) : super.internal();

  final String memberUid;
  final String viewerUid;

  @override
  Override overrideWith(
    FutureOr<List<MemberReviewSummary>> Function(
            MemberVisibleReviewsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MemberVisibleReviewsProvider._internal(
        (ref) => create(ref as MemberVisibleReviewsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        memberUid: memberUid,
        viewerUid: viewerUid,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<MemberReviewSummary>> createElement() {
    return _MemberVisibleReviewsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MemberVisibleReviewsProvider &&
        other.memberUid == memberUid &&
        other.viewerUid == viewerUid;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, memberUid.hashCode);
    hash = _SystemHash.combine(hash, viewerUid.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MemberVisibleReviewsRef
    on AutoDisposeFutureProviderRef<List<MemberReviewSummary>> {
  /// The parameter `memberUid` of this provider.
  String get memberUid;

  /// The parameter `viewerUid` of this provider.
  String get viewerUid;
}

class _MemberVisibleReviewsProviderElement
    extends AutoDisposeFutureProviderElement<List<MemberReviewSummary>>
    with MemberVisibleReviewsRef {
  _MemberVisibleReviewsProviderElement(super.provider);

  @override
  String get memberUid => (origin as MemberVisibleReviewsProvider).memberUid;
  @override
  String get viewerUid => (origin as MemberVisibleReviewsProvider).viewerUid;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
