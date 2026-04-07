import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/shared/services/crashlytics_service.dart';

class MockFirebaseCrashlytics extends Mock implements FirebaseCrashlytics {}

void main() {
  late MockFirebaseCrashlytics mockCrashlytics;
  late CrashlyticsService service;

  setUp(() {
    mockCrashlytics = MockFirebaseCrashlytics();
    service = CrashlyticsService(mockCrashlytics);
  });

  group('CrashlyticsService', () {
    test('setUserId delega a FirebaseCrashlytics.setUserIdentifier', () async {
      when(() => mockCrashlytics.setUserIdentifier(any()))
          .thenAnswer((_) async {});

      await service.setUserId('uid_123');

      verify(() => mockCrashlytics.setUserIdentifier('uid_123')).called(1);
    });

    test('recordError delega a FirebaseCrashlytics.recordError', () async {
      final exception = Exception('test error');
      final stackTrace = StackTrace.current;
      when(() => mockCrashlytics.recordError(any(), any(), fatal: any(named: 'fatal')))
          .thenAnswer((_) async {});

      await service.recordError(exception, stackTrace);

      verify(() => mockCrashlytics.recordError(exception, stackTrace, fatal: false))
          .called(1);
    });

    test('log delega a FirebaseCrashlytics.log', () async {
      when(() => mockCrashlytics.log(any())).thenAnswer((_) async {});

      await service.log('task completed');

      verify(() => mockCrashlytics.log('task completed')).called(1);
    });

    test('setUserId swallows exceptions', () async {
      when(() => mockCrashlytics.setUserIdentifier(any()))
          .thenThrow(Exception('crashlytics error'));

      expect(() => service.setUserId('uid'), returnsNormally);
    });
  });
}
