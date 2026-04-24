import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/shared/widgets/futurista/tocka_ring.dart';

Widget harness(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('value 0 renders without progress arc', (tester) async {
    await tester.pumpWidget(harness(const TockaRing(value: 0)));
    expect(find.byType(TockaRing), findsOneWidget);
  });

  testWidgets('value 0.5 renders arc', (tester) async {
    await tester.pumpWidget(harness(const TockaRing(value: 0.5)));
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('value 1 renders full ring', (tester) async {
    await tester.pumpWidget(harness(const TockaRing(value: 1)));
    expect(find.byType(TockaRing), findsOneWidget);
  });

  testWidgets('child is centered above ring', (tester) async {
    await tester.pumpWidget(harness(const TockaRing(
      value: 0.5,
      child: Text('82%'),
    )));
    expect(find.text('82%'), findsOneWidget);
  });
}
