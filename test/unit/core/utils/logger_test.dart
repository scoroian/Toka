import 'package:flutter_test/flutter_test.dart';
import 'package:toka/core/utils/logger.dart';

void main() {
  group('AppLogger', () {
    test('debug does not throw', () {
      expect(() => AppLogger.debug('msg'), returnsNormally);
    });

    test('info does not throw', () {
      expect(() => AppLogger.info('msg'), returnsNormally);
    });

    test('warning does not throw', () {
      expect(() => AppLogger.warning('msg'), returnsNormally);
    });

    test('error does not throw', () {
      expect(() => AppLogger.error('msg'), returnsNormally);
    });

    test('accepts optional error and stackTrace without throwing', () {
      expect(
        () => AppLogger.error('msg', Exception('e'), StackTrace.current),
        returnsNormally,
      );
    });
  });
}
