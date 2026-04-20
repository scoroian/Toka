// test/ui/features/profile/radar_chart_widget_test.dart
import 'package:fl_chart/fl_chart.dart' show RadarChart;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/profile/presentation/widgets/radar_chart_widget.dart';
import 'package:toka/features/profile/presentation/widgets/strengths_list_widget.dart';
import 'package:toka/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
      home: Scaffold(body: child),
    );

void main() {
  group('RadarChartWidget', () {
    test('con 15 tareas solo muestra 10 en el radar', () {
      final data = List.generate(
        15,
        (i) => RadarEntry(taskName: 'Tarea $i', avgScore: 7.0 + i * 0.1),
      );
      final radarEntries = data.take(10).toList();
      final overflowEntries = data.skip(10).toList();
      expect(radarEntries.length, 10);
      expect(overflowEntries.length, 5);
    });

    testWidgets('RadarChartWidget con 3 tareas muestra RadarChart', (t) async {
      final data = [
        RadarEntry(taskName: 'Fregar', avgScore: 8.0),
        RadarEntry(taskName: 'Barrer', avgScore: 6.5),
        RadarEntry(taskName: 'Cocinar', avgScore: 9.0),
      ];
      await t.pumpWidget(_wrap(RadarChartWidget(entries: data)));
      await t.pumpAndSettle();
      expect(find.byType(RadarChart), findsOneWidget);
    });

    testWidgets('RadarChartWidget con 0 tareas muestra mensaje vacío', (t) async {
      await t.pumpWidget(_wrap(const RadarChartWidget(entries: [])));
      await t.pumpAndSettle();
      expect(find.byType(RadarChart), findsNothing);
      expect(find.byKey(const Key('radar_no_data')), findsOneWidget);
    });

    testWidgets('RadarChartWidget con 1 tarea muestra fallback de texto', (t) async {
      const data = [RadarEntry(taskName: 'Barrer', avgScore: 5.0)];
      await t.pumpWidget(_wrap(const RadarChartWidget(entries: data)));
      await t.pumpAndSettle();
      expect(find.byType(RadarChart), findsNothing);
      expect(find.byKey(const Key('radar_no_data')), findsNothing);
      expect(find.byKey(const Key('radar_text_fallback')), findsOneWidget);
      expect(find.text('Barrer'), findsOneWidget);
      expect(find.text('5.0'), findsOneWidget);
    });

    testWidgets('RadarChartWidget con 2 tareas muestra fallback de texto', (t) async {
      const data = [
        RadarEntry(taskName: 'Barrer', avgScore: 5.0),
        RadarEntry(taskName: 'Fregar', avgScore: 9.0),
      ];
      await t.pumpWidget(_wrap(const RadarChartWidget(entries: data)));
      await t.pumpAndSettle();
      expect(find.byType(RadarChart), findsNothing);
      expect(find.byKey(const Key('radar_text_fallback')), findsOneWidget);
      expect(find.text('Barrer'), findsOneWidget);
      expect(find.text('Fregar'), findsOneWidget);
    });

    testWidgets('RadarChartWidget con 12 tareas muestra 10 en chart + StrengthsListWidget', (t) async {
      final data = List.generate(
        12,
        (i) => RadarEntry(taskName: 'Tarea $i', avgScore: 5.0 + i * 0.3),
      );
      await t.pumpWidget(_wrap(RadarChartWidget(entries: data)));
      await t.pumpAndSettle();
      expect(find.byType(RadarChart), findsOneWidget);
      expect(find.byType(StrengthsListWidget), findsOneWidget);
    });

    testWidgets('golden: RadarChartWidget con 5 tareas', (t) async {
      final data = [
        RadarEntry(taskName: 'Fregar', avgScore: 8.0),
        RadarEntry(taskName: 'Barrer', avgScore: 6.5),
        RadarEntry(taskName: 'Cocinar', avgScore: 9.0),
        RadarEntry(taskName: 'Compras', avgScore: 7.5),
        RadarEntry(taskName: 'Baño', avgScore: 8.5),
      ];
      await t.pumpWidget(_wrap(RadarChartWidget(entries: data)));
      await t.pumpAndSettle();
      await expectLater(
        find.byType(RadarChartWidget),
        matchesGoldenFile('goldens/radar_chart.png'),
      );
    });
  });
}
