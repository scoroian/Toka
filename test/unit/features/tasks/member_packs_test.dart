import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';

void main() {
  group('MemberPacks.fromMap', () {
    test('lee plus5/plus10 del mapa', () {
      final p = MemberPacks.fromMap({'plus5': true, 'plus10': false});
      expect(p.plus5, isTrue);
      expect(p.plus10, isFalse);
    });

    test('ambos activos', () {
      final p = MemberPacks.fromMap({'plus5': true, 'plus10': true});
      expect(p.plus5, isTrue);
      expect(p.plus10, isTrue);
    });

    test('claves ausentes → false (default seguro)', () {
      final p = MemberPacks.fromMap(const {});
      expect(p.plus5, isFalse);
      expect(p.plus10, isFalse);
    });
  });

  group('MemberPacks helpers', () {
    test('activeCount cuenta los packs vigentes', () {
      expect(const MemberPacks().activeCount, 0);
      expect(const MemberPacks(plus5: true).activeCount, 1);
      expect(const MemberPacks(plus10: true).activeCount, 1);
      expect(const MemberPacks(plus5: true, plus10: true).activeCount, 2);
    });

    test('isMaxed solo cuando ambos packs están activos', () {
      expect(const MemberPacks().isMaxed, isFalse);
      expect(const MemberPacks(plus5: true).isMaxed, isFalse);
      expect(const MemberPacks(plus10: true).isMaxed, isFalse);
      expect(const MemberPacks(plus5: true, plus10: true).isMaxed, isTrue);
    });

    test('empty es ambos false', () {
      expect(MemberPacks.empty.plus5, isFalse);
      expect(MemberPacks.empty.plus10, isFalse);
    });
  });

  group('PremiumFlags.fromMap memberPacks', () {
    test('parsea memberPacks cuando viene en el dashboard', () {
      final flags = PremiumFlags.fromMap({
        'isPremium': true,
        'tier': 'grupo',
        'maxMembers': 20,
        'memberPacks': {'plus5': false, 'plus10': true},
      });
      expect(flags.memberPacks, isNotNull);
      expect(flags.memberPacks!.plus5, isFalse);
      expect(flags.memberPacks!.plus10, isTrue);
    });

    test('memberPacks null en dashboards legacy sin el campo', () {
      final flags = PremiumFlags.fromMap({
        'isPremium': true,
        'tier': 'grupo',
        'maxMembers': 10,
      });
      expect(flags.memberPacks, isNull);
    });
  });
}
