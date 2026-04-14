import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/homes/data/home_model.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
import 'package:toka/features/homes/domain/homes_repository.dart';

class _MockHomesRepository extends Mock implements HomesRepository {}

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
  });
}
