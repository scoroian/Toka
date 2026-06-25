import 'package:freezed_annotation/freezed_annotation.dart';

import '../../members/domain/member.dart';

part 'personal_metrics.freezed.dart';

/// Métricas personales del usuario actual, compuestas a partir de datos que YA
/// existen (doc de miembro + reparto entre miembros del hogar). No inventa
/// datos: todo sale de [Member].
@freezed
class PersonalMetrics with _$PersonalMetrics {
  const factory PersonalMetrics({
    required int tasksCompleted,
    required int passedCount,

    /// Puntualidad en % (0–100), derivada de `complianceRate`.
    required double compliancePercent,
    required int currentStreak,

    /// Puntuación media recibida (0–10).
    required double averageScore,

    /// Reparto: % de tareas completadas por el usuario sobre el total
    /// completado por los miembros vigentes del hogar (0–100).
    required double sharePercent,

    /// Si el usuario tiene alguna actividad (para el estado vacío).
    required bool hasData,
  }) = _PersonalMetrics;

  const PersonalMetrics._();

  /// Estado sin datos (usuario no encontrado o sin actividad).
  factory PersonalMetrics.empty() => const PersonalMetrics(
        tasksCompleted: 0,
        passedCount: 0,
        compliancePercent: 0,
        currentStreak: 0,
        averageScore: 0,
        sharePercent: 0,
        hasData: false,
      );
}

/// Compone [PersonalMetrics] del usuario [uid] a partir de la lista de
/// [members] vigentes del hogar (que ya excluye a quienes se fueron).
PersonalMetrics computePersonalMetrics({
  required String uid,
  required List<Member> members,
}) {
  Member? me;
  var totalCompleted = 0;
  for (final m in members) {
    totalCompleted += m.tasksCompleted;
    if (m.uid == uid) me = m;
  }
  if (me == null) return PersonalMetrics.empty();

  final share =
      totalCompleted == 0 ? 0.0 : me.tasksCompleted / totalCompleted * 100;
  final hasData = me.tasksCompleted > 0 ||
      me.passedCount > 0 ||
      me.averageScore > 0 ||
      me.currentStreak > 0;

  return PersonalMetrics(
    tasksCompleted: me.tasksCompleted,
    passedCount: me.passedCount,
    compliancePercent: me.complianceRate * 100,
    currentStreak: me.currentStreak,
    averageScore: me.averageScore,
    sharePercent: share,
    hasData: hasData,
  );
}
