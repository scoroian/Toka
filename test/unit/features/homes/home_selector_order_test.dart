import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
import 'package:toka/features/homes/presentation/home_selector_widget.dart';

HomeMembership _m(String id, String name) => HomeMembership(
      homeId: id,
      homeNameSnapshot: name,
      role: MemberRole.member,
      billingState: BillingState.none,
      status: MemberStatus.active,
      joinedAt: DateTime(2025),
    );

void main() {
  group('sortMembershipsForSelector', () {
    test('current home appears first', () {
      final memberships = [
        _m('h1', 'Alfa'),
        _m('h2', 'Beta'),
        _m('h3', 'Gamma'),
      ];

      final sorted = sortMembershipsForSelector(
        memberships,
        currentHomeId: 'h2',
      );

      expect(sorted.first.homeId, 'h2');
    });

    test('remaining homes are ordered alphabetically by name', () {
      final memberships = [
        _m('h1', 'Zeta'),
        _m('h2', 'Alfa'),
        _m('h3', 'Mango'),
        _m('h4', 'Beta'),
      ];

      final sorted = sortMembershipsForSelector(
        memberships,
        currentHomeId: 'h2',
      );

      // h2 (Alfa) is current → first
      expect(sorted[0].homeId, 'h2');
      // Remaining: Beta (h4), Mango (h3), Zeta (h1)
      expect(sorted[1].homeId, 'h4');
      expect(sorted[2].homeId, 'h3');
      expect(sorted[3].homeId, 'h1');
    });

    test('single home returns single-element list', () {
      final memberships = [_m('h1', 'Casa Única')];

      final sorted = sortMembershipsForSelector(
        memberships,
        currentHomeId: 'h1',
      );

      expect(sorted.length, 1);
      expect(sorted.first.homeId, 'h1');
    });

    test('empty list returns empty list', () {
      final sorted = sortMembershipsForSelector(
        [],
        currentHomeId: 'h1',
      );

      expect(sorted, isEmpty);
    });

    test('original list is not mutated', () {
      final memberships = [
        _m('h1', 'Zeta'),
        _m('h2', 'Alfa'),
      ];
      final originalOrder = [...memberships];

      sortMembershipsForSelector(memberships, currentHomeId: 'h2');

      expect(memberships[0].homeId, originalOrder[0].homeId);
      expect(memberships[1].homeId, originalOrder[1].homeId);
    });
  });
}
