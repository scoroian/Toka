import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
import 'package:toka/features/members/domain/member.dart';
import 'package:toka/features/profile/domain/personal_metrics.dart';

Member _member(
  String uid, {
  int completed = 0,
  int passed = 0,
  double compliance = 0,
  int streak = 0,
  double score = 0,
}) =>
    Member(
      uid: uid,
      homeId: 'h1',
      nickname: uid,
      photoUrl: null,
      bio: null,
      phone: null,
      phoneVisibility: 'hidden',
      role: MemberRole.member,
      status: MemberStatus.active,
      joinedAt: DateTime(2024),
      tasksCompleted: completed,
      passedCount: passed,
      complianceRate: compliance,
      currentStreak: streak,
      averageScore: score,
    );

void main() {
  group('computePersonalMetrics', () {
    test('usuario con datos: calcula stats y reparto', () {
      final members = [
        _member('me',
            completed: 10, passed: 2, compliance: 0.8, streak: 5, score: 8.5),
        _member('other', completed: 30),
      ];

      final m = computePersonalMetrics(uid: 'me', members: members);

      expect(m.tasksCompleted, 10);
      expect(m.passedCount, 2);
      expect(m.compliancePercent, closeTo(80, 0.001));
      expect(m.currentStreak, 5);
      expect(m.averageScore, 8.5);
      expect(m.sharePercent, closeTo(25, 0.001)); // 10 / (10+30)
      expect(m.hasData, isTrue);
    });

    test('usuario sin actividad: hasData false, reparto 0', () {
      final members = [_member('me'), _member('other')];

      final m = computePersonalMetrics(uid: 'me', members: members);

      expect(m.tasksCompleted, 0);
      expect(m.hasData, isFalse);
      expect(m.sharePercent, 0);
    });

    test('usuario no encontrado: métricas vacías', () {
      final m = computePersonalMetrics(
        uid: 'ghost',
        members: [_member('a', completed: 5)],
      );

      expect(m.hasData, isFalse);
      expect(m.tasksCompleted, 0);
      expect(m.sharePercent, 0);
    });

    test('reparto sin division-by-zero cuando nadie completó', () {
      final members = [
        _member('me', passed: 1),
        _member('other'),
      ];

      final m = computePersonalMetrics(uid: 'me', members: members);

      expect(m.sharePercent, 0);
      expect(m.hasData, isTrue); // tiene un turno pasado
    });

    test('datos parciales: solo completadas, sin puntuación', () {
      final members = [_member('me', completed: 4), _member('o', completed: 4)];

      final m = computePersonalMetrics(uid: 'me', members: members);

      expect(m.hasData, isTrue);
      expect(m.averageScore, 0);
      expect(m.sharePercent, closeTo(50, 0.001));
    });
  });
}
