import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/shared/widgets/skins/shell_presence_marker.dart';

void main() {
  testWidgets('of(context) returns true under marker', (tester) async {
    bool? observed;
    await tester.pumpWidget(MaterialApp(
      home: ShellPresenceMarker(
        child: Builder(builder: (ctx) {
          observed = ShellPresenceMarker.of(ctx);
          return const SizedBox();
        }),
      ),
    ));
    expect(observed, isTrue);
  });

  testWidgets('of(context) returns false without marker', (tester) async {
    bool? observed;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (ctx) {
        observed = ShellPresenceMarker.of(ctx);
        return const SizedBox();
      }),
    ));
    expect(observed, isFalse);
  });

  testWidgets('of(context) propagates through nested widgets', (tester) async {
    bool? observed;
    await tester.pumpWidget(MaterialApp(
      home: ShellPresenceMarker(
        child: Scaffold(
          body: Container(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Builder(builder: (ctx) {
                observed = ShellPresenceMarker.of(ctx);
                return const SizedBox();
              }),
            ),
          ),
        ),
      ),
    ));
    expect(observed, isTrue);
  });
}
