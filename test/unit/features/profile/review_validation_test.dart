// test/unit/features/profile/review_validation_test.dart
import 'package:flutter_test/flutter_test.dart';

// Simula las reglas de validación de submitReview en el lado cliente
bool isValidReviewScore(int score) => score >= 1 && score <= 10;
bool isValidReviewNote(String? note) => note == null || note.length <= 300;

void main() {
  group('Review validation rules', () {
    test('score válido: 1 a 10', () {
      expect(isValidReviewScore(1), true);
      expect(isValidReviewScore(10), true);
      expect(isValidReviewScore(5), true);
    });

    test('score inválido: 0 y 11', () {
      expect(isValidReviewScore(0), false);
      expect(isValidReviewScore(11), false);
    });

    test('nota nula es válida', () {
      expect(isValidReviewNote(null), true);
    });

    test('nota de 300 caracteres es válida', () {
      expect(isValidReviewNote('a' * 300), true);
    });

    test('nota de 301 caracteres es inválida', () {
      expect(isValidReviewNote('a' * 301), false);
    });

    test('score negativo es inválido', () {
      expect(isValidReviewScore(-1), false);
    });

    test('nota vacía es válida', () {
      expect(isValidReviewNote(''), true);
    });
  });
}
