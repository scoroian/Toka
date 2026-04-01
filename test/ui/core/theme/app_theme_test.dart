import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/core/theme/app_theme.dart';
import 'package:toka/core/theme/app_colors.dart';

void main() {
  group('AppTheme', () {
    testWidgets('light theme applies correct primary color to ElevatedButton', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) {
              final themeStyle = Theme.of(context).elevatedButtonTheme.style;
              final bgColor = themeStyle?.backgroundColor?.resolve({});
              expect(bgColor, equals(AppColors.primary));
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('Test'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();
    });

    testWidgets('light theme scaffold background is AppColors.background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) {
              final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
              expect(scaffoldBg, equals(AppColors.background));
              return const Scaffold(body: SizedBox());
            },
          ),
        ),
      );
      await tester.pump();
    });

    testWidgets('dark theme has Brightness.dark', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder: (context) {
              final brightness = Theme.of(context).colorScheme.brightness;
              expect(brightness, equals(Brightness.dark));
              return const Scaffold(body: SizedBox());
            },
          ),
        ),
      );
      await tester.pump();
    });

    testWidgets('useMaterial3 is true in light theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) {
              expect(Theme.of(context).useMaterial3, isTrue);
              return const Scaffold(body: SizedBox());
            },
          ),
        ),
      );
      await tester.pump();
    });
  });
}
