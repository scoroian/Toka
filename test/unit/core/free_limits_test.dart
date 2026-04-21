import 'package:flutter_test/flutter_test.dart';
import 'package:toka/core/constants/free_limits.dart';

void main() {
  group('FreeLimits', () {
    test('valores coinciden con la spec §6.1', () {
      expect(FreeLimits.maxActiveMembers, 3);
      expect(FreeLimits.maxActiveTasks, 4);
      expect(FreeLimits.maxAdminsTotal, 1);
      expect(FreeLimits.maxAutomaticRecurringTasks, 3);
    });
  });

  group('isHomePremium', () {
    test('true para active, cancelledPendingEnd y rescue', () {
      expect(isHomePremium('active'), isTrue);
      expect(isHomePremium('cancelledPendingEnd'), isTrue);
      expect(isHomePremium('rescue'), isTrue);
    });

    test('false para free, expiredFree, restorable, purged y null', () {
      expect(isHomePremium('free'), isFalse);
      expect(isHomePremium('expiredFree'), isFalse);
      expect(isHomePremium('restorable'), isFalse);
      expect(isHomePremium('purged'), isFalse);
      expect(isHomePremium(null), isFalse);
    });

    test('false para status desconocido', () {
      expect(isHomePremium('unknown'), isFalse);
      expect(isHomePremium(''), isFalse);
    });
  });
}
