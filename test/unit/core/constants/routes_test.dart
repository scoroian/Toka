import 'package:flutter_test/flutter_test.dart';
import 'package:toka/core/constants/routes.dart';

void main() {
  group('AppRoutes', () {
    test('all route constants are non-empty strings', () {
      for (final r in AppRoutes.all) {
        expect(r, isNotEmpty);
      }
    });

    test('all route constants are unique', () {
      final routes = AppRoutes.all;
      expect(routes.toSet().length, equals(routes.length),
          reason: 'Duplicate route path detected');
    });

    test('all routes start with /', () {
      for (final r in AppRoutes.all) {
        expect(r, startsWith('/'), reason: 'Route $r must start with /');
      }
    });
  });
}
