import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_provider.dart';
import '../../homes/application/current_home_provider.dart';
import '../../members/application/members_provider.dart';
import '../domain/personal_metrics.dart';

part 'personal_metrics_view_model.g.dart';

/// Métricas personales del usuario actual en su hogar activo.
///
/// Combina el uid autenticado, el hogar actual y la lista de miembros (que ya
/// excluye a quienes se fueron) para componer [PersonalMetrics] con
/// [computePersonalMetrics]. Devuelve loading/error/data espejando la carga de
/// miembros. La pantalla aplica el gating por Toka Plus por separado.
@riverpod
AsyncValue<PersonalMetrics> personalMetricsViewModel(
  PersonalMetricsViewModelRef ref,
) {
  final uid = ref.watch(authProvider).whenOrNull(authenticated: (u) => u.uid);
  final homeAsync = ref.watch(currentHomeProvider);
  final homeId = homeAsync.valueOrNull?.id;

  if (uid == null) return AsyncValue.data(PersonalMetrics.empty());
  if (homeId == null) {
    return homeAsync.isLoading
        ? const AsyncValue.loading()
        : AsyncValue.data(PersonalMetrics.empty());
  }

  final membersAsync = ref.watch(homeMembersProvider(homeId));
  return membersAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
    data: (members) =>
        AsyncValue.data(computePersonalMetrics(uid: uid, members: members)),
  );
}
