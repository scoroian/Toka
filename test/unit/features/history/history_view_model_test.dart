// test/unit/features/history/history_view_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/history/application/history_provider.dart';

void main() {
  group('HistoryFilter', () {
    test('default HistoryFilter has all null fields', () {
      const filter = HistoryFilter();
      expect(filter.memberUid, isNull);
      expect(filter.taskId, isNull);
      expect(filter.eventType, isNull);
    });

    test('HistoryFilter equality: two default instances are equal', () {
      const f1 = HistoryFilter();
      const f2 = HistoryFilter();
      expect(f1, equals(f2));
    });

    test('HistoryFilter copyWith changes only specified fields', () {
      const f = HistoryFilter();
      final f2 = f.copyWith(memberUid: 'u1', eventType: 'completed');
      expect(f2.memberUid, 'u1');
      expect(f2.eventType, 'completed');
      expect(f2.taskId, isNull);
    });

    test('HistoryFilter with memberUid differs from default', () {
      const base = HistoryFilter();
      final withMember = base.copyWith(memberUid: 'u2');
      expect(withMember, isNot(equals(base)));
    });
  });
}
