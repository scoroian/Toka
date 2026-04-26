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

  testWidgets('mine + actionable shows [Hecho][Pasar] row, fires onComplete and onPass',
      (tester) async {
    var completed = false;
    var passed = false;
    await tester.pumpWidget(harness(TaskCardFuturista(
      title: 't',
      assignee: 'A',
      assigneeColor: const Color(0xFF38BDF8),
      mine: true,
      actionable: true,
      onComplete: () => completed = true,
      onPass: () => passed = true,
    )));
    final doneBtn = find.byKey(const Key('task_card_done_btn'));
    final passBtn = find.byKey(const Key('task_card_pass_btn'));
    expect(doneBtn, findsOneWidget);
    expect(passBtn, findsOneWidget);
    await tester.tap(doneBtn);
    expect(completed, true);
    await tester.tap(passBtn);
    expect(passed, true);
  });

  testWidgets('mine + NOT actionable: tap done fires onActionableHint, not onComplete',
      (tester) async {
    var completed = false;
    var hinted = false;
    await tester.pumpWidget(harness(TaskCardFuturista(
      title: 't',
      assignee: 'A',
      assigneeColor: const Color(0xFF38BDF8),
      mine: true,
      actionable: false,
      onComplete: () => completed = true,
      onActionableHint: () => hinted = true,
    )));
    expect(find.byIcon(Icons.lock_clock), findsOneWidget);
    await tester.tap(find.byKey(const Key('task_card_done_btn')));
    expect(completed, false);
    expect(hinted, true);
  });

  testWidgets('mine + done hides buttons row and applies strikethrough',
      (tester) async {
    await tester.pumpWidget(harness(const TaskCardFuturista(
      title: 't',
      assignee: 'A',
      assigneeColor: Color(0xFF38BDF8),
      mine: true,
      done: true,
    )));
    expect(find.byKey(const Key('task_card_done_btn')), findsNothing);
    expect(find.byKey(const Key('task_card_pass_btn')), findsNothing);
    final titleText = tester.widget<Text>(find.text('t'));
    expect(titleText.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('!mine shows lock icon in right slot, no buttons row',
      (tester) async {
    await tester.pumpWidget(harness(const TaskCardFuturista(
      title: 't',
      assignee: 'A',
      assigneeColor: Color(0xFF38BDF8),
    )));
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.byKey(const Key('task_card_done_btn')), findsNothing);
    expect(find.byKey(const Key('task_card_pass_btn')), findsNothing);
  });

  testWidgets('onTap fires when card body tapped', (tester) async {
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
