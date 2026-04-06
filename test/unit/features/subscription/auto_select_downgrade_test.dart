// test/unit/features/subscription/auto_select_downgrade_test.dart
import 'package:flutter_test/flutter_test.dart';

typedef MemberData = ({
  String uid,
  String status,
  int completions60d,
  DateTime? lastCompletedAt,
  DateTime joinedAt,
});

typedef TaskData = ({
  String id,
  String status,
  int completedCount90d,
  DateTime nextDueAt,
});

typedef Selection = ({List<String> memberIds, List<String> taskIds});

Selection autoSelectForDowngrade(
  List<MemberData> members,
  List<TaskData> tasks,
  String ownerId,
) {
  final sorted = members
      .where((m) => m.uid != ownerId && m.status == 'active')
      .toList()
    ..sort((a, b) {
      if (b.completions60d != a.completions60d) return b.completions60d - a.completions60d;
      if (b.lastCompletedAt != null && a.lastCompletedAt != null) {
        return b.lastCompletedAt!.compareTo(a.lastCompletedAt!);
      }
      if (b.lastCompletedAt != null && a.lastCompletedAt == null) return 1;
      if (b.lastCompletedAt == null && a.lastCompletedAt != null) return -1;
      return a.joinedAt.compareTo(b.joinedAt);
    });

  final memberIds = [ownerId, ...sorted.take(2).map((m) => m.uid)];

  final sortedTasks = tasks
      .where((t) => t.status == 'active')
      .toList()
    ..sort((a, b) {
      if (b.completedCount90d != a.completedCount90d) return b.completedCount90d - a.completedCount90d;
      return a.nextDueAt.compareTo(b.nextDueAt);
    });

  final taskIds = sortedTasks.take(4).map((t) => t.id).toList();

  return (memberIds: memberIds, taskIds: taskIds);
}

void main() {
  const ownerId = 'owner';
  final baseDate = DateTime(2026, 1, 1);

  group('autoSelectForDowngrade – miembros', () {
    test('selecciona owner + 2 más participativos de 5', () {
      final members = <MemberData>[
        (uid: ownerId, status: 'active', completions60d: 10, lastCompletedAt: null, joinedAt: baseDate),
        (uid: 'm1', status: 'active', completions60d: 8, lastCompletedAt: baseDate.add(const Duration(days: 4)), joinedAt: baseDate),
        (uid: 'm2', status: 'active', completions60d: 5, lastCompletedAt: baseDate.add(const Duration(days: 3)), joinedAt: baseDate),
        (uid: 'm3', status: 'active', completions60d: 3, lastCompletedAt: null, joinedAt: baseDate),
        (uid: 'm4', status: 'active', completions60d: 1, lastCompletedAt: null, joinedAt: baseDate),
      ];
      final result = autoSelectForDowngrade(members, [], ownerId);
      expect(result.memberIds, containsAll([ownerId, 'm1', 'm2']));
      expect(result.memberIds, hasLength(3));
    });

    test('desempata por lastCompletedAt más reciente', () {
      final members = <MemberData>[
        (uid: ownerId, status: 'active', completions60d: 10, lastCompletedAt: null, joinedAt: baseDate),
        (uid: 'm1', status: 'active', completions60d: 5, lastCompletedAt: DateTime(2026, 1, 5), joinedAt: baseDate),
        (uid: 'm2', status: 'active', completions60d: 5, lastCompletedAt: DateTime(2026, 1, 10), joinedAt: baseDate),
        (uid: 'm3', status: 'active', completions60d: 5, lastCompletedAt: DateTime(2026, 1, 3), joinedAt: baseDate),
      ];
      final result = autoSelectForDowngrade(members, [], ownerId);
      expect(result.memberIds, containsAll([ownerId, 'm2', 'm1']));
    });

    test('con empate en lastCompletedAt null, gana el más antiguo en joinedAt', () {
      final members = <MemberData>[
        (uid: ownerId, status: 'active', completions60d: 10, lastCompletedAt: null, joinedAt: baseDate),
        (uid: 'm1', status: 'active', completions60d: 5, lastCompletedAt: null, joinedAt: DateTime(2026, 1, 1)),
        (uid: 'm2', status: 'active', completions60d: 5, lastCompletedAt: null, joinedAt: DateTime(2026, 2, 1)),
        (uid: 'm3', status: 'active', completions60d: 5, lastCompletedAt: null, joinedAt: DateTime(2026, 3, 1)),
      ];
      final result = autoSelectForDowngrade(members, [], ownerId);
      expect(result.memberIds, containsAll([ownerId, 'm1', 'm2']));
    });
  });

  group('autoSelectForDowngrade – tareas', () {
    test('selecciona las 4 con más completedCount90d de 6', () {
      final tasks = <TaskData>[
        (id: 't1', status: 'active', completedCount90d: 20, nextDueAt: baseDate),
        (id: 't2', status: 'active', completedCount90d: 15, nextDueAt: baseDate),
        (id: 't3', status: 'active', completedCount90d: 10, nextDueAt: baseDate),
        (id: 't4', status: 'active', completedCount90d: 8, nextDueAt: baseDate),
        (id: 't5', status: 'active', completedCount90d: 5, nextDueAt: baseDate),
        (id: 't6', status: 'active', completedCount90d: 2, nextDueAt: baseDate),
      ];
      final result = autoSelectForDowngrade([], tasks, ownerId);
      expect(result.taskIds, equals(['t1', 't2', 't3', 't4']));
    });
  });
}
