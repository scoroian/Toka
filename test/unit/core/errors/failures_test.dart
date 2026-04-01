import 'package:flutter_test/flutter_test.dart';
import 'package:toka/core/errors/failures.dart';

void main() {
  group('Failure', () {
    test('server failure constructs without message', () {
      const f = Failure.server();
      expect(f, isA<ServerFailure>());
    });

    test('server failure constructs with message', () {
      const f = Failure.server('503');
      f.when(
        server: (msg) => expect(msg, equals('503')),
        cache: (_) => fail('wrong variant'),
        auth: (_) => fail('wrong variant'),
        network: (_) => fail('wrong variant'),
        unknown: (_) => fail('wrong variant'),
      );
    });

    test('auth failure constructs correctly', () {
      const f = Failure.auth('invalid token');
      expect(f, isA<AuthFailure>());
    });

    test('network failure constructs correctly', () {
      const f = Failure.network();
      expect(f, isA<NetworkFailure>());
    });

    test('unknown failure constructs correctly', () {
      const f = Failure.unknown('unexpected');
      expect(f, isA<UnknownFailure>());
    });

    test('two equal failures are equal', () {
      const f1 = Failure.server('x');
      const f2 = Failure.server('x');
      expect(f1, equals(f2));
    });

    test('two different failures are not equal', () {
      const f1 = Failure.server('x');
      const f2 = Failure.cache('x');
      expect(f1, isNot(equals(f2)));
    });
  });
}
