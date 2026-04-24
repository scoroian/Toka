import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/shared/widgets/futurista/tocka_chip.dart';

Widget harness(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('active chip renders', (tester) async {
    await tester.pumpWidget(harness(const TockaChip(active: true, child: Text('A'))));
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('inactive chip renders', (tester) async {
    await tester.pumpWidget(harness(const TockaChip(child: Text('B'))));
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('tap invokes callback', (tester) async {
    var tapped = false;
    await tester.pumpWidget(harness(TockaChip(
      onTap: () => tapped = true,
      child: const Text('C'),
    )));
    await tester.tap(find.byType(TockaChip));
    expect(tapped, true);
  });
}
