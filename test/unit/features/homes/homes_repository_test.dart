import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/homes/data/home_model.dart';
import 'package:toka/features/homes/data/homes_repository_impl.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
import 'package:toka/features/homes/domain/homes_repository.dart';

class _MockHomesRepository extends Mock implements HomesRepository {}

class _MockFunctions extends Mock implements FirebaseFunctions {}

Map<String, dynamic> _homeDoc({
  String name = 'Casa',
  String premiumStatus = 'free',
  String? photoUrl,
  bool withTimestamps = true,
}) =>
    {
      'name': name,
      'ownerUid': 'uid1',
      'currentPayerUid': null,
      'lastPayerUid': null,
      'premiumStatus': premiumStatus,
      'premiumPlan': null,
      'premiumEndsAt': null,
      'restoreUntil': null,
      'autoRenewEnabled': false,
      'limits': {'maxMembers': 5},
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (withTimestamps) 'createdAt': Timestamp.fromDate(DateTime(2025)),
      if (withTimestamps) 'updatedAt': Timestamp.fromDate(DateTime(2025)),
    };

void main() {
  late _MockHomesRepository repo;

  final now = DateTime(2025, 1, 1);

  final fakeMembership = HomeMembership(
    homeId: 'h1',
    homeNameSnapshot: 'Casa',
    role: MemberRole.owner,
    billingState: BillingState.currentPayer,
    status: MemberStatus.active,
    joinedAt: now,
  );

  final fakeHome = Home(
    id: 'h1',
    name: 'Casa',
    ownerUid: 'uid1',
    currentPayerUid: 'uid1',
    lastPayerUid: null,
    premiumStatus: HomePremiumStatus.free,
    premiumPlan: null,
    premiumEndsAt: null,
    restoreUntil: null,
    autoRenewEnabled: false,
    limits: const HomeLimits(maxMembers: 5),
    createdAt: now,
    updatedAt: now,
  );

  setUp(() {
    repo = _MockHomesRepository();
  });

  test('watchUserMemberships emits a list of memberships', () {
    when(() => repo.watchUserMemberships('uid1'))
        .thenAnswer((_) => Stream.value([fakeMembership]));

    expect(
      repo.watchUserMemberships('uid1'),
      emits([fakeMembership]),
    );
  });

  test('getAvailableSlots returns 2', () async {
    when(() => repo.getAvailableSlots('uid1')).thenAnswer((_) async => 2);

    final slots = await repo.getAvailableSlots('uid1');
    expect(slots, 2);
  });

  test('getAvailableSlots returns 0', () async {
    when(() => repo.getAvailableSlots('uid1')).thenAnswer((_) async => 0);

    final slots = await repo.getAvailableSlots('uid1');
    expect(slots, 0);
  });

  test('createHome returns new home id', () async {
    when(() => repo.createHome('Casa Nueva'))
        .thenAnswer((_) async => 'new-home-id');

    final id = await repo.createHome('Casa Nueva');
    expect(id, 'new-home-id');
  });

  test('createHome throws NoAvailableSlotsException when no slots', () async {
    when(() => repo.createHome(any()))
        .thenThrow(const NoAvailableSlotsException());

    expect(
      () => repo.createHome('Casa Llena'),
      throwsA(isA<NoAvailableSlotsException>()),
    );
  });

  test('leaveHome throws CannotLeaveAsOwnerException for owner', () async {
    when(() => repo.leaveHome('h1', uid: 'uid1'))
        .thenThrow(const CannotLeaveAsOwnerException());

    expect(
      () => repo.leaveHome('h1', uid: 'uid1'),
      throwsA(isA<CannotLeaveAsOwnerException>()),
    );
  });

  test('leaveHome completes without error for non-owner', () async {
    when(() => repo.leaveHome('h1', uid: 'uid2'))
        .thenAnswer((_) async {});

    await expectLater(
      repo.leaveHome('h1', uid: 'uid2'),
      completes,
    );
  });

  test('fetchHome returns a Home', () async {
    when(() => repo.fetchHome('h1')).thenAnswer((_) async => fakeHome);

    final home = await repo.fetchHome('h1');
    expect(home, fakeHome);
    expect(home.id, 'h1');
  });

  group('HomeModel.membershipFromFirestore', () {
    test('lee hasPendingToday correctamente cuando es true', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      await fakeFirestore
          .collection('users')
          .doc('uid1')
          .collection('memberships')
          .doc('home1')
          .set({
        'homeNameSnapshot': 'Hogar Test',
        'role': 'member',
        'billingState': 'none',
        'status': 'active',
        'joinedAt': Timestamp.fromDate(DateTime(2024)),
        'hasPendingToday': true,
      });
      final docSnap = await fakeFirestore
          .collection('users')
          .doc('uid1')
          .collection('memberships')
          .doc('home1')
          .get();
      final membership = HomeModel.membershipFromFirestore(docSnap);
      expect(membership.hasPendingToday, isTrue);
    });

    test('usa false por defecto si falta hasPendingToday', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      await fakeFirestore
          .collection('users')
          .doc('uid1')
          .collection('memberships')
          .doc('home1')
          .set({
        'homeNameSnapshot': 'Hogar Test',
        'role': 'member',
        'billingState': 'none',
        'status': 'active',
        'joinedAt': Timestamp.fromDate(DateTime(2024)),
        // hasPendingToday absent
      });
      final docSnap = await fakeFirestore
          .collection('users')
          .doc('uid1')
          .collection('memberships')
          .doc('home1')
          .get();
      final membership = HomeModel.membershipFromFirestore(docSnap);
      expect(membership.hasPendingToday, isFalse);
    });

    test('lee homePhotoSnapshot cuando está presente (§10)', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      await fakeFirestore
          .collection('users')
          .doc('uid1')
          .collection('memberships')
          .doc('home1')
          .set({
        'homeNameSnapshot': 'Hogar Test',
        'homePhotoSnapshot': 'https://x.y/casa.jpg',
        'role': 'member',
        'billingState': 'none',
        'status': 'active',
        'joinedAt': Timestamp.fromDate(DateTime(2024)),
      });
      final docSnap = await fakeFirestore
          .collection('users')
          .doc('uid1')
          .collection('memberships')
          .doc('home1')
          .get();
      final membership = HomeModel.membershipFromFirestore(docSnap);
      expect(membership.homePhotoSnapshot, 'https://x.y/casa.jpg');
    });

    test('homePhotoSnapshot es null si falta (hogar sin foto)', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      await fakeFirestore
          .collection('users')
          .doc('uid1')
          .collection('memberships')
          .doc('home1')
          .set({
        'homeNameSnapshot': 'Hogar Test',
        'role': 'member',
        'billingState': 'none',
        'status': 'active',
        'joinedAt': Timestamp.fromDate(DateTime(2024)),
        // homePhotoSnapshot absent
      });
      final docSnap = await fakeFirestore
          .collection('users')
          .doc('uid1')
          .collection('memberships')
          .doc('home1')
          .get();
      final membership = HomeModel.membershipFromFirestore(docSnap);
      expect(membership.homePhotoSnapshot, isNull);
    });
  });

  group('HomesRepositoryImpl.watchHome (BUG-05 sync en vivo)', () {
    late FakeFirebaseFirestore fakeFirestore;
    late HomesRepositoryImpl impl;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      impl = HomesRepositoryImpl(
        firestore: fakeFirestore,
        functions: _MockFunctions(),
      );
    });

    test('re-emite cuando el documento del hogar cambia', () async {
      await fakeFirestore
          .collection('homes')
          .doc('h1')
          .set(_homeDoc(name: 'Casa', premiumStatus: 'free'));

      final emissions = <Home?>[];
      final sub = impl.watchHome('h1').listen(emissions.add);
      await pumpEventQueue();

      // Cambio aplicado "en caliente" (como haría el Admin SDK con la app
      // abierta): nombre, foto y estado premium.
      await fakeFirestore.collection('homes').doc('h1').update({
        'name': 'Casa Renombrada',
        'photoUrl': 'https://example.com/avatar.jpg',
        'premiumStatus': 'active',
      });
      await pumpEventQueue();
      await sub.cancel();

      expect(emissions.first?.name, 'Casa');
      expect(emissions.first?.premiumStatus, HomePremiumStatus.free);
      expect(emissions.last?.name, 'Casa Renombrada');
      expect(emissions.last?.photoUrl, 'https://example.com/avatar.jpg');
      expect(emissions.last?.premiumStatus, HomePremiumStatus.active);
    });

    test('emite null si el documento no existe', () async {
      final first = await impl.watchHome('inexistente').first;
      expect(first, isNull);
    });

    test('tolera timestamps de servidor pendientes (updatedAt/createdAt null)',
        () async {
      // Emisión optimista del dispositivo que acaba de escribir con
      // FieldValue.serverTimestamp(): el snapshot local llega sin los
      // timestamps resueltos. No debe lanzar.
      await fakeFirestore
          .collection('homes')
          .doc('h1')
          .set(_homeDoc(name: 'Casa', withTimestamps: false));

      final home = await impl.watchHome('h1').first;
      expect(home, isNotNull);
      expect(home!.name, 'Casa');
      // Fallback temporal: no nulo, sin crash.
      expect(home.createdAt, isA<DateTime>());
      expect(home.updatedAt, isA<DateTime>());
    });
  });
}
