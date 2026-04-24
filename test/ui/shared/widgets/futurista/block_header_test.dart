import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/shared/widgets/futurista/block_header.dart';

Widget harness(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('uppercases label', (tester) async {
    await tester.pumpWidget(harness(const BlockHeader(label: 'hoy · hora')));
    expect(find.text('HOY · HORA'), findsOneWidget);
  });

  testWidgets('with count renders zero-padded', (tester) async {
    await tester.pumpWidget(harness(const BlockHeader(
      label: 'hoy', count: 3,
    )));
    expect(find.text('03'), findsOneWidget);
  });

  testWidgets('without count renders only label', (tester) async {
    await tester.pumpWidget(harness(const BlockHeader(label: 'hoy')));
    expect(find.text('HOY'), findsOneWidget);
  });
}
