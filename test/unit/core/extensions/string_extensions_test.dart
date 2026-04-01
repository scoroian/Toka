import 'package:flutter_test/flutter_test.dart';
import 'package:toka/core/extensions/string_extensions.dart';

void main() {
  group('StringX.capitalized', () {
    test('capitalizes lowercase string', () {
      expect('hello'.capitalized, equals('Hello'));
    });

    test('leaves already-capitalized string unchanged', () {
      expect('Hello'.capitalized, equals('Hello'));
    });

    test('handles empty string', () {
      expect(''.capitalized, equals(''));
    });

    test('handles single character', () {
      expect('a'.capitalized, equals('A'));
    });
  });

  group('StringX.isValidEmail', () {
    test('accepts valid email', () {
      expect('user@example.com'.isValidEmail, isTrue);
    });

    test('accepts email with subdomain', () {
      expect('user@mail.example.com'.isValidEmail, isTrue);
    });

    test('accepts email with plus alias', () {
      expect('user+tag@example.com'.isValidEmail, isTrue);
    });

    test('rejects missing @', () {
      expect('userexample.com'.isValidEmail, isFalse);
    });

    test('rejects empty string', () {
      expect(''.isValidEmail, isFalse);
    });

    test('rejects leading dot in domain', () {
      expect('user@.example.com'.isValidEmail, isFalse);
    });

    test('rejects missing TLD', () {
      expect('user@example'.isValidEmail, isFalse);
    });

    test('rejects double @', () {
      expect('user@@example.com'.isValidEmail, isFalse);
    });
  });
}
