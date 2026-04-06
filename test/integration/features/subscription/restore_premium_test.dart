// test/integration/features/subscription/restore_premium_test.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> simulateRestorePremium(
  FakeFirebaseFirestore db,
  String homeId,
) async {
  final homeSnap = await db.collection('homes').doc(homeId).get();
  final home = homeSnap.data()!;
  final premiumStatus = home['premiumStatus'] as String;

  if (premiumStatus == 'purged') throw Exception('restore_window_expired');
  if (premiumStatus != 'restorable') throw Exception('not_restorable');

  final frozenMembersSnap = await db.collection('homes').doc(homeId).collection('members')
      .where('status', isEqualTo: 'frozen').get();
  final frozenTasksSnap = await db.collection('homes').doc(homeId).collection('tasks')
      .where('status', isEqualTo: 'frozen').get();

  for (final m in frozenMembersSnap.docs) {
    await m.reference.update({'status': 'active'});
  }
  for (final t in frozenTasksSnap.docs) {
    await t.reference.update({'status': 'active'});
  }

  await db.collection('homes').doc(homeId).update({
    'premiumStatus': 'active',
    'restoreUntil': null,
    'limits.maxMembers': 10,
  });
}

void main() {
  late FakeFirebaseFirestore db;
  const homeId = 'home1';

  setUp(() async {
    db = FakeFirebaseFirestore();
    await db.collection('homes').doc(homeId).set({
      'ownerUid': 'owner',
      'premiumStatus': 'restorable',
      'restoreUntil': Timestamp.fromDate(DateTime.now().add(const Duration(days: 20))),
      'limits': {'maxMembers': 3},
    });

    await db.collection('homes').doc(homeId).collection('members').doc('m1').set({'status': 'frozen'});
    await db.collection('homes').doc(homeId).collection('members').doc('m2').set({'status': 'frozen'});
    await db.collection('homes').doc(homeId).collection('members').doc('owner').set({'status': 'active'});

    await db.collection('homes').doc(homeId).collection('tasks').doc('t1').set({'status': 'frozen'});
    await db.collection('homes').doc(homeId).collection('tasks').doc('t2').set({'status': 'active'});
  });

  test('restaurar dentro de 30 días → todos los extras descongelados', () async {
    await simulateRestorePremium(db, homeId);

    final homeSnap = await db.collection('homes').doc(homeId).get();
    expect(homeSnap.data()!['premiumStatus'], 'active');

    final m1 = await db.collection('homes').doc(homeId).collection('members').doc('m1').get();
    expect(m1.data()!['status'], 'active');

    final t1 = await db.collection('homes').doc(homeId).collection('tasks').doc('t1').get();
    expect(t1.data()!['status'], 'active');
  });

  test('restaurar con premiumStatus = purged → lanza error', () async {
    await db.collection('homes').doc(homeId).update({'premiumStatus': 'purged'});

    expect(
      () => simulateRestorePremium(db, homeId),
      throwsA(predicate((e) => e.toString().contains('restore_window_expired'))),
    );
  });
}
