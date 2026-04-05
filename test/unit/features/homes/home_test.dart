import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/features/homes/domain/home_membership.dart';

void main() {
  group('HomePremiumStatus.fromString', () {
    test('returns active for "active"', () {
      expect(
        HomePremiumStatus.fromString('active'),
        HomePremiumStatus.active,
      );
    });

    test('returns free for "free"', () {
      expect(
        HomePremiumStatus.fromString('free'),
        HomePremiumStatus.free,
      );
    });

    test('returns cancelledPendingEnd for "cancelledPendingEnd"', () {
      expect(
        HomePremiumStatus.fromString('cancelledPendingEnd'),
        HomePremiumStatus.cancelledPendingEnd,
      );
    });

    test('returns free as fallback for unknown value', () {
      expect(
        HomePremiumStatus.fromString('unknownValue'),
        HomePremiumStatus.free,
      );
    });

    test('all 7 enum values round-trip through fromString', () {
      for (final status in HomePremiumStatus.values) {
        expect(
          HomePremiumStatus.fromString(status.name),
          status,
          reason: 'Round-trip failed for ${status.name}',
        );
      }
    });

    test('all 7 enum values are present', () {
      expect(HomePremiumStatus.values.length, 7);
      expect(HomePremiumStatus.values, containsAll([
        HomePremiumStatus.free,
        HomePremiumStatus.active,
        HomePremiumStatus.cancelledPendingEnd,
        HomePremiumStatus.rescue,
        HomePremiumStatus.expiredFree,
        HomePremiumStatus.restorable,
        HomePremiumStatus.purged,
      ]));
    });
  });

  group('Home', () {
    final now = DateTime(2025, 1, 1);

    Home buildHome({
      String id = 'h1',
      String name = 'Casa',
      String ownerUid = 'owner-uid',
      String? currentPayerUid = 'payer-uid',
      String? lastPayerUid = 'last-payer-uid',
      HomePremiumStatus premiumStatus = HomePremiumStatus.active,
      String? premiumPlan = 'monthly',
      DateTime? premiumEndsAt,
      DateTime? restoreUntil,
      bool autoRenewEnabled = true,
      HomeLimits? limits,
      DateTime? createdAt,
      DateTime? updatedAt,
    }) {
      return Home(
        id: id,
        name: name,
        ownerUid: ownerUid,
        currentPayerUid: currentPayerUid,
        lastPayerUid: lastPayerUid,
        premiumStatus: premiumStatus,
        premiumPlan: premiumPlan,
        premiumEndsAt: premiumEndsAt,
        restoreUntil: restoreUntil,
        autoRenewEnabled: autoRenewEnabled,
        limits: limits ?? const HomeLimits(maxMembers: 5),
        createdAt: createdAt ?? now,
        updatedAt: updatedAt ?? now,
      );
    }

    test('constructs with all fields correctly', () {
      final endsAt = DateTime(2025, 6, 1);
      final restoreUntil = DateTime(2025, 7, 1);
      final home = buildHome(
        premiumEndsAt: endsAt,
        restoreUntil: restoreUntil,
      );

      expect(home.id, 'h1');
      expect(home.name, 'Casa');
      expect(home.ownerUid, 'owner-uid');
      expect(home.currentPayerUid, 'payer-uid');
      expect(home.lastPayerUid, 'last-payer-uid');
      expect(home.premiumStatus, HomePremiumStatus.active);
      expect(home.premiumPlan, 'monthly');
      expect(home.premiumEndsAt, endsAt);
      expect(home.restoreUntil, restoreUntil);
      expect(home.autoRenewEnabled, isTrue);
      expect(home.limits.maxMembers, 5);
      expect(home.createdAt, now);
      expect(home.updatedAt, now);
    });

    test('constructs with null optional fields', () {
      final home = buildHome(
        currentPayerUid: null,
        lastPayerUid: null,
        premiumPlan: null,
        premiumEndsAt: null,
        restoreUntil: null,
        premiumStatus: HomePremiumStatus.free,
      );

      expect(home.currentPayerUid, isNull);
      expect(home.lastPayerUid, isNull);
      expect(home.premiumPlan, isNull);
      expect(home.premiumEndsAt, isNull);
      expect(home.restoreUntil, isNull);
    });

    test('copyWith changes only specified field', () {
      final original = buildHome();
      final modified = original.copyWith(name: 'Nuevo Nombre');

      expect(modified.name, 'Nuevo Nombre');
      expect(modified.id, original.id);
      expect(modified.ownerUid, original.ownerUid);
      expect(modified.premiumStatus, original.premiumStatus);
      expect(modified.limits, original.limits);
    });

    test('two Homes with same values are equal (freezed ==)', () {
      final home1 = buildHome();
      final home2 = buildHome();

      expect(home1, equals(home2));
    });

    test('two Homes with different values are not equal', () {
      final home1 = buildHome(name: 'Casa A');
      final home2 = buildHome(name: 'Casa B');

      expect(home1, isNot(equals(home2)));
    });
  });

  group('HomeMembership', () {
    final joinedAt = DateTime(2025, 1, 1);

    test('constructs with owner role', () {
      final membership = HomeMembership(
        homeId: 'h1',
        homeNameSnapshot: 'Casa Principal',
        role: MemberRole.owner,
        billingState: BillingState.currentPayer,
        status: MemberStatus.active,
        joinedAt: joinedAt,
      );

      expect(membership.homeId, 'h1');
      expect(membership.homeNameSnapshot, 'Casa Principal');
      expect(membership.role, MemberRole.owner);
      expect(membership.billingState, BillingState.currentPayer);
      expect(membership.status, MemberStatus.active);
      expect(membership.joinedAt, joinedAt);
      expect(membership.leftAt, isNull);
    });

    test('leftAt can be non-null', () {
      final leftDate = DateTime(2025, 6, 15);
      final membership = HomeMembership(
        homeId: 'h2',
        homeNameSnapshot: 'Piso Compartido',
        role: MemberRole.member,
        billingState: BillingState.none,
        status: MemberStatus.frozen,
        joinedAt: joinedAt,
        leftAt: leftDate,
      );

      expect(membership.leftAt, leftDate);
    });
  });
}
