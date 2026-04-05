import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/auth/domain/failures/auth_failure.dart';

void main() {
  group('AuthFailure', () {
    test('networkError is identified by maybeWhen', () {
      const f = AuthFailure.networkError();
      final result = f.maybeWhen(networkError: () => true, orElse: () => false);
      expect(result, isTrue);
    });

    test('accountExistsWithDifferentCredential holds email and providers', () {
      const f = AuthFailure.accountExistsWithDifferentCredential(
        email: 'a@b.com',
        providers: ['google.com'],
      );
      f.maybeWhen(
        accountExistsWithDifferentCredential: (email, providers) {
          expect(email, 'a@b.com');
          expect(providers, ['google.com']);
        },
        orElse: () => fail('wrong variant'),
      );
    });

    test('unknown holds optional message', () {
      const f = AuthFailure.unknown('oops');
      f.maybeWhen(
        unknown: (msg) => expect(msg, 'oops'),
        orElse: () => fail('wrong variant'),
      );
    });

    test('two identical failures are equal', () {
      expect(
        const AuthFailure.invalidCredentials(),
        const AuthFailure.invalidCredentials(),
      );
    });
  });
}
