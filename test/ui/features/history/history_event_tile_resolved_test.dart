// test/ui/features/history/history_event_tile_resolved_test.dart
//
// Regresión BUG-19: los tiles de historial deben mostrar nombres resueltos de
// miembros, nunca UIDs crudos. Cubre CompletedEvent, PassedEvent y MissedEvent.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/history/domain/task_event.dart';
import 'package:toka/features/history/presentation/widgets/history_event_tile.dart';
import 'package:toka/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
      home: Scaffold(body: child),
    );

void main() {
  group('HistoryEventTile — render sin UIDs crudos', () {
    final completed = TaskEvent.completed(
      id: 'e1',
      taskId: 't1',
      taskTitleSnapshot: 'Fregar',
      taskVisualSnapshot: const TaskVisual(kind: 'emoji', value: '🧹'),
      actorUid: 'uid_actor',
      performerUid: 'uid_actor',
      completedAt: DateTime(2026, 4, 20, 10),
      createdAt: DateTime(2026, 4, 20, 10),
    );

    final passed = TaskEvent.passed(
      id: 'e2',
      taskId: 't1',
      taskTitleSnapshot: 'Barrer',
      taskVisualSnapshot: const TaskVisual(kind: 'emoji', value: '🧹'),
      actorUid: 'uid_actor',
      fromUid: 'uid_actor',
      toUid: 'uid_other',
      penaltyApplied: false,
      complianceBefore: null,
      complianceAfter: null,
      createdAt: DateTime(2026, 4, 20, 11),
    );

    final missed = TaskEvent.missed(
      id: 'e3',
      taskId: 't1',
      taskTitleSnapshot: 'Aspirar',
      taskVisualSnapshot: const TaskVisual(kind: 'emoji', value: '🧹'),
      actorUid: 'uid_actor',
      toUid: 'uid_other',
      penaltyApplied: true,
      missedAt: DateTime(2026, 4, 20, 12),
      createdAt: DateTime(2026, 4, 20, 12),
    );

    testWidgets('CompletedEvent muestra alias, no UID', (tester) async {
      await tester.pumpWidget(_wrap(HistoryEventTile(
        event: completed,
        actorName: 'Ana',
        actorPhotoUrl: null,
      )));
      expect(find.textContaining('Ana'), findsWidgets);
      expect(find.textContaining('uid_actor'), findsNothing);
    });

    testWidgets('PassedEvent muestra alias de from y to, no UID', (tester) async {
      await tester.pumpWidget(_wrap(HistoryEventTile(
        event: passed,
        actorName: 'Ana',
        toName: 'Luis',
        actorPhotoUrl: null,
      )));
      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('Luis'), findsOneWidget);
      expect(find.textContaining('uid_actor'), findsNothing);
      expect(find.textContaining('uid_other'), findsNothing);
    });

    testWidgets('MissedEvent: copy neutro centrado en la tarea, sin nombre',
        (tester) async {
      await tester.pumpWidget(_wrap(HistoryEventTile(
        event: missed,
        actorName: 'Ana',
        actorPhotoUrl: null,
      )));
      // Encuadre neutro: estado de la tarea, no de la persona.
      expect(find.text('Tarea vencida'), findsOneWidget);
      // Ya no señala a nadie por nombre, ni expone el UID.
      expect(find.textContaining('Ana'), findsNothing);
      expect(find.textContaining('uid_actor'), findsNothing);
      // La tarea sigue identificándose en el subtítulo.
      expect(find.textContaining('Aspirar'), findsOneWidget);
    });

    testWidgets('PassedEvent sin toName muestra placeholder, nunca el UID',
        (tester) async {
      await tester.pumpWidget(_wrap(HistoryEventTile(
        event: passed,
        actorName: 'Ana',
        actorPhotoUrl: null,
        // toName intencionadamente null (simulando desconocido): el tile
        // cae al placeholder '?' en lugar de exponer el UID.
      )));
      expect(find.textContaining('uid_other'), findsNothing);
    });

    testWidgets('MissedEvent: leading neutro (sin avatar de persona) y sin alarma',
        (tester) async {
      await tester.pumpWidget(_wrap(HistoryEventTile(
        event: missed,
        actorName: 'Ana',
        actorPhotoUrl: null,
      )));

      // No hay avatar de persona: no aparece su inicial 'A'.
      expect(find.text('A'), findsNothing);
      // Leading despersonalizado: icono neutro centrado en la tarea.
      expect(find.byIcon(Icons.event_busy_outlined), findsOneWidget);
      // Ningún icono usa color de alarma naranja.
      final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
      expect(icons.any((i) => i.color == Colors.orange), isFalse);
    });
  });

  group('HistoryEventTile — golden tile missed', () {
    final missedGolden = TaskEvent.missed(
      id: 'g1',
      taskId: 't1',
      taskTitleSnapshot: 'Aspirar',
      taskVisualSnapshot: const TaskVisual(kind: 'emoji', value: '🧹'),
      actorUid: 'uid_actor',
      toUid: 'uid_other',
      penaltyApplied: true,
      missedAt: DateTime(2026, 4, 20, 12),
      createdAt: DateTime(2026, 4, 20, 12),
    );

    testWidgets('golden: evento vencido reencuadrado (neutro, sin nombre)',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 360);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(HistoryEventTile(
        event: missedGolden,
        actorName: 'Ana',
        actorPhotoUrl: null,
      )));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/history_event_tile_missed.png'),
      );
    });
  });
}
