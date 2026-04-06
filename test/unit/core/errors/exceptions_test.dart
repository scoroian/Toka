import 'package:flutter_test/flutter_test.dart';
import 'package:toka/core/errors/exceptions.dart';

void main() {
  group('ServerException', () {
    test('has default message', () {
      const e = ServerException();
      expect(e.message, equals('Server error'));
    });
    test('accepts custom message', () {
      const e = ServerException('custom');
      expect(e.message, equals('custom'));
    });
    test('toString includes message', () {
      const e = ServerException('oops');
      expect(e.toString(), equals('ServerException: oops'));
    });
  });

  group('CacheException', () {
    test('has default message', () {
      const e = CacheException();
      expect(e.message, equals('Cache error'));
    });
    test('toString includes message', () {
      const e = CacheException('miss');
      expect(e.toString(), equals('CacheException: miss'));
    });
  });

  group('AuthException', () {
    test('has default message', () {
      const e = AuthException();
      expect(e.message, equals('Auth error'));
    });
    test('toString includes message', () {
      const e = AuthException('invalid token');
      expect(e.toString(), equals('AuthException: invalid token'));
    });
  });

  group('NetworkException', () {
    test('has default message', () {
      const e = NetworkException();
      expect(e.message, equals('No network connection'));
    });
    test('toString includes message', () {
      const e = NetworkException('timeout');
      expect(e.toString(), equals('NetworkException: timeout'));
    });
  });

  group('LanguagesFetchException', () {
    test('has default message', () {
      const e = LanguagesFetchException();
      expect(e.message, equals('Failed to fetch languages'));
    });
    test('toString includes message', () {
      const e = LanguagesFetchException('network error');
      expect(e.toString(), equals('LanguagesFetchException: network error'));
    });
  });

  test('MaxMembersReachedException tiene mensaje correcto', () {
    const e = MaxMembersReachedException();
    expect(e.toString(), contains('MaxMembersReachedException'));
  });

  test('MaxAdminsReachedException tiene mensaje correcto', () {
    const e = MaxAdminsReachedException();
    expect(e.toString(), contains('MaxAdminsReachedException'));
  });

  test('CannotRemoveOwnerException tiene mensaje correcto', () {
    const e = CannotRemoveOwnerException();
    expect(e.toString(), contains('CannotRemoveOwnerException'));
  });
}
