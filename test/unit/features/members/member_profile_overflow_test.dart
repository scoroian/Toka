// test/unit/features/members/member_profile_overflow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
import 'package:toka/features/members/application/member_profile_view_model.dart';
import 'package:toka/features/members/domain/member.dart';

void main() {
  final testMember = Member(
    uid: 'u1',
    homeId: 'h1',
    nickname: 'Ana',
    photoUrl: null,
    bio: null,
    phone: null,
    phoneVisibility: 'private',
    role: MemberRole.member,
    status: MemberStatus.active,
    joinedAt: DateTime(2024, 1, 1),
    tasksCompleted: 5,
    passedCount: 0,
    complianceRate: 0.8,
    currentStreak: 3,
    averageScore: 7.5,
  );

  group('MemberProfileViewData — campos enriquecidos', () {
    test('showRadar false cuando radarEntries < 3', () {
      final data = MemberProfileViewData(
        member: testMember,
        isSelf: false,
        visiblePhone: null,
        compliancePct: '80',
        radarEntries: [],
        canManageRoles: false,
        canRemoveMember: false,
        completedCount: 5,
        streakCount: 3,
        averageScore: 7.5,
        showRadar: false,
        overflowEntries: [],
      );
      expect(data.showRadar, isFalse);
      expect(data.completedCount, 5);
      expect(data.streakCount, 3);
      expect(data.averageScore, 7.5);
    });

    test('canManageRoles true se propaga correctamente', () {
      final data = MemberProfileViewData(
        member: testMember,
        isSelf: false,
        visiblePhone: null,
        compliancePct: '90',
        radarEntries: [],
        canManageRoles: true,
        canRemoveMember: false,
        completedCount: 10,
        streakCount: 5,
        averageScore: 8.0,
        showRadar: false,
        overflowEntries: [],
      );
      expect(data.canManageRoles, isTrue);
    });

    test('overflowEntries se propagan correctamente', () {
      const entry = OverflowEntry(
        taskId: 't1',
        title: 'Barrer',
        visualKind: 'emoji',
        visualValue: '🧹',
        averageScore: 8.5,
      );
      final data = MemberProfileViewData(
        member: testMember,
        isSelf: false,
        visiblePhone: null,
        compliancePct: '85',
        radarEntries: [],
        canManageRoles: false,
        canRemoveMember: false,
        completedCount: 3,
        streakCount: 1,
        averageScore: 8.5,
        showRadar: false,
        overflowEntries: [entry],
      );
      expect(data.overflowEntries.length, 1);
      expect(data.overflowEntries.first.title, 'Barrer');
    });
  });
}
