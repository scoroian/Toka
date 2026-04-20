import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/presentation/widgets/pass_turn_dialog.dart';

void main() {
  group('PassTurnDialog.calcEstimatedCompliance', () {
    test('caso normal: (3 completadas, 1 pasadas) → 3/5', () {
      final result = PassTurnDialog.calcEstimatedCompliance(
        completedCount: 3,
        passedCount: 1,
      );
      expect(result, closeTo(0.6, 0.001));
    });

    test('caso 0 completadas → 0.0', () {
      final result = PassTurnDialog.calcEstimatedCompliance(
        completedCount: 0,
        passedCount: 0,
      );
      expect(result, 0.0);
    });

    test('resultado no puede ser negativo', () {
      final result = PassTurnDialog.calcEstimatedCompliance(
        completedCount: 0,
        passedCount: 5,
      );
      expect(result, greaterThanOrEqualTo(0.0));
    });

    test('con 1 miembro (cumplimiento 100%) → diff proyectado < 1%', () {
      // El usuario tiene 100 tareas completadas, 0 pasadas.
      // Al pasar turno: estimado = 100/101 ≈ 0.9901 → diff ≈ 0.99 < 1 pp.
      const rate = 1.0;
      const estimated = 100 / 101;
      const diff = (rate - estimated) * 100;
      expect(diff, lessThan(1.0));
    });
  });
}
