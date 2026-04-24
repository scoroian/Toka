import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/shared/widgets/futurista/task_glyph.dart';

void main() {
  testWidgets('all 10 kinds render without throwing', (tester) async {
    for (final kind in TaskGlyphKind.values) {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: TaskGlyph(kind: kind, color: const Color(0xFF38BDF8)),
          ),
        ),
      ));
      expect(find.byType(TaskGlyph), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    }
  });

  testWidgets('custom size propagates to CustomPaint', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: TaskGlyph(
            kind: TaskGlyphKind.ring,
            color: Color(0xFF38BDF8),
            size: 40,
          ),
        ),
      ),
    ));
    final widget = tester.widget<TaskGlyph>(find.byType(TaskGlyph));
    expect(widget.size, 40);
  });
}
