// test/unit/features/notifications/notification_settings_view_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/notifications/domain/notification_preferences.dart';
import 'package:toka/features/subscription/domain/subscription_state.dart';

// Helper that mirrors the _subIsPremium logic from the ViewModel
bool _subIsPremium(SubscriptionState sub) => sub.map(
      free: (_) => false,
      active: (_) => true,
      cancelledPendingEnd: (_) => true,
      rescue: (_) => true,
      expiredFree: (_) => false,
      restorable: (_) => false,
      purged: (_) => false,
    );

void main() {
  group('NotificationSettingsViewModel isPremium logic', () {
    test('active subscription returns isPremium = true', () {
      final sub = SubscriptionState.active(
        plan: 'monthly',
        endsAt: DateTime(2026, 12, 31),
        autoRenew: true,
      );
      expect(_subIsPremium(sub), isTrue);
    });

    test('free subscription returns isPremium = false', () {
      const sub = SubscriptionState.free();
      expect(_subIsPremium(sub), isFalse);
    });

    test('cancelledPendingEnd returns isPremium = true', () {
      final sub = SubscriptionState.cancelledPendingEnd(
        plan: 'monthly',
        endsAt: DateTime(2026, 5, 1),
      );
      expect(_subIsPremium(sub), isTrue);
    });

    test('restorable returns isPremium = false', () {
      final sub = SubscriptionState.restorable(
        restoreUntil: DateTime(2026, 5, 1),
      );
      expect(_subIsPremium(sub), isFalse);
    });
  });

  group('NotificationPreferences defaults', () {
    test('default prefs have notifyOnDue = true and notifyBefore = false', () {
      final prefs = NotificationPreferences(homeId: 'h1', uid: 'u1');
      expect(prefs.notifyOnDue, isTrue);
      expect(prefs.notifyBefore, isFalse);
      expect(prefs.minutesBefore, 30);
    });

    test('copyWith updates notifyBefore correctly', () {
      final prefs = NotificationPreferences(homeId: 'h1', uid: 'u1');
      final updated = prefs.copyWith(notifyBefore: true, minutesBefore: 60);
      expect(updated.notifyBefore, isTrue);
      expect(updated.minutesBefore, 60);
    });
  });
}
