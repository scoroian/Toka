// test/integration/features/tasks/pass_turn_test.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// Simula lo que haría la Cloud Function passTaskTurn.
Future<void> simulatePass(
  FakeFirebaseFirestore db,
  String homeId,
  String taskId,
  String uid, {
  String? reason,
}) async {
  final taskRef =
      db.collection('homes').doc(homeId).collection('tasks').doc(taskId);
  final taskSnap = await taskRef.get();
  final task = taskSnap.data()!;

  final membersSnap =
      await db.collection('homes').doc(homeId).collection('members').get();
  final frozenUids = membersSnap.docs
      .where((d) => d.data()['status'] == 'frozen')
      .map((d) => d.id)
      .toSet();

  final assignmentOrder =
      List<String>.from(task['assignmentOrder'] as List? ?? [uid]);

  // Encontrar siguiente elegible (circular, excluyendo al actual y congelados)
  String toUid = uid;
  final currentIdx = assignmentOrder.indexOf(uid);
  for (var i = 1; i < assignmentOrder.length; i++) {
    final candidate = assignmentOrder[(currentIdx + i) % assignmentOrder.length];
    if (!frozenUids.contains(candidate)) {
      toUid = candidate;
      break;
    }
  }
  final noCandidate = toUid == uid;

  final eventRef =
      db.collection('homes').doc(homeId).collection('taskEvents').doc();
  await eventRef.set({
    'eventType': 'passed',
    'taskId': taskId,
    'actorUid': uid,
    'toUid': toUid,
    'reason': reason,
    'noCandidate': noCandidate,
    'createdAt': Timestamp.fromDate(DateTime.now()),
    'penaltyApplied': true,
  });

  await taskRef.update({'currentAssigneeUid': toUid});

  final memberRef =
      db.collection('homes').doc(homeId).collection('members').doc(uid);
  final memberSnap = await memberRef.get();
  final member = memberSnap.data()!;
  final completed = (member['completedCount'] as int?) ?? 0;
  final passed = ((member['passedCount'] as int?) ?? 0) + 1;
  final newCompliance = completed / (completed + passed);

  await memberRef.update({
    'passedCount': FieldValue.increment(1),
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
    });

    for (final uid in ['uid-A', 'uid-B', 'uid-C']) {
      await db
          .collection('homes')
          .doc(homeId)
          .collection('members')
          .doc(uid)
          .set({
        'name': uid,
        'completedCount': 4,
        'passedCount': 0,
        'complianceRate': 1.0,
        'status': 'active',
      });
    }
  });

  test('pasar turno crea evento passed en taskEvents', () async {
    await simulatePass(db, homeId, 'task1', 'uid-A', reason: 'Viaje');

    final events = await db
        .collection('homes')
        .doc(homeId)
        .collection('taskEvents')
        .where('eventType', isEqualTo: 'passed')
        .get();

    expect(events.docs.length, 1);
    expect(events.docs.first.data()['actorUid'], 'uid-A');
    expect(events.docs.first.data()['reason'], 'Viaje');
  });

  test('currentAssigneeUid cambia al siguiente elegible', () async {
    await simulatePass(db, homeId, 'task1', 'uid-A');

    final task = await db
        .collection('homes')
        .doc(homeId)
        .collection('tasks')
        .doc('task1')
        .get();

    expect(task.data()!['currentAssigneeUid'], 'uid-B');
  });

  test('passedCount del miembro se incrementa', () async {
    await simulatePass(db, homeId, 'task1', 'uid-A');

    final member = await db
        .collection('homes')
        .doc(homeId)
        .collection('members')
        .doc('uid-A')
        .get();

    expect(member.data()!['passedCount'], 1);
  });

  test('complianceRate se reduce tras pasar', () async {
    await simulatePass(db, homeId, 'task1', 'uid-A');

    final member = await db
        .collection('homes')
        .doc(homeId)
        .collection('members')
        .doc('uid-A')
        .get();

    // completedCount=4, passedCount=1 → 4/5 = 0.8
    expect(member.data()!['complianceRate'], closeTo(0.8, 0.001));
  });

  test('miembro congelado se salta en la rotación', () async {
    await db
        .collection('homes')
        .doc(homeId)
        .collection('members')
        .doc('uid-B')
        .update({'status': 'frozen'});

    await simulatePass(db, homeId, 'task1', 'uid-A');

    final task = await db
        .collection('homes')
        .doc(homeId)
        .collection('tasks')
        .doc('task1')
        .get();

    expect(task.data()!['currentAssigneeUid'], 'uid-C');
  });

  test('sin candidatos elegibles: se asigna a sí mismo', () async {
    for (final uid in ['uid-B', 'uid-C']) {
      await db
          .collection('homes')
          .doc(homeId)
          .collection('members')
          .doc(uid)
          .update({'status': 'frozen'});
    }

    await simulatePass(db, homeId, 'task1', 'uid-A');

    final task = await db
        .collection('homes')
        .doc(homeId)
        .collection('tasks')
        .doc('task1')
        .get();

    expect(task.data()!['currentAssigneeUid'], 'uid-A');
  });
}
