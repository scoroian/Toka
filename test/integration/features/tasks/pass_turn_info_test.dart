// Verifica el cálculo cliente de la info del diálogo "Pasar turno"
// (fetchPassTurnInfo): siguiente responsable + penalización de cumplimiento.
// Regresión del bug QA 2026-06-16: el cliente siempre mostraba "sin candidato"
// y nunca el siguiente responsable ni la penalización.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/application/today_view_model.dart';

void main() {
  late FakeFirebaseFirestore db;
  const homeId = 'home1';
  const taskId = 'task1';

  Future<void> seedMember(
    String uid, {
    String? nickname,
    int? tasksCompleted,
    int? completedCount,
    int passedCount = 0,
    String status = 'active',
    Map<String, dynamic>? vacation,
  }) async {
    await db
        .collection('homes')
        .doc(homeId)
        .collection('members')
        .doc(uid)
        .set({
      'nickname': nickname ?? uid,
      if (tasksCompleted != null) 'tasksCompleted': tasksCompleted,
      if (completedCount != null) 'completedCount': completedCount,
      'passedCount': passedCount,
      'status': status,
      if (vacation != null) 'vacation': vacation,
    });
  }

  Future<void> seedTask(List<String> order, String currentUid) async {
    await db
        .collection('homes')
        .doc(homeId)
        .collection('tasks')
        .doc(taskId)
        .set({
      'title': 'Barrer',
      'status': 'active',
      'currentAssigneeUid': currentUid,
      'assignmentOrder': order,
      'nextDueAt': Timestamp.fromDate(DateTime(2026, 6, 16, 10)),
    });
  }

  setUp(() {
    db = FakeFirebaseFirestore();
  });

  test('2 miembros [A,B], turno de A → siguiente responsable = nombre de B',
      () async {
    await seedTask(['A', 'B'], 'A');
    await seedMember('A', nickname: 'Ana', tasksCompleted: 9, passedCount: 0);
    await seedMember('B', nickname: 'Bob');

    final info = await fetchPassTurnInfo(db, homeId, taskId, 'A');

    expect(info.nextAssigneeName, 'Bob');
    // before = 9/9 = 1.0 ; after = 9/10 = 0.9
    expect(info.complianceBefore, closeTo(1.0, 0.001));
    expect(info.estimatedAfter, closeTo(0.9, 0.001));
  });

  test('un solo miembro → nextAssigneeName null (sin candidato)', () async {
    await seedTask(['A'], 'A');
    await seedMember('A', nickname: 'Ana', tasksCompleted: 3);

    final info = await fetchPassTurnInfo(db, homeId, taskId, 'A');

    expect(info.nextAssigneeName, isNull);
  });

  test('miembro congelado se salta → siguiente elegible', () async {
    await seedTask(['A', 'B', 'C'], 'A');
    await seedMember('A', nickname: 'Ana', tasksCompleted: 4);
    await seedMember('B', nickname: 'Bob', status: 'frozen');
    await seedMember('C', nickname: 'Carlos');

    final info = await fetchPassTurnInfo(db, homeId, taskId, 'A');

    expect(info.nextAssigneeName, 'Carlos');
  });

  test('miembro con vacación activa se salta como el backend', () async {
    await seedTask(['A', 'B', 'C'], 'A');
    await seedMember('A', nickname: 'Ana', tasksCompleted: 4);
    await seedMember('B', nickname: 'Bob', vacation: {'isActive': true});
    await seedMember('C', nickname: 'Carlos');

    final info = await fetchPassTurnInfo(db, homeId, taskId, 'A');

    expect(info.nextAssigneeName, 'Carlos');
  });

  test('vacación FUTURA no salta (aún no empezó)', () async {
    await seedTask(['A', 'B', 'C'], 'A');
    await seedMember('A', nickname: 'Ana', tasksCompleted: 4);
    await seedMember('B', nickname: 'Bob', vacation: {
      'isActive': true,
      'startDate':
          Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
    });
    await seedMember('C', nickname: 'Carlos');

    final info = await fetchPassTurnInfo(db, homeId, taskId, 'A');

    // Bob no está de vacaciones aún → es el siguiente en la rotación.
    expect(info.nextAssigneeName, 'Bob');
  });

  test('todos los demás congelados → sin candidato', () async {
    await seedTask(['A', 'B'], 'A');
    await seedMember('A', nickname: 'Ana', tasksCompleted: 4);
    await seedMember('B', nickname: 'Bob', status: 'frozen');

    final info = await fetchPassTurnInfo(db, homeId, taskId, 'A');

    expect(info.nextAssigneeName, isNull);
  });

  test('usa tasksCompleted sobre el legacy completedCount', () async {
    await seedTask(['A', 'B'], 'A');
    // El backend ya migró: tasksCompleted=8, completedCount fue borrado.
    await seedMember('A', nickname: 'Ana', tasksCompleted: 8, passedCount: 2);
    await seedMember('B', nickname: 'Bob');

    final info = await fetchPassTurnInfo(db, homeId, taskId, 'A');

    // before = 8/10 = 0.8 ; after = 8/11 ≈ 0.727
    expect(info.complianceBefore, closeTo(0.8, 0.001));
    expect(info.estimatedAfter, closeTo(8 / 11, 0.001));
  });

  test('fallback a completedCount cuando no hay tasksCompleted', () async {
    await seedTask(['A', 'B'], 'A');
    await seedMember('A', nickname: 'Ana', completedCount: 5, passedCount: 0);
    await seedMember('B', nickname: 'Bob');

    final info = await fetchPassTurnInfo(db, homeId, taskId, 'A');

    // before = 5/5 = 1.0 ; after = 5/6 ≈ 0.833
    expect(info.complianceBefore, closeTo(1.0, 0.001));
    expect(info.estimatedAfter, closeTo(5 / 6, 0.001));
  });
}
