import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/shared/widgets/loading_widget.dart';
import 'package:toka/core/theme/app_colors.dart';

void main() {
  group('LoadingWidget', () {
    testWidgets('renders CircularProgressIndicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LoadingWidget())),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('is wrapped in a Center', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LoadingWidget())),
      );
      final center = tester.widget<Center>(
        find.ancestor(
          of: find.byType(CircularProgressIndicator),
          matching: find.byType(Center),
        ),
      );
      expect(center, isNotNull);
    });

    testWidgets('uses AppColors.primary as indicator color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LoadingWidget())),
      );
      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.color, equals(AppColors.primary));
    });
  });
}
