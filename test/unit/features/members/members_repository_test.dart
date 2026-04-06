import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/core/errors/exceptions.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
import 'package:toka/features/members/domain/member.dart';
import 'package:toka/features/members/domain/members_repository.dart';

class _MockMembersRepository extends Mock implements MembersRepository {}

void main() {
  late _MockMembersRepository repo;

  final fakeMember = Member(
    uid: 'uid1',
    homeId: 'home1',
    nickname: 'Ana',
    photoUrl: null,
    bio: null,
    phone: null,
    phoneVisibility: 'hidden',
    role: MemberRole.member,
    status: MemberStatus.active,
    joinedAt: DateTime(2026, 1, 1),
    tasksCompleted: 5,
    passedCount: 1,
    complianceRate: 0.83,
    currentStreak: 2,
    averageScore: 8.0,
  );

  setUp(() {
    repo = _MockMembersRepository();
  });

  test('watchHomeMembers emite lista de miembros', () {
    when(() => repo.watchHomeMembers('home1'))
        .thenAnswer((_) => Stream.value([fakeMember]));
    expect(repo.watchHomeMembers('home1'), emits([fakeMember]));
  });

  test('inviteMember lanza MaxMembersReachedException si home está lleno', () {
    when(() => repo.inviteMember('home1', null))
        .thenThrow(const MaxMembersReachedException());
    expect(
      () => repo.inviteMember('home1', null),
      throwsA(isA<MaxMembersReachedException>()),
    );
  });

  test('promoteToAdmin lanza MaxAdminsReachedException en plan Free', () {
    when(() => repo.promoteToAdmin('home1', 'uid2'))
        .thenThrow(const MaxAdminsReachedException());
    expect(
      () => repo.promoteToAdmin('home1', 'uid2'),
      throwsA(isA<MaxAdminsReachedException>()),
    );
  });

  test('removeMember lanza CannotRemoveOwnerException para el owner', () {
    when(() => repo.removeMember('home1', 'uid-owner'))
        .thenThrow(const CannotRemoveOwnerException());
    expect(
      () => repo.removeMember('home1', 'uid-owner'),
      throwsA(isA<CannotRemoveOwnerException>()),
    );
  });

  test('generateInviteCode retorna código de 6 chars', () async {
    when(() => repo.generateInviteCode('home1'))
        .thenAnswer((_) async => 'ABC123');
    final code = await repo.generateInviteCode('home1');
    expect(code.length, 6);
  });
}
