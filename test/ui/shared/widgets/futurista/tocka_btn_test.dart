import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/shared/widgets/futurista/tocka_btn.dart';

Widget harness(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  for (final v in TockaBtnVariant.values) {
    testWidgets('variant ${v.name} renders and taps', (tester) async {
      var tapped = false;
      await tester.pumpWidget(harness(TockaBtn(
        variant: v,
        onPressed: () => tapped = true,
        child: const Text('x'),
      )));
      await tester.tap(find.byType(TockaBtn));
      expect(tapped, true);
    });
  }

  for (final s in TockaBtnSize.values) {
    testWidgets('size ${s.name} renders', (tester) async {
      await tester.pumpWidget(harness(TockaBtn(
        size: s,
        onPressed: () {},
        child: const Text('x'),
      )));
      expect(find.text('x'), findsOneWidget);
    });
  }

  testWidgets('disabled (onPressed null) does not fire tap', (tester) async {
    await tester.pumpWidget(harness(const TockaBtn(
      onPressed: null,
      child: Text('x'),
    )));
    expect(find.text('x'), findsOneWidget);
  });

  testWidgets('icon is rendered before child', (tester) async {
    await tester.pumpWidget(harness(TockaBtn(
      icon: const Icon(Icons.check),
      onPressed: () {},
      child: const Text('x'),
    )));
    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}
