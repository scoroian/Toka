import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/shared/widgets/futurista/tocka_tab_bar.dart';

Widget harness(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  const items = [
    TockaTabBarItem(icon: Icons.home, label: 'Hoy'),
    TockaTabBarItem(icon: Icons.history, label: 'Historial'),
    TockaTabBarItem(icon: Icons.group, label: 'Miembros'),
    TockaTabBarItem(icon: Icons.check, label: 'Tareas'),
    TockaTabBarItem(icon: Icons.settings, label: 'Ajustes'),
  ];

  testWidgets('renders all items with labels', (tester) async {
    await tester.pumpWidget(harness(TockaTabBar(
      activeIndex: 0,
      items: items,
      onTap: (_) {},
    )));
    expect(find.text('Hoy'), findsOneWidget);
    expect(find.text('Historial'), findsOneWidget);
    expect(find.text('Miembros'), findsOneWidget);
    expect(find.text('Tareas'), findsOneWidget);
    expect(find.text('Ajustes'), findsOneWidget);
  });

  testWidgets('tap fires onTap with correct index', (tester) async {
    int? tappedIndex;
    await tester.pumpWidget(harness(TockaTabBar(
      activeIndex: 0,
      items: items,
      onTap: (i) => tappedIndex = i,
    )));
    await tester.tap(find.text('Tareas'));
    expect(tappedIndex, 3);
  });
}
