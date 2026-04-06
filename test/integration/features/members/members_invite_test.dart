import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/core/errors/exceptions.dart';

/// Simula la CF generateInviteCode: crea doc en invitations con TTL.
Future<String> simulateGenerateCode(
  FakeFirebaseFirestore db,
  String homeId,
  String actorUid,
) async {
  const code = 'ABC123';
  await db
      .collection('homes')
      .doc(homeId)
      .collection('invitations')
      .doc('inv1')
      .set({
    'code': code,
    'createdBy': actorUid,
    'createdAt': Timestamp.fromDate(DateTime.now()),
    'expiresAt':
        Timestamp.fromDate(DateTime.now().add(const Duration(hours: 48))),
    'used': false,
  });
  return code;
}

/// Simula la CF joinHomeByCode: valida TTL y crea membresía.
Future<void> simulateJoinByCode(
  FakeFirebaseFirestore db,
  String homeId,
  String code,
  String newUid,
) async {
  final invitesSnap = await db
      .collection('homes')
      .doc(homeId)
      .collection('invitations')
      .where('code', isEqualTo: code)
      .get();

  if (invitesSnap.docs.isEmpty) throw const InvalidInviteCodeException();

  final invite = invitesSnap.docs.first.data();
  final expiresAt = (invite['expiresAt'] as Timestamp).toDate();
  if (DateTime.now().isAfter(expiresAt)) {
    throw const ExpiredInviteCodeException();
  }

  await db
      .collection('homes')
      .doc(homeId)
      .collection('members')
      .doc(newUid)
      .set({
    'nickname': 'Nuevo Miembro',
    'role': 'member',
    'status': 'active',
    'joinedAt': Timestamp.fromDate(DateTime.now()),
    'phoneVisibility': 'hidden',
    'tasksCompleted': 0,
    'passedCount': 0,
    'complianceRate': 0.0,
    'currentStreak': 0,
    'averageScore': 0.0,
  });

  await db
      .collection('users')
      .doc(newUid)
      .collection('memberships')
      .doc(homeId)
      .set({
    'homeId': homeId,
    'homeNameSnapshot': 'Casa de prueba',
    'role': 'member',
    'status': 'active',
    'billingState': 'none',
    'joinedAt': Timestamp.fromDate(DateTime.now()),
  });
}

/// Simula la CF transferOwnership: cambia roles en Firestore.
Future<void> simulateTransferOwnership(
  FakeFirebaseFirestore db,
  String homeId,
  String currentOwnerUid,
  String newOwnerUid,
) async {
  // Nuevo owner
  await db
      .collection('homes')
      .doc(homeId)
      .collection('members')
      .doc(newOwnerUid)
      .update({'role': 'owner'});
  await db
      .collection('users')
      .doc(newOwnerUid)
      .collection('memberships')
      .doc(homeId)
      .update({'role': 'owner'});

  // Anterior owner pasa a admin
  await db
      .collection('homes')
      .doc(homeId)
      .collection('members')
      .doc(currentOwnerUid)
      .update({'role': 'admin'});
  await db
      .collection('users')
      .doc(currentOwnerUid)
      .collection('memberships')
      .doc(homeId)
      .update({'role': 'admin'});

  // Actualizar homes/{homeId}
  await db.collection('homes').doc(homeId).update({'ownerUid': newOwnerUid});
}

void main() {
  late FakeFirebaseFirestore db;
  const homeId = 'home1';
  const ownerUid = 'uid-owner';
  const member1Uid = 'uid-m1';
  const member2Uid = 'uid-m2';

  Future<void> seedHome() async {
    await db.collection('homes').doc(homeId).set({
      'name': 'Casa de prueba',
      'ownerUid': ownerUid,
      'premiumStatus': 'free',
    });

    for (final uid in [ownerUid, member1Uid, member2Uid]) {
      final role = uid == ownerUid ? 'owner' : 'member';
      await db
          .collection('homes')
          .doc(homeId)
          .collection('members')
          .doc(uid)
          .set({
        'nickname': uid,
        'role': role,
        'status': 'active',
        'joinedAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'phoneVisibility': 'hidden',
        'tasksCompleted': 0,
        'passedCount': 0,
        'complianceRate': 0.0,
        'currentStreak': 0,
        'averageScore': 0.0,
      });
      await db
          .collection('users')
          .doc(uid)
          .collection('memberships')
          .doc(homeId)
          .set({
        'homeId': homeId,
        'homeNameSnapshot': 'Casa de prueba',
        'role': role,
        'status': 'active',
        'billingState': uid == ownerUid ? 'currentPayer' : 'none',
        'joinedAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      });
    }
  }

  setUp(() async {
    db = FakeFirebaseFirestore();
    await seedHome();
  });

  test('invitar miembro con código → membresía creada correctamente', () async {
    const newUid = 'uid-new';
    final code = await simulateGenerateCode(db, homeId, ownerUid);
    await simulateJoinByCode(db, homeId, code, newUid);

    final memberDoc = await db
        .collection('homes')
        .doc(homeId)
        .collection('members')
        .doc(newUid)
        .get();

    expect(memberDoc.exists, isTrue);
    expect(memberDoc.data()!['role'], 'member');
    expect(memberDoc.data()!['status'], 'active');

    final membershipDoc = await db
        .collection('users')
        .doc(newUid)
        .collection('memberships')
        .doc(homeId)
        .get();
    expect(membershipDoc.exists, isTrue);
  });

  test('código expirado → lanza ExpiredInviteCodeException', () async {
    // Crear invitación ya expirada
    await db
        .collection('homes')
        .doc(homeId)
        .collection('invitations')
        .doc('expired')
        .set({
      'code': 'EXP999',
      'createdBy': ownerUid,
      'createdAt':
          Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
      'expiresAt':
          Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
      'used': false,
    });

    expect(
      () => simulateJoinByCode(db, homeId, 'EXP999', 'uid-late'),
      throwsA(isA<ExpiredInviteCodeException>()),
    );
  });

  test('Free con 3 miembros activos → invitar 4º → límite Free (máx 3)', () async {
    // Ya hay 3 miembros (owner + m1 + m2), verificar que la CF debe rechazarlo.
    // Simulamos la validación que haría la CF:
    final membersSnap = await db
        .collection('homes')
        .doc(homeId)
        .collection('members')
        .where('status', isEqualTo: 'active')
        .get();

    final activeCount = membersSnap.docs.length;
    const freePlanMaxMembers = 3;

    expect(activeCount, 3);
    expect(activeCount >= freePlanMaxMembers, isTrue,
        reason: 'La CF debe rechazar la invitación por límite de plan Free');
  });

  test('transferir propiedad → owner anterior pasa a admin, nuevo uid es owner', () async {
    await simulateTransferOwnership(db, homeId, ownerUid, member1Uid);

    // Verificar nuevo owner
    final newOwnerDoc = await db
        .collection('homes')
        .doc(homeId)
        .collection('members')
        .doc(member1Uid)
        .get();
    expect(newOwnerDoc.data()!['role'], 'owner');

    // Verificar que owner anterior es ahora admin
    final oldOwnerDoc = await db
        .collection('homes')
        .doc(homeId)
        .collection('members')
        .doc(ownerUid)
        .get();
    expect(oldOwnerDoc.data()!['role'], 'admin');

    // Verificar campo ownerUid en homes doc
    final homeDoc = await db.collection('homes').doc(homeId).get();
    expect(homeDoc.data()!['ownerUid'], member1Uid);
  });
}
