import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/shared/widgets/futurista/tocka_top_bar.dart';

Widget harness({required Widget child}) => ProviderScope(
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  testWidgets('renders home name and 3 avatars', (tester) async {
    await tester.pumpWidget(harness(
      child: const TockaTopBar(
        homeName: 'Piso Raval',
        members: [
          (name: 'Ana', color: Color(0xFF38BDF8)),
          (name: 'Marc', color: Color(0xFFA78BFA)),
          (name: 'Luna', color: Color(0xFFF472B6)),
        ],
      ),
    ));
    expect(find.text('Piso Raval'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('M'), findsOneWidget);
    expect(find.text('L'), findsOneWidget);
  });

  testWidgets('onHomeTap fires', (tester) async {
    var tapped = false;
    await tester.pumpWidget(harness(
      child: TockaTopBar(
        homeName: 'Piso',
        members: const [],
        onHomeTap: () => tapped = true,
      ),
    ));
    await tester.tap(find.text('Piso'));
    expect(tapped, true);
  });
}
