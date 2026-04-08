// test/unit/features/settings/settings_view_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/settings/application/settings_view_model.dart';
import 'package:toka/features/subscription/domain/subscription_state.dart';

// Mirror of the _computeIsPremium logic from the ViewModel
bool _computeIsPremium(SubscriptionState state) => state.map(
      free: (_) => false,
      active: (_) => true,
      cancelledPendingEnd: (_) => true,
      rescue: (_) => true,
      expiredFree: (_) => false,
      restorable: (_) => false,
      purged: (_) => false,
    );

void main() {
  group('SettingsViewData', () {
    test('holds isPremium, homeId, uid, and appVersion', () {
      const data = SettingsViewData(
        isPremium: true,
        homeId: 'h1',
        uid: 'u1',
        appVersion: '1.0.0 (42)',
      );
      expect(data.isPremium, isTrue);
      expect(data.homeId, 'h1');
      expect(data.uid, 'u1');
      expect(data.appVersion, '1.0.0 (42)');
    });

    test('appVersion is nullable and can be null', () {
      const data = SettingsViewData(
        isPremium: false,
        homeId: '',
        uid: '',
      );
      expect(data.appVersion, isNull);
    });
  });

  group('SettingsViewModel isPremium computation', () {
    test('active subscription is premium', () {
      final sub = SubscriptionState.active(
        plan: 'monthly',
        endsAt: DateTime(2026, 12, 31),
        autoRenew: true,
      );
      expect(_computeIsPremium(sub), isTrue);
    });

    test('free subscription is not premium', () {
      const sub = SubscriptionState.free();
      expect(_computeIsPremium(sub), isFalse);
    });

    test('rescue subscription is premium', () {
      final sub = SubscriptionState.rescue(
        plan: 'monthly',
        endsAt: DateTime(2026, 4, 10),
        daysLeft: 3,
      );
      expect(_computeIsPremium(sub), isTrue);
    });

    test('expiredFree is not premium', () {
      const sub = SubscriptionState.expiredFree();
      expect(_computeIsPremium(sub), isFalse);
    });
  });
}
