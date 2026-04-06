// test/integration/features/subscription/open_rescue_window_test.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> simulateOpenRescueWindow(
  FakeFirebaseFirestore db,
  DateTime now,
) async {
  final threeDaysFromNow = now.add(const Duration(days: 3));

  final snapshot = await db.collection('homes')
      .where('premiumStatus', isEqualTo: 'cancelled_pending_end')
      .get();

  for (final doc in snapshot.docs) {
    final data = doc.data();
    final endsAt = (data['premiumEndsAt'] as Timestamp?)?.toDate();
    if (endsAt == null || endsAt.isAfter(threeDaysFromNow)) continue;
    if (data['rescueFlags']?['isInRescue'] == true) continue;

    final daysLeft = endsAt.difference(now).inDays.clamp(0, 3);
    await doc.reference.update({'premiumStatus': 'rescue'});
    await db.collection('homes').doc(doc.id).collection('views').doc('dashboard').set({
      'rescueFlags': {'isInRescue': true, 'daysLeft': daysLeft},
    }, SetOptions(merge: true));
  }
}

void main() {
  late FakeFirebaseFirestore db;
  const homeId = 'home1';

  setUp(() async {
    db = FakeFirebaseFirestore();
  });

  test('hogar a 2 días → premiumStatus cambia a rescue', () async {
    final now = DateTime(2026, 4, 6);
    final endsAt = now.add(const Duration(days: 2));

    await db.collection('homes').doc(homeId).set({
      'premiumStatus': 'cancelled_pending_end',
      'premiumEndsAt': Timestamp.fromDate(endsAt),
      'rescueFlags': {'isInRescue': false},
    });

    await simulateOpenRescueWindow(db, now);

    final homeSnap = await db.collection('homes').doc(homeId).get();
    expect(homeSnap.data()!['premiumStatus'], 'rescue');

    final dashSnap = await db.collection('homes').doc(homeId).collection('views').doc('dashboard').get();
    expect(dashSnap.data()!['rescueFlags']['isInRescue'], true);
    expect(dashSnap.data()!['rescueFlags']['daysLeft'], 2);
  });

  test('hogar a 5 días → NO cambia a rescue', () async {
    final now = DateTime(2026, 4, 6);
    final endsAt = now.add(const Duration(days: 5));

    await db.collection('homes').doc(homeId).set({
      'premiumStatus': 'cancelled_pending_end',
      'premiumEndsAt': Timestamp.fromDate(endsAt),
      'rescueFlags': {'isInRescue': false},
    });

    await simulateOpenRescueWindow(db, now);

    final homeSnap = await db.collection('homes').doc(homeId).get();
    expect(homeSnap.data()!['premiumStatus'], 'cancelled_pending_end');
  });

  test('hogar ya en rescue → no se toca', () async {
    final now = DateTime(2026, 4, 6);
    final endsAt = now.add(const Duration(days: 1));

    await db.collection('homes').doc(homeId).set({
      'premiumStatus': 'rescue',
      'premiumEndsAt': Timestamp.fromDate(endsAt),
      'rescueFlags': {'isInRescue': true, 'daysLeft': 1},
    });

    await simulateOpenRescueWindow(db, now);

    final homeSnap = await db.collection('homes').doc(homeId).get();
    expect(homeSnap.data()!['premiumStatus'], 'rescue');
  });
}
