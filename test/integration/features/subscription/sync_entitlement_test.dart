// test/integration/features/subscription/sync_entitlement_test.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> simulateSyncEntitlement(
  FakeFirebaseFirestore db,
  String homeId,
  String uid, {
  required String status,
  required String plan,
  required DateTime endsAt,
  required bool autoRenewEnabled,
  required String chargeId,
  required bool validForUnlock,
}) async {
  await db.collection('homes').doc(homeId).update({
    'premiumStatus': status,
    'premiumPlan': plan,
    'premiumEndsAt': Timestamp.fromDate(endsAt),
    'autoRenewEnabled': autoRenewEnabled,
    'currentPayerUid': uid,
    'updatedAt': Timestamp.fromDate(DateTime.now()),
  });

  final isPremium = ['active', 'cancelled_pending_end', 'rescue'].contains(status);
  await db.collection('homes').doc(homeId).collection('views').doc('dashboard').set({
    'premiumFlags': {
      'isPremium': isPremium,
      'showAds': !isPremium,
      'canUseSmartDistribution': isPremium,
      'canUseVacations': isPremium,
      'canUseReviews': isPremium,
    },
  }, SetOptions(merge: true));

  await db.collection('homes').doc(homeId)
      .collection('subscriptions').doc('history')
      .collection('charges').doc(chargeId)
      .set({'chargeId': chargeId, 'uid': uid, 'plan': plan, 'validForUnlock': validForUnlock});

  if (validForUnlock) {
    final userRef = db.collection('users').doc(uid);
    final userSnap = await userRef.get();
    final current = (userSnap.data()?['lifetimeUnlockedHomeSlots'] as int?) ?? 0;
    if (current < 3) {
      await userRef.update({'lifetimeUnlockedHomeSlots': current + 1});
    }
  }
}

void main() {
  late FakeFirebaseFirestore db;
  const homeId = 'home1';
  const uid = 'user1';

  setUp(() async {
    db = FakeFirebaseFirestore();
    await db.collection('homes').doc(homeId).set({
      'name': 'Test Home',
      'ownerUid': uid,
      'premiumStatus': 'free',
      'premiumPlan': null,
      'premiumEndsAt': null,
      'autoRenewEnabled': false,
      'currentPayerUid': null,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
    await db.collection('users').doc(uid).set({
      'lifetimeUnlockedHomeSlots': 0,
      'homeSlotCap': 2,
    });
  });

  test('compra válida → premiumStatus = active, premiumEndsAt seteado', () async {
    final endsAt = DateTime.now().add(const Duration(days: 31));
    await simulateSyncEntitlement(db, homeId, uid,
      status: 'active',
      plan: 'monthly',
      endsAt: endsAt,
      autoRenewEnabled: true,
      chargeId: 'charge-001',
      validForUnlock: true,
    );

    final homeSnap = await db.collection('homes').doc(homeId).get();
    expect(homeSnap.data()!['premiumStatus'], 'active');
    expect(homeSnap.data()!['premiumPlan'], 'monthly');
    expect(homeSnap.data()!['premiumEndsAt'], isNotNull);
  });

  test('compra válida nueva → lifetimeUnlockedHomeSlots pasa de 0 a 1', () async {
    await simulateSyncEntitlement(db, homeId, uid,
      status: 'active',
      plan: 'monthly',
      endsAt: DateTime.now().add(const Duration(days: 31)),
      autoRenewEnabled: true,
      chargeId: 'charge-001',
      validForUnlock: true,
    );

    final userSnap = await db.collection('users').doc(uid).get();
    expect(userSnap.data()!['lifetimeUnlockedHomeSlots'], 1);
  });

  test('compra reembolsada → validForUnlock = false, plaza NO desbloqueada', () async {
    await simulateSyncEntitlement(db, homeId, uid,
      status: 'expired_free',
      plan: 'monthly',
      endsAt: DateTime.now(),
      autoRenewEnabled: false,
      chargeId: 'charge-refund',
      validForUnlock: false,
    );

    final userSnap = await db.collection('users').doc(uid).get();
    expect(userSnap.data()!['lifetimeUnlockedHomeSlots'], 0);
  });

  test('dashboard actualiza premiumFlags cuando status = active', () async {
    await simulateSyncEntitlement(db, homeId, uid,
      status: 'active',
      plan: 'annual',
      endsAt: DateTime.now().add(const Duration(days: 365)),
      autoRenewEnabled: true,
      chargeId: 'charge-annual',
      validForUnlock: true,
    );

    final dashSnap = await db.collection('homes').doc(homeId).collection('views').doc('dashboard').get();
    expect(dashSnap.data()!['premiumFlags']['isPremium'], true);
    expect(dashSnap.data()!['premiumFlags']['showAds'], false);
  });
}
