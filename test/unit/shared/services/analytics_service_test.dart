import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/shared/services/analytics_service.dart';

class MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

void main() {
  late MockFirebaseAnalytics mockAnalytics;
  late AnalyticsService service;

  setUp(() {
    mockAnalytics = MockFirebaseAnalytics();
    service = AnalyticsService(mockAnalytics);
  });

  group('AnalyticsService.logEvent', () {
    test('delegates to FirebaseAnalytics.logEvent', () async {
      when(() => mockAnalytics.logEvent(
            name: any(named: 'name'),
            parameters: any(named: 'parameters'),
          )).thenAnswer((_) async {});

      await service.logEvent('test_event');

      verify(() => mockAnalytics.logEvent(name: 'test_event')).called(1);
    });

    test('swallows exceptions and does not rethrow', () async {
      when(() => mockAnalytics.logEvent(
            name: any(named: 'name'),
            parameters: any(named: 'parameters'),
          )).thenThrow(Exception('analytics error'));

      expect(() => service.logEvent('test_event'), returnsNormally);
    });
  });

  group('AnalyticsService.setUserId', () {
    test('delegates to FirebaseAnalytics.setUserId', () async {
      when(() => mockAnalytics.setUserId(id: any(named: 'id')))
          .thenAnswer((_) async {});

      await service.setUserId('uid_123');

      verify(() => mockAnalytics.setUserId(id: 'uid_123')).called(1);
    });

    test('swallows exceptions', () async {
      when(() => mockAnalytics.setUserId(id: any(named: 'id')))
          .thenThrow(Exception('uid error'));

      expect(() => service.setUserId('uid'), returnsNormally);
    });
  });

  group('AnalyticsService.logScreenView', () {
    test('delegates to FirebaseAnalytics.logScreenView', () async {
      when(() => mockAnalytics.logScreenView(
            screenName: any(named: 'screenName'),
          )).thenAnswer((_) async {});

      await service.logScreenView('HomeScreen');

      verify(() => mockAnalytics.logScreenView(screenName: 'HomeScreen'))
          .called(1);
    });

    test('swallows exceptions', () async {
      when(() => mockAnalytics.logScreenView(
            screenName: any(named: 'screenName'),
          )).thenThrow(Exception('screen error'));

      expect(() => service.logScreenView('HomeScreen'), returnsNormally);
    });
  });
}
