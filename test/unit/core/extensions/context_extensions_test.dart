import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/core/extensions/context_extensions.dart';

void main() {
  group('BuildContextX', () {
    testWidgets('theme returns correct ThemeData', (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(builder: (ctx) {
            capturedContext = ctx;
            return const SizedBox();
          }),
        ),
      );
      expect(capturedContext.theme, isA<ThemeData>());
    });

    testWidgets('colorScheme returns ColorScheme', (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (ctx) {
            capturedContext = ctx;
            return const SizedBox();
          }),
        ),
      );
      expect(capturedContext.colorScheme, isA<ColorScheme>());
    });

    testWidgets('screenWidth returns positive value', (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (ctx) {
            capturedContext = ctx;
            return const SizedBox();
          }),
        ),
      );
      expect(capturedContext.screenWidth, greaterThan(0));
    });

    testWidgets('screenHeight returns positive value', (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (ctx) {
            capturedContext = ctx;
            return const SizedBox();
          }),
        ),
      );
      expect(capturedContext.screenHeight, greaterThan(0));
    });
  });
}
