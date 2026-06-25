// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_metrics_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$personalMetricsViewModelHash() =>
    r'52b9ce551dcab9a2b61868c45038446cd0805bac';

/// Métricas personales del usuario actual en su hogar activo.
///
/// Combina el uid autenticado, el hogar actual y la lista de miembros (que ya
/// excluye a quienes se fueron) para componer [PersonalMetrics] con
/// [computePersonalMetrics]. Devuelve loading/error/data espejando la carga de
/// miembros. La pantalla aplica el gating por Toka Plus por separado.
///
/// Copied from [personalMetricsViewModel].
@ProviderFor(personalMetricsViewModel)
final personalMetricsViewModelProvider =
    AutoDisposeProvider<AsyncValue<PersonalMetrics>>.internal(
  personalMetricsViewModel,
  name: r'personalMetricsViewModelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$personalMetricsViewModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PersonalMetricsViewModelRef
    = AutoDisposeProviderRef<AsyncValue<PersonalMetrics>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
