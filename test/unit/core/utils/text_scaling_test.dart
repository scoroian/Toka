import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/core/utils/text_scaling.dart';

// Accesibilidad (H-019): el textScaler del sistema se acota a [0.8, 1.3] en
// MaterialApp.builder. Aquí fijamos el contrato del clamp de forma aislada.
void main() {
  group('clampedTextScaler', () {
    test('un factor enorme (fuente XL/accesibilidad) se acota a 1.3', () {
      final scaler = clampedTextScaler(const TextScaler.linear(2.0));
      expect(scaler.scale(10), 13.0);
    });

    test('el máximo de Android "Lo más grande" (~1.3) se respeta tal cual', () {
      final scaler = clampedTextScaler(const TextScaler.linear(1.3));
      expect(scaler.scale(10), closeTo(13.0, 1e-9));
    });

    test('un factor intermedio dentro del rango no se altera', () {
      final scaler = clampedTextScaler(const TextScaler.linear(1.15));
      expect(scaler.scale(10), closeTo(11.5, 1e-9));
    });

    test('un factor minúsculo se acota a 0.8', () {
      final scaler = clampedTextScaler(const TextScaler.linear(0.5));
      expect(scaler.scale(10), 8.0);
    });

    test('factor 1.0 (por defecto) se mantiene', () {
      final scaler = clampedTextScaler(const TextScaler.linear(1.0));
      expect(scaler.scale(10), 10.0);
    });

    test('TextScaler.noScaling equivale a factor 1.0', () {
      final scaler = clampedTextScaler(TextScaler.noScaling);
      expect(scaler.scale(10), 10.0);
    });
  });
}
