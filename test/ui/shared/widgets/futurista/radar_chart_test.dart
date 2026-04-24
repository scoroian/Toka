import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/shared/widgets/futurista/radar_chart.dart';

Widget harness(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('renders with 8 axes', (tester) async {
    await tester.pumpWidget(harness(RadarChart(
      values: const [0.9, 0.7, 0.85, 0.6, 0.95, 0.75, 0.8, 0.88],
      labels: const ['Cocina', 'Baño', 'Ropa', 'Salón',
               'Compra', 'Plantas', 'Basura', 'Orden'],
    )));
    expect(find.byType(RadarChart), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('renders with 3 axes (minimum)', (tester) async {
    await tester.pumpWidget(harness(RadarChart(
      values: const [0.5, 0.7, 0.9],
      labels: const ['A', 'B', 'C'],
    )));
    expect(find.byType(RadarChart), findsOneWidget);
  });

  testWidgets('clamps values >1 and <0 silently', (tester) async {
    await tester.pumpWidget(harness(RadarChart(
      values: const [1.5, -0.2, 0.5],
      labels: const ['A', 'B', 'C'],
    )));
    expect(find.byType(RadarChart), findsOneWidget);
  });

  test('asserts values.length == labels.length in debug', () {
    expect(
      () => RadarChart(values: const [0.5], labels: const ['A', 'B']),
      throwsAssertionError,
    );
  });

  test('asserts axes count between 3 and 12', () {
    expect(
      () => RadarChart(values: const [0.5, 0.5], labels: const ['A', 'B']),
      throwsAssertionError,
    );
  });
}
