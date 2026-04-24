// test/unit/features/subscription/subscription_dashboard_test.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/subscription/domain/subscription_dashboard.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';

void main() {
  group('SubscriptionDashboard.fromMaps', () {
    test('construye estado active con plan y endsAt', () {
      final dash = SubscriptionDashboard.fromMaps(
        homeId: 'h1',
        home: {
          'premiumStatus': 'active',
          'premiumPlan': 'annual',
          'premiumEndsAt': Timestamp.fromDate(DateTime(2027)),
          'autoRenewEnabled': true,
          'currentPayerUid': 'u1',
        },
        dashboard: {
          'planCounters': {
            'activeMembers': 2,
            'automaticRecurringTasks': 1,
          },
        },
      );
      expect(dash.homeId, 'h1');
      expect(dash.status, HomePremiumStatus.active);
      expect(dash.plan, 'annual');
      expect(dash.endsAt, DateTime(2027));
      expect(dash.autoRenew, isTrue);
      expect(dash.currentPayerUid, 'u1');
      expect(dash.planCounters.activeMembers, 2);
      expect(dash.planCounters.automaticRecurringTasks, 1);
      expect(dash.isPremium, isTrue);
    });

    test('usa free cuando no hay premiumStatus', () {
      final dash = SubscriptionDashboard.fromMaps(
        homeId: 'h1',
        home: const {},
      );
      expect(dash.status, HomePremiumStatus.free);
      expect(dash.plan, isNull);
      expect(dash.endsAt, isNull);
      expect(dash.autoRenew, isFalse);
      expect(dash.isPremium, isFalse);
    });

    test('planCounters es empty si no viene dashboard', () {
      final dash = SubscriptionDashboard.fromMaps(
        homeId: 'h1',
        home: const {'premiumStatus': 'free'},
      );
      expect(dash.planCounters, PlanCounters.empty());
      expect(dash.planCounters.activeMembers, 0);
      expect(dash.planCounters.automaticRecurringTasks, 0);
    });

    test('isPremium true en cancelledPendingEnd y rescue, false en el resto',
        () {
      SubscriptionDashboard withStatus(String s) =>
          SubscriptionDashboard.fromMaps(
            homeId: 'h1',
            home: {'premiumStatus': s},
          );
      expect(withStatus('active').isPremium, isTrue);
      expect(withStatus('cancelledPendingEnd').isPremium, isTrue);
      expect(withStatus('rescue').isPremium, isTrue);
      expect(withStatus('free').isPremium, isFalse);
      expect(withStatus('expiredFree').isPremium, isFalse);
      expect(withStatus('restorable').isPremium, isFalse);
    });

    test('daysLeft 0 cuando endsAt es pasado', () {
      final dash = SubscriptionDashboard.fromMaps(
        homeId: 'h1',
        home: {
          'premiumStatus': 'active',
          'premiumEndsAt':
              Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 5))),
        },
      );
      expect(dash.daysLeft, 0);
    });
  });

  group('SubscriptionDashboard.empty', () {
    test('devuelve estado free vacío', () {
      final dash = SubscriptionDashboard.empty('h1');
      expect(dash.status, HomePremiumStatus.free);
      expect(dash.planCounters, PlanCounters.empty());
      expect(dash.isPremium, isFalse);
    });
  });
}
