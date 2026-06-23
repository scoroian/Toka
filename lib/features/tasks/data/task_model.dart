import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/recurrence_rule.dart';
import '../domain/task.dart';
import '../domain/task_status.dart';

class TaskModel {
  static Task fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Task(
      id: doc.id,
      homeId: d['homeId'] as String,
      title: d['title'] as String,
      description: d['description'] as String?,
      visualKind: d['visualKind'] as String? ?? 'emoji',
      visualValue: d['visualValue'] as String? ?? '🏠',
      status: TaskStatus.fromString(d['status'] as String? ?? 'active'),
      recurrenceRule: _ruleFromMap(
          d['recurrenceRule'] as Map<String, dynamic>? ?? {}),
      assignmentMode: d['assignmentMode'] as String? ?? 'basicRotation',
      assignmentOrder:
          List<String>.from(d['assignmentOrder'] as List? ?? []),
      currentAssigneeUid: d['currentAssigneeUid'] as String?,
      nextDueAt: (d['nextDueAt'] as Timestamp).toDate().toLocal(),
      difficultyWeight: (d['difficultyWeight'] as num?)?.toDouble() ?? 1.0,
      completedCount90d: (d['completedCount90d'] as int?) ?? 0,
      createdByUid: d['createdByUid'] as String,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      updatedAt: (d['updatedAt'] as Timestamp).toDate(),
      onMissAssign: d['onMissAssign'] as String? ?? 'sameAssignee',
    );
  }

  static Map<String, dynamic> toFirestore(
      TaskInput input, String homeId, String createdByUid, DateTime nextDueAt) {
    return {
      'homeId': homeId,
      'title': input.title.trim(),
      'description': input.description?.trim(),
      'visualKind': input.visualKind,
      'visualValue': input.visualValue,
      'status': 'active',
      'recurrenceType': _recurrenceTypeFromRule(input.recurrenceRule),
      'recurrenceRule': _ruleToMap(input.recurrenceRule),
      'assignmentMode': input.assignmentMode,
      'assignmentOrder': input.assignmentOrder,
      'currentAssigneeUid':
          input.assignmentOrder.isNotEmpty ? input.assignmentOrder.first : null,
      'nextDueAt': Timestamp.fromDate(nextDueAt),
      'difficultyWeight': input.difficultyWeight,
      'completedCount90d': 0,
      'createdByUid': createdByUid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'onMissAssign': input.onMissAssign,
    };
  }

  /// Payload JSON-safe para la callable `createTask` (Hallazgo #14: el alta de
  /// tareas pasó a server-side para que el límite Free no sea eludible).
  ///
  /// A diferencia de [toFirestore], NO incluye `FieldValue`/`Timestamp` (no son
  /// serializables a JSON de un callable): los timestamps de auditoría los pone
  /// el servidor y `nextDueAt` viaja como ISO 8601 (lo calcula el cliente, igual
  /// que antes). `status`, `completedCount90d`, `createdByUid` y
  /// `currentAssigneeUid` los deriva el backend.
  static Map<String, dynamic> toCallablePayload(
      TaskInput input, DateTime nextDueAt) {
    return {
      'title': input.title.trim(),
      'description': input.description?.trim(),
      'visualKind': input.visualKind,
      'visualValue': input.visualValue,
      'recurrenceType': _recurrenceTypeFromRule(input.recurrenceRule),
      'recurrenceRule': _ruleToMap(input.recurrenceRule),
      'assignmentMode': input.assignmentMode,
      'assignmentOrder': input.assignmentOrder,
      'difficultyWeight': input.difficultyWeight,
      'onMissAssign': input.onMissAssign,
      'nextDueAt': nextDueAt.toUtc().toIso8601String(),
    };
  }

  /// Mapa de actualización al EDITAR una tarea existente.
  ///
  /// Hallazgo #11(b): editar una tarea (p. ej. su título) NO debe reiniciar la
  /// rotación. Por eso `currentAssigneeUid` solo se reescribe cuando el
  /// `assignmentOrder` cambia respecto al guardado ([previousOrder]); si el
  /// orden no cambia, la clave se OMITE del mapa para que el documento conserve
  /// el responsable actual de Firestore.
  ///
  /// Si el orden cambia, se preserva al responsable actual
  /// ([currentAssigneeUid]) cuando sigue presente en el nuevo orden; si ya no
  /// está (lo quitaron de la rotación), cae al primero del nuevo orden.
  static Map<String, dynamic> toUpdateMap(
    TaskInput input,
    DateTime nextDueAt, {
    required List<String> previousOrder,
    required String? currentAssigneeUid,
  }) {
    final map = <String, dynamic>{
      'title': input.title.trim(),
      'description': input.description?.trim(),
      'visualKind': input.visualKind,
      'visualValue': input.visualValue,
      'recurrenceType': _recurrenceTypeFromRule(input.recurrenceRule),
      'recurrenceRule': _ruleToMap(input.recurrenceRule),
      'assignmentMode': input.assignmentMode,
      'assignmentOrder': input.assignmentOrder,
      'nextDueAt': Timestamp.fromDate(nextDueAt),
      'difficultyWeight': input.difficultyWeight,
      'updatedAt': FieldValue.serverTimestamp(),
      'onMissAssign': input.onMissAssign,
    };

    if (!_sameOrder(input.assignmentOrder, previousOrder)) {
      map['currentAssigneeUid'] =
          _resolveAssigneeOnReorder(input.assignmentOrder, currentAssigneeUid);
    }

    return map;
  }

  /// Resuelve el responsable cuando el orden de rotación cambia: conserva al
  /// asignado actual si sigue en el orden; si no, el primero (o null si vacío).
  static String? _resolveAssigneeOnReorder(
      List<String> order, String? currentAssigneeUid) {
    if (order.isEmpty) return null;
    if (currentAssigneeUid != null && order.contains(currentAssigneeUid)) {
      return currentAssigneeUid;
    }
    return order.first;
  }

  static bool _sameOrder(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // ── serialización RecurrenceRule ────────────────────────────────────

  static String _recurrenceTypeFromRule(RecurrenceRule rule) => switch (rule) {
        OneTimeRule _ => 'oneTime',
        HourlyRule _ => 'hourly',
        DailyRule _ => 'daily',
        WeeklyRule _ => 'weekly',
        MonthlyFixedRule _ => 'monthly',
        MonthlyNthRule _ => 'monthly',
        YearlyFixedRule _ => 'yearly',
        YearlyNthRule _ => 'yearly',
      };

  static Map<String, dynamic> _ruleToMap(RecurrenceRule rule) =>
      switch (rule) {
        OneTimeRule r => {
            'type': 'oneTime',
            'kind': 'oneTime',
            'date': r.date,
            'time': r.time,
            'timezone': r.timezone,
          },
        HourlyRule r => {
            'type': 'hourly',
            'every': r.every,
            'startTime': r.startTime,
            'endTime': r.endTime,
            'timezone': r.timezone,
          },
        DailyRule r => {
            'type': 'daily',
            'every': r.every,
            'time': r.time,
            'timezone': r.timezone,
          },
        WeeklyRule r => {
            'type': 'weekly',
            'weekdays': r.weekdays,
            'time': r.time,
            'timezone': r.timezone,
          },
        MonthlyFixedRule r => {
            'type': 'monthlyFixed',
            'day': r.day,
            'time': r.time,
            'timezone': r.timezone,
          },
        MonthlyNthRule r => {
            'type': 'monthlyNth',
            'weekOfMonth': r.weekOfMonth,
            'weekday': r.weekday,
            'time': r.time,
            'timezone': r.timezone,
          },
        YearlyFixedRule r => {
            'type': 'yearlyFixed',
            'month': r.month,
            'day': r.day,
            'time': r.time,
            'timezone': r.timezone,
          },
        YearlyNthRule r => {
            'type': 'yearlyNth',
            'month': r.month,
            'weekOfMonth': r.weekOfMonth,
            'weekday': r.weekday,
            'time': r.time,
            'timezone': r.timezone,
          },
      };

  static RecurrenceRule _ruleFromMap(Map<String, dynamic> map) {
    // Compatibilidad: algunos documentos guardan el discriminante en "kind"
    // (spec 2026-04-21) y otros en "type".
    final type =
        (map['kind'] as String?) ?? (map['type'] as String?) ?? 'daily';
    return switch (type) {
      'oneTime' => RecurrenceRule.oneTime(
          date: map['date'] as String? ?? '1970-01-01',
          time: map['time'] as String? ?? '09:00',
          timezone: map['timezone'] as String? ?? 'UTC',
        ),
      'hourly' => RecurrenceRule.hourly(
          every: (map['every'] as int?) ?? 1,
          startTime: map['startTime'] as String? ?? '08:00',
          endTime: map['endTime'] as String?,
          timezone: map['timezone'] as String? ?? 'UTC',
        ),
      'daily' => RecurrenceRule.daily(
          every: (map['every'] as int?) ?? 1,
          time: map['time'] as String? ?? '09:00',
          timezone: map['timezone'] as String? ?? 'UTC',
        ),
      'weekly' => RecurrenceRule.weekly(
          weekdays: List<String>.from(map['weekdays'] as List? ?? ['MON']),
          time: map['time'] as String? ?? '09:00',
          timezone: map['timezone'] as String? ?? 'UTC',
        ),
      'monthlyFixed' => RecurrenceRule.monthlyFixed(
          day: (map['day'] as int?) ?? 1,
          time: map['time'] as String? ?? '09:00',
          timezone: map['timezone'] as String? ?? 'UTC',
        ),
      'monthlyNth' => RecurrenceRule.monthlyNth(
          weekOfMonth: (map['weekOfMonth'] as int?) ?? 1,
          weekday: map['weekday'] as String? ?? 'MON',
          time: map['time'] as String? ?? '09:00',
          timezone: map['timezone'] as String? ?? 'UTC',
        ),
      'yearlyFixed' => RecurrenceRule.yearlyFixed(
          month: (map['month'] as int?) ?? 1,
          day: (map['day'] as int?) ?? 1,
          time: map['time'] as String? ?? '09:00',
          timezone: map['timezone'] as String? ?? 'UTC',
        ),
      'yearlyNth' => RecurrenceRule.yearlyNth(
          month: (map['month'] as int?) ?? 1,
          weekOfMonth: (map['weekOfMonth'] as int?) ?? 1,
          weekday: map['weekday'] as String? ?? 'MON',
          time: map['time'] as String? ?? '09:00',
          timezone: map['timezone'] as String? ?? 'UTC',
        ),
      _ => RecurrenceRule.daily(
          every: 1,
          time: '09:00',
          timezone: map['timezone'] as String? ?? 'UTC',
        ),
    };
  }
}
