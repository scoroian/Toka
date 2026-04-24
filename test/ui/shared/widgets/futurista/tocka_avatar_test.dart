import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/shared/widgets/futurista/tocka_avatar.dart';

Widget harness(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('renders initials from full name', (tester) async {
    await tester.pumpWidget(harness(const TockaAvatar(
      name: 'Ana Soto',
      color: Color(0xFF38BDF8),
    )));
    expect(find.text('AS'), findsOneWidget);
  });

  testWidgets('single word -> single letter', (tester) async {
    await tester.pumpWidget(harness(const TockaAvatar(
      name: 'Ana',
      color: Color(0xFF38BDF8),
    )));
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('empty name -> question mark', (tester) async {
    await tester.pumpWidget(harness(const TockaAvatar(
      name: '',
      color: Color(0xFF38BDF8),
    )));
    expect(find.text('?'), findsOneWidget);
  });

  testWidgets('ring wraps with border container', (tester) async {
    await tester.pumpWidget(harness(const TockaAvatar(
      name: 'Ana',
      color: Color(0xFF38BDF8),
      ring: Color(0xFF38BDF8),
    )));
    expect(find.text('A'), findsOneWidget);
  });
}
