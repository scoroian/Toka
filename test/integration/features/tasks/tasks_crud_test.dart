import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:toka/features/tasks/data/tasks_repository_impl.dart';
import 'package:toka/features/tasks/domain/recurrence_rule.dart';
import 'package:toka/features/tasks/domain/task.dart';
import 'package:toka/features/tasks/domain/task_status.dart';

const _homeId = 'home1';
const _uid = 'user1';

TaskInput _dailyInput({String title = 'Fregar'}) => TaskInput(
      title: title,
      visualKind: 'emoji',
      visualValue: '🍽️',
      recurrenceRule: const RecurrenceRule.daily(
          every: 1, time: '20:00', timezone: 'Europe/Madrid'),
      assignmentMode: 'basicRotation',
      assignmentOrder: [_uid],
    );

void main() {
  setUpAll(() => tz_data.initializeTimeZones());

  late FakeFirebaseFirestore fakeDb;
  late TasksRepositoryImpl repo;

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    repo = TasksRepositoryImpl(firestore: fakeDb);
  });

  test('createTask → documento creado con status active', () async {
    final id = await repo.createTask(_homeId, _dailyInput(), _uid);
    final doc = await fakeDb
        .collection('homes')
        .doc(_homeId)
        .collection('tasks')
        .doc(id)
        .get();
    expect(doc.exists, isTrue);
    expect(doc.data()!['status'], 'active');
    expect(doc.data()!['title'], 'Fregar');
    expect(doc.data()!['currentAssigneeUid'], _uid);
  });

  test('watchHomeTasks emite la tarea creada', () async {
    await repo.createTask(_homeId, _dailyInput(), _uid);
    final tasks = await repo.watchHomeTasks(_homeId).first;
    expect(tasks.length, 1);
    expect(tasks.first.title, 'Fregar');
    expect(tasks.first.status, TaskStatus.active);
  });

  test('updateTask → título actualizado', () async {
    final id = await repo.createTask(_homeId, _dailyInput(), _uid);
    await repo.updateTask(_homeId, id, _dailyInput(title: 'Planchar'));
    final task = await repo.fetchTask(_homeId, id);
    expect(task.title, 'Planchar');
  });

  test('freezeTask → status frozen', () async {
    final id = await repo.createTask(_homeId, _dailyInput(), _uid);
    await repo.freezeTask(_homeId, id);
    final task = await repo.fetchTask(_homeId, id);
    expect(task.status, TaskStatus.frozen);
  });

  test('unfreezeTask → status active', () async {
    final id = await repo.createTask(_homeId, _dailyInput(), _uid);
    await repo.freezeTask(_homeId, id);
    await repo.unfreezeTask(_homeId, id);
    final task = await repo.fetchTask(_homeId, id);
    expect(task.status, TaskStatus.active);
  });

  test('deleteTask → soft delete (status=deleted), no aparece en watch',
      () async {
    final id = await repo.createTask(_homeId, _dailyInput(), _uid);
    await repo.deleteTask(_homeId, id, _uid);
    // fetchTask todavía puede leerlo
    final task = await repo.fetchTask(_homeId, id);
    expect(task.status, TaskStatus.deleted);
    // pero watchHomeTasks no lo incluye
    final tasks = await repo.watchHomeTasks(_homeId).first;
    expect(tasks.where((t) => t.id == id), isEmpty);
  });

  test('reorderAssignees → actualiza orden y currentAssigneeUid', () async {
    final id = await repo.createTask(
        _homeId,
        _dailyInput().copyWith(assignmentOrder: ['u1', 'u2']),
        _uid);
    await repo.reorderAssignees(_homeId, id, ['u2', 'u1']);
    final task = await repo.fetchTask(_homeId, id);
    expect(task.assignmentOrder, ['u2', 'u1']);
    expect(task.currentAssigneeUid, 'u2');
  });

  test('watchHomeTasks no incluye tareas deleted', () async {
    final id1 = await repo.createTask(_homeId, _dailyInput(title: 'A'), _uid);
    final id2 = await repo.createTask(_homeId, _dailyInput(title: 'B'), _uid);
    await repo.deleteTask(_homeId, id2, _uid);
    final tasks = await repo.watchHomeTasks(_homeId).first;
    expect(tasks.length, 1);
    expect(tasks.first.id, id1);
  });
}
