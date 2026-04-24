import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/shared/widgets/futurista/tocka_pill.dart';

Widget harness(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('renders child text', (tester) async {
    await tester.pumpWidget(harness(const TockaPill(child: Text('hello'))));
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('with color applies custom border and bg', (tester) async {
    await tester.pumpWidget(harness(const TockaPill(
      color: Color(0xFF38BDF8),
      child: Text('cyan'),
    )));
    final decorated = tester.widget<DecoratedBox>(find.byType(DecoratedBox).first);
    final dec = decorated.decoration as BoxDecoration;
    expect(dec.color, isNotNull);
    expect(dec.border, isNotNull);
  });

  testWidgets('with glow adds boxShadow', (tester) async {
    await tester.pumpWidget(harness(const TockaPill(
      color: Color(0xFF38BDF8),
      glow: true,
      child: Text('g'),
    )));
    final decorated = tester.widget<DecoratedBox>(find.byType(DecoratedBox).first);
    final dec = decorated.decoration as BoxDecoration;
    expect(dec.boxShadow, isNotNull);
    expect(dec.boxShadow!.length, greaterThan(0));
  });

  testWidgets('without color uses theme neutral', (tester) async {
    await tester.pumpWidget(harness(const TockaPill(child: Text('n'))));
    expect(find.text('n'), findsOneWidget);
  });
}
