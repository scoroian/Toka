import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/domain/pass_turn_logic.dart';

void main() {
  group('getNextEligibleMember (espejo del backend)', () {
    test('order vacío → devuelve currentUid (nada que rotar)', () {
      expect(getNextEligibleMember([], 'A', []), 'A');
    });

    test('un solo miembro → devuelve currentUid (sin candidato)', () {
      expect(getNextEligibleMember(['A'], 'A', []), 'A');
    });

    test('2 miembros sin frozen → alterna A → B', () {
      expect(getNextEligibleMember(['A', 'B'], 'A', []), 'B');
    });

    test('2 miembros sin frozen → alterna B → A', () {
      expect(getNextEligibleMember(['A', 'B'], 'B', []), 'A');
    });

    test('3 miembros: avanza al siguiente en el orden', () {
      expect(getNextEligibleMember(['A', 'B', 'C'], 'A', []), 'B');
      expect(getNextEligibleMember(['A', 'B', 'C'], 'C', []), 'A');
    });

    test('salta a un miembro congelado', () {
      expect(getNextEligibleMember(['A', 'B', 'C'], 'A', ['B']), 'C');
    });

    test('todos los demás frozen → devuelve currentUid', () {
      expect(getNextEligibleMember(['A', 'B', 'C'], 'A', ['B', 'C']), 'A');
    });

    test('currentUid fuera del order → empieza desde el índice 0', () {
      // indexOf devuelve -1; (−1+1)%2 = 0 → primer elegible.
      expect(getNextEligibleMember(['A', 'B'], 'Z', []), 'A');
    });
  });
}
