import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/shared/widgets/futurista/task_card_futurista.dart';
import 'package:toka/shared/widgets/futurista/task_glyph.dart';

Widget harness(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders title and assignee', (tester) async {
    await tester.pumpWidget(harness(const TaskCardFuturista(
      title: 'Sacar basura',
      assignee: 'Ana',
      assigneeColor: Color(0xFF38BDF8),
      when: 'vence 11:30',
      glyph: TaskGlyphKind.ring,
    )));
    expect(find.text('Sacar basura'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('· vence 11:30'), findsOneWidget);
  });

  testWidgets('mine & !done shows check button and fires onComplete',
      (tester) async {
    var completed = false;
    await tester.pumpWidget(harness(TaskCardFuturista(
      title: 't',
      assignee: 'A',
      assigneeColor: const Color(0xFF38BDF8),
      mine: true,
      onComplete: () => completed = true,
    )));
    final checkBtn = find.byIcon(Icons.check);
    expect(checkBtn, findsOneWidget);
    await tester.tap(checkBtn);
    expect(completed, true);
  });

  testWidgets('done hides right slot and adds strikethrough', (tester) async {
    await tester.pumpWidget(harness(const TaskCardFuturista(
      title: 't',
      assignee: 'A',
      assigneeColor: Color(0xFF38BDF8),
      done: true,
    )));
    expect(find.byIcon(Icons.lock_outline), findsNothing);
    final titleText = tester.widget<Text>(find.text('t'));
    expect(titleText.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('!mine & !done shows lock icon', (tester) async {
    await tester.pumpWidget(harness(const TaskCardFuturista(
      title: 't',
      assignee: 'A',
      assigneeColor: Color(0xFF38BDF8),
    )));
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });

  testWidgets('onTap fires when card tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(harness(TaskCardFuturista(
      title: 't',
      assignee: 'A',
      assigneeColor: const Color(0xFF38BDF8),
      onTap: () => tapped = true,
    )));
    await tester.tap(find.byType(TaskCardFuturista));
    expect(tapped, true);
  });
}
