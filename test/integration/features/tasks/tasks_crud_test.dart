import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:toka/features/tasks/data/tasks_repository_impl.dart';
import 'package:toka/features/tasks/domain/recurrence_rule.dart';
import 'package:toka/features/tasks/domain/task.dart';
import 'package:toka/features/tasks/domain/task_status.dart';

// NOTA (Hallazgo #14): el ALTA de tareas (`createTask`) dejó de ser una
// escritura directa del cliente y pasó a una callable transaccional server-side
// (límite Free no eludible). Su comportamiento se prueba en
// functions/test/integration/create_task.test.ts contra el emulador real. Aquí
// solo se prueban las operaciones que SIGUEN siendo escrituras directas del
// cliente (update/freeze/unfreeze/delete/reorder y los streams de lectura),
// sembrando las tareas directamente en el fake Firestore.

const _homeId = 'home1';
const _uid = 'user1';

class _MockFunctions extends Mock implements FirebaseFunctions {}

TaskInput _dailyInput({String title = 'Fregar'}) => TaskInput(
      title: title,
      visualKind: 'emoji',
      visualValue: '🍽️',
      recurrenceRule: const RecurrenceRule.daily(
          every: 1, time: '20:00', timezone: 'Europe/Madrid'),
      assignmentMode: 'basicRotation',
      assignmentOrder: [_uid],
    );

Future<String> _seedTask(
  FakeFirebaseFirestore db, {
  String title = 'Fregar',
  List<String> assignmentOrder = const [_uid],
  String status = 'active',
}) async {
  final ref =
      db.collection('homes').doc(_homeId).collection('tasks').doc();
  await ref.set({
    'homeId': _homeId,
    'title': title,
    'description': null,
    'visualKind': 'emoji',
    'visualValue': '🍽️',
    'status': status,
    'recurrenceType': 'daily',
    'recurrenceRule': {
      'type': 'daily',
      'every': 1,
      'time': '20:00',
      'timezone': 'Europe/Madrid',
    },
    'assignmentMode': 'basicRotation',
    'assignmentOrder': assignmentOrder,
    'currentAssigneeUid':
        assignmentOrder.isNotEmpty ? assignmentOrder.first : null,
    'nextDueAt': Timestamp.fromDate(DateTime(2026, 4, 10, 20)),
    'difficultyWeight': 1.0,
    'completedCount90d': 0,
    'createdByUid': _uid,
    'createdAt': Timestamp.fromDate(DateTime(2026)),
    'updatedAt': Timestamp.fromDate(DateTime(2026)),
    'onMissAssign': 'sameAssignee',
  });
  return ref.id;
}

void main() {
  setUpAll(() => tz_data.initializeTimeZones());

  late FakeFirebaseFirestore fakeDb;
  late TasksRepositoryImpl repo;

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    repo = TasksRepositoryImpl(
      firestore: fakeDb,
      // Las pruebas de esta suite no ejercitan el alta (server-side), así que
      // el cliente de Functions nunca se invoca.
      functions: _MockFunctions(),
    );
  });

  test('watchHomeTasks emite la tarea sembrada', () async {
    await _seedTask(fakeDb);
    final tasks = await repo.watchHomeTasks(_homeId).first;
    expect(tasks.length, 1);
    expect(tasks.first.title, 'Fregar');
    expect(tasks.first.status, TaskStatus.active);
  });

  test('updateTask → título actualizado', () async {
    final id = await _seedTask(fakeDb);
    await repo.updateTask(_homeId, id, _dailyInput(title: 'Planchar'));
    final task = await repo.fetchTask(_homeId, id);
    expect(task.title, 'Planchar');
  });

  test('freezeTask → status frozen', () async {
    final id = await _seedTask(fakeDb);
    await repo.freezeTask(_homeId, id);
    final task = await repo.fetchTask(_homeId, id);
    expect(task.status, TaskStatus.frozen);
  });

  test('unfreezeTask → status active', () async {
    final id = await _seedTask(fakeDb);
    await repo.freezeTask(_homeId, id);
    await repo.unfreezeTask(_homeId, id);
    final task = await repo.fetchTask(_homeId, id);
    expect(task.status, TaskStatus.active);
  });

  test(
      'deleteTask → soft delete (status=deleted, deletedAt registrado), '
      'no aparece en watch', () async {
    final id = await _seedTask(fakeDb);
    await repo.deleteTask(_homeId, id, _uid);
    final task = await repo.fetchTask(_homeId, id);
    expect(task.status, TaskStatus.deleted);
    final raw = await fakeDb
        .collection('homes')
        .doc(_homeId)
        .collection('tasks')
        .doc(id)
        .get();
    expect(raw.data()!['deletedAt'], isNotNull);
    final tasks = await repo.watchHomeTasks(_homeId).first;
    expect(tasks.where((t) => t.id == id), isEmpty);
  });

  test('reorderAssignees → actualiza orden y currentAssigneeUid', () async {
    final id = await _seedTask(fakeDb, assignmentOrder: ['u1', 'u2']);
    await repo.reorderAssignees(_homeId, id, ['u2', 'u1']);
    final task = await repo.fetchTask(_homeId, id);
    expect(task.assignmentOrder, ['u2', 'u1']);
    expect(task.currentAssigneeUid, 'u2');
  });

  test('watchHomeTasks no incluye tareas deleted', () async {
    final id1 = await _seedTask(fakeDb, title: 'A');
    final id2 = await _seedTask(fakeDb, title: 'B');
    await repo.deleteTask(_homeId, id2, _uid);
    final tasks = await repo.watchHomeTasks(_homeId).first;
    expect(tasks.length, 1);
    expect(tasks.first.id, id1);
  });
}
