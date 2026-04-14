import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/application/today_view_model.dart';
import 'package:toka/features/homes/domain/home_membership.dart';

void main() {
  group('HomeDropdownItem', () {
    test('hasPendingToday true se refleja en el item', () {
      const item = HomeDropdownItem(
        homeId: 'h1',
        name: 'Casa',
        emoji: '🏠',
        role: MemberRole.owner,
        hasPendingToday: true,
        isSelected: true,
      );
      expect(item.hasPendingToday, isTrue);
      expect(item.isSelected, isTrue);
      expect(item.homeId, 'h1');
    });

    test('hasPendingToday false por defecto', () {
      const item = HomeDropdownItem(
        homeId: 'h2',
        name: 'Piso',
        emoji: '🏢',
        role: MemberRole.member,
        hasPendingToday: false,
        isSelected: false,
      );
      expect(item.hasPendingToday, isFalse);
      expect(item.isSelected, isFalse);
    });
  });
}
