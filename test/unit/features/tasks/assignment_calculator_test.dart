import 'package:flutter_test/flutter_test.dart';
import 'package:toka/core/utils/assignment_calculator.dart';

void main() {
  group('AssignmentCalculator.getNextAssignee', () {
    test('lista de 3: después del 3º vuelve al 1º', () {
      final order = ['A', 'B', 'C'];
      expect(AssignmentCalculator.getNextAssignee(order, 'C', []), 'A');
    });

    test('lista de 3: después del 1º va al 2º', () {
      final order = ['A', 'B', 'C'];
      expect(AssignmentCalculator.getNextAssignee(order, 'A', []), 'B');
    });

    test('salta miembro congelado', () {
      final order = ['A', 'B', 'C'];
      expect(AssignmentCalculator.getNextAssignee(order, 'A', ['B']), 'C');
    });

    test('todos congelados excepto el actual: se asigna a sí mismo', () {
      final order = ['A', 'B', 'C'];
      expect(AssignmentCalculator.getNextAssignee(order, 'A', ['B', 'C']), 'A');
    });

    test('lista vacía: retorna null', () {
      expect(AssignmentCalculator.getNextAssignee([], 'A', []), isNull);
    });

    test('miembro no en la lista: retorna el primero elegible', () {
      final order = ['A', 'B', 'C'];
      // indexOf returns -1; (-1 + 1) % 3 = 0 → 'A'
      expect(AssignmentCalculator.getNextAssignee(order, 'Z', []), 'A');
    });
  });
}
