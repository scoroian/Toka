// test/integration/features/subscription/apply_downgrade_test.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> simulateApplyDowngrade(
  FakeFirebaseFirestore db,
  String homeId,
) async {
  final homeSnap = await db.collection('homes').doc(homeId).get();
  final home = homeSnap.data()!;
  final ownerId = home['ownerUid'] as String;

  final manualPlanRef = db.collection('homes').doc(homeId).collection('downgrade').doc('current');
  final manualPlanSnap = await manualPlanRef.get();

  List<String> selectedMemberIds;
  List<String> selectedTaskIds;

  if (manualPlanSnap.exists) {
    selectedMemberIds = List<String>.from(manualPlanSnap.data()!['selectedMemberIds'] as List);
    selectedTaskIds = List<String>.from(manualPlanSnap.data()!['selectedTaskIds'] as List);
  } else {
    final membersSnap = await db.collection('homes').doc(homeId).collection('members').get();
    final activeMemberIds = membersSnap.docs
        .where((d) => d.data()['status'] == 'active' && d.id != ownerId)
        .map((d) => d.id)
        .take(2)
        .toList();
    selectedMemberIds = [ownerId, ...activeMemberIds];

    final tasksSnap = await db.collection('homes').doc(homeId).collection('tasks')
        .where('status', isEqualTo: 'active').get();
    selectedTaskIds = tasksSnap.docs.take(4).map((d) => d.id).toList();
  }

  final allMembersSnap = await db.collection('homes').doc(homeId).collection('members').get();
  for (final m in allMembersSnap.docs) {
    if (!selectedMemberIds.contains(m.id) && m.data()['status'] == 'active') {
      await m.reference.update({'status': 'frozen', 'frozenAt': Timestamp.fromDate(DateTime.now())});
    }
  }

  final allTasksSnap = await db.collection('homes').doc(homeId).collection('tasks')
      .where('status', isEqualTo: 'active').get();
  for (final t in allTasksSnap.docs) {
    if (!selectedTaskIds.contains(t.id)) {
      await t.reference.update({'status': 'frozen', 'frozenAt': Timestamp.fromDate(DateTime.now())});
    }
  }

  final restoreUntil = DateTime.now().add(const Duration(days: 30));
  await db.collection('homes').doc(homeId).update({
    'premiumStatus': 'restorable',
    'restoreUntil': Timestamp.fromDate(restoreUntil),
    'limits.maxMembers': 3,
  });
}

void main() {
  late FakeFirebaseFirestore db;
  const homeId = 'home1';

  setUp(() async {
    db = FakeFirebaseFirestore();

    await db.collection('homes').doc(homeId).set({
      'ownerUid': 'owner',
      'premiumStatus': 'rescue',
      'premiumEndsAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 5))),
    });

    for (var i = 1; i <= 5; i++) {
      await db.collection('homes').doc(homeId).collection('members').doc('m$i').set({
        'status': 'active',
        'completions60d': 10 - i,
        'nickname': 'Member $i',
      });
    }
    await db.collection('homes').doc(homeId).collection('members').doc('owner').set({
      'status': 'active',
      'completions60d': 20,
      'nickname': 'Owner',
    });

    for (var i = 1; i <= 6; i++) {
      await db.collection('homes').doc(homeId).collection('tasks').doc('t$i').set({
        'status': 'active',
        'title': 'Task $i',
        'completedCount90d': 10 - i,
        'nextDueAt': Timestamp.fromDate(DateTime.now().add(Duration(days: i))),
      });
    }
  });

  test('applyDowngrade sin plan manual → aplica selección automática y congela excedentes', () async {
    await simulateApplyDowngrade(db, homeId);

    final members = await db.collection('homes').doc(homeId).collection('members').get();
    final frozen = members.docs.where((d) => d.data()['status'] == 'frozen');
    final active = members.docs.where((d) => d.data()['status'] == 'active');

    expect(active.length, 3); // owner + 2
    expect(frozen.length, 3); // los 3 restantes

    final homeSnap = await db.collection('homes').doc(homeId).get();
    expect(homeSnap.data()!['premiumStatus'], 'restorable');
  });

  test('applyDowngrade con plan manual → congela los miembros seleccionados correctamente', () async {
    await db.collection('homes').doc(homeId).collection('downgrade').doc('current').set({
      'selectedMemberIds': ['owner', 'm1', 'm2'],
      'selectedTaskIds': ['t1', 't2', 't3', 't4'],
      'selectionMode': 'manual',
    });

    await simulateApplyDowngrade(db, homeId);

    final members = await db.collection('homes').doc(homeId).collection('members').get();
    final activeMembersIds = members.docs
        .where((d) => d.data()['status'] == 'active')
        .map((d) => d.id)
        .toList();

    expect(activeMembersIds, containsAll(['owner', 'm1', 'm2']));
    expect(activeMembersIds, hasLength(3));
  });
}
