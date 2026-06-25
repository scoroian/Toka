import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/domain/recurrence_order.dart';

void main() {
  group('RecurrenceOrder.all', () {
    // 'oneTime' (Puntual) va primero a propósito: la pantalla Hoy itera sobre
    // esta lista para renderizar, y sin la entrada las tareas oneTime no se
    // pintaban nunca (ver RecurrenceOrder). El resto conserva el orden de spec
    // Hora → Día → Semana → Mes → Año.
    test('tiene exactamente 6 elementos (incluye oneTime)', () {
      expect(RecurrenceOrder.all.length, 6);
    });

    test('orden es oneTime, hourly, daily, weekly, monthly, yearly', () {
      expect(RecurrenceOrder.all, [
        'oneTime',
        'hourly',
        'daily',
        'weekly',
        'monthly',
        'yearly',
      ]);
    });
  });
}
