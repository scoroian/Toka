// test/integration/features/tasks/task_completion_test.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/core/utils/assignment_calculator.dart';

/// Simula lo que haría la Cloud Function applyTaskCompletion.
Future<void> simulateCompletion(
  FakeFirebaseFirestore db,
  String homeId,
  String taskId,
  String uid,
) async {
  final taskRef =
      db.collection('homes').doc(homeId).collection('tasks').doc(taskId);
  final taskSnap = await taskRef.get();
  final task = taskSnap.data()!;

  final assignmentOrder =
      List<String>.from(task['assignmentOrder'] as List? ?? [uid]);
  final nextUid =
      AssignmentCalculator.getNextAssignee(assignmentOrder, uid, []) ?? uid;

  final currentDue = (task['nextDueAt'] as Timestamp).toDate();
  final nextDue = currentDue.add(const Duration(days: 1));

  final eventRef =
      db.collection('homes').doc(homeId).collection('taskEvents').doc();
  await eventRef.set({
    'eventType': 'completed',
    'taskId': taskId,
    'taskTitleSnapshot': task['title'],
    'taskVisualSnapshot': {
      'kind': task['visualKind'],
      'value': task['visualValue']
    },
    'actorUid': uid,
    'performerUid': uid,
    'completedAt': Timestamp.fromDate(DateTime.now()),
    'createdAt': Timestamp.fromDate(DateTime.now()),
    'penaltyApplied': false,
  });

  await taskRef.update({
    'currentAssigneeUid': nextUid,
    'nextDueAt': Timestamp.fromDate(nextDue),
    'completedCount90d': FieldValue.increment(1),
    'updatedAt': Timestamp.fromDate(DateTime.now()),
  });

  final memberRef =
      db.collection('homes').doc(homeId).collection('members').doc(uid);
  final memberSnap = await memberRef.get();
  final member = memberSnap.data()!;
  final newCompleted = ((member['completedCount'] as int?) ?? 0) + 1;
  final newPassed = (member['passedCount'] as int?) ?? 0;
  final newCompliance = newCompleted / (newCompleted + newPassed);

  await memberRef.update({
    'completedCount': FieldValue.increment(1),
    'complianceRate': newCompliance,
  });
}

void main() {
  late FakeFirebaseFirestore db;
  const homeId = 'home1';

  setUp(() async {
    db = FakeFirebaseFirestore();

    await db
        .collection('homes')
        .doc(homeId)
        .collection('tasks')
        .doc('task1')
        .set({
      'title': 'Barrer',
      'visualKind': 'emoji',
      'visualValue': '🧹',
      'recurrenceType': 'daily',
      'status': 'active',
      'currentAssigneeUid': 'uid-A',
      'assignmentOrder': ['uid-A', 'uid-B', 'uid-C'],
      'nextDueAt': Timestamp.fromDate(DateTime(2026, 4, 6, 10)),
      'completedCount90d': 0,
    });

    for (final uid in ['uid-A', 'uid-B', 'uid-C']) {
      await db
          .collection('homes')
          .doc(homeId)
          .collection('members')
          .doc(uid)
          .set({
        'name': uid,
        'completedCount': 3,
        'passedCount': 1,
        'complianceRate': 0.75,
        'status': 'active',
      });
    }
  });

  test('completar tarea crea evento completed en taskEvents', () async {
    await simulateCompletion(db, homeId, 'task1', 'uid-A');

    final events = await db
        .collection('homes')
        .doc(homeId)
        .collection('taskEvents')
        .where('eventType', isEqualTo: 'completed')
        .get();

    expect(events.docs.length, 1);
    expect(events.docs.first.data()['taskId'], 'task1');
    expect(events.docs.first.data()['actorUid'], 'uid-A');
  });

  test('nextDueAt de la tarea avanza 1 día', () async {
    await simulateCompletion(db, homeId, 'task1', 'uid-A');

    final task = await db
        .collection('homes')
        .doc(homeId)
        .collection('tasks')
        .doc('task1')
        .get();

    final nextDue = (task.data()!['nextDueAt'] as Timestamp).toDate();
    expect(nextDue, DateTime(2026, 4, 7, 10));
  });

  test('currentAssigneeUid rota al siguiente miembro', () async {
    await simulateCompletion(db, homeId, 'task1', 'uid-A');

    final task = await db
        .collection('homes')
        .doc(homeId)
        .collection('tasks')
        .doc('task1')
        .get();

    expect(task.data()!['currentAssigneeUid'], 'uid-B');
  });

  test('completedCount del miembro se incrementa', () async {
    await simulateCompletion(db, homeId, 'task1', 'uid-A');

    final member = await db
        .collection('homes')
        .doc(homeId)
        .collection('members')
        .doc('uid-A')
        .get();

    expect(member.data()!['completedCount'], 4);
  });

  test('complianceRate del miembro se recalcula', () async {
    await simulateCompletion(db, homeId, 'task1', 'uid-A');

    final member = await db
        .collection('homes')
        .doc(homeId)
        .collection('members')
        .doc('uid-A')
        .get();

    // completedCount=4, passedCount=1 → 4/5 = 0.8
    expect(member.data()!['complianceRate'], closeTo(0.8, 0.001));
  });

  test('rotación circular: C completa → A es el nuevo responsable', () async {
    // Forzar currentAssigneeUid = uid-C
    await db
        .collection('homes')
        .doc(homeId)
        .collection('tasks')
        .doc('task1')
        .update({'currentAssigneeUid': 'uid-C'});

    await simulateCompletion(db, homeId, 'task1', 'uid-C');

    final task = await db
        .collection('homes')
        .doc(homeId)
        .collection('tasks')
        .doc('task1')
        .get();

    expect(task.data()!['currentAssigneeUid'], 'uid-A');
  });
}
