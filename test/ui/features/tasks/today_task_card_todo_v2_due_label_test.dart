import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';
import 'package:toka/features/tasks/presentation/skins/widgets/today_task_card_todo_v2.dart';
import 'package:toka/l10n/app_localizations.dart';

// La etiqueta "Hoy" del tile la decide la clasificación del backend
// (`isDueToday`, zona del hogar), NO un recálculo en la zona del dispositivo.
// Así el contador `tasksDueToday` y las etiquetas de los tiles siempre cuadran,
// incluso si el dispositivo está en otra zona (p. ej. emulador GMT vs hogar
// Madrid). Estos tests fijan ese contrato.

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es')],
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

TaskPreview _task({
  required bool isDueToday,
  required bool isOverdue,
  required DateTime nextDueAt,
}) =>
    TaskPreview(
      taskId: 't1',
      title: 'Barrer la cocina',
      visualKind: 'emoji',
      visualValue: '🧹',
      recurrenceType: 'daily',
      // Sin responsable → el tile no consulta userProfileProvider (sin Firebase).
      currentAssigneeUid: null,
      currentAssigneeName: null,
      currentAssigneePhoto: null,
      nextDueAt: nextDueAt,
      isOverdue: isOverdue,
      isDueToday: isDueToday,
      status: 'active',
    );

void main() {
  testWidgets(
      'muestra "Hoy" cuando isDueToday=true aunque el día del dispositivo sea mañana',
      (tester) async {
    // now = 6 abr 10:00; nextDueAt = 7 abr 09:00 → en zona del dispositivo es
    // MAÑANA, pero el backend lo marcó isDueToday=true (zona del hogar).
    await tester.pumpWidget(_wrap(TodayTaskCardTodoV2(
      task: _task(
        isDueToday: true,
        isOverdue: false,
        nextDueAt: DateTime(2026, 4, 7, 9, 0),
      ),
      currentUid: 'someone-else',
      now: DateTime(2026, 4, 6, 10, 0),
    )));
    await tester.pump();

    expect(find.textContaining('Hoy'), findsOneWidget);
  });

  testWidgets(
      'NO muestra "Hoy" cuando isDueToday=false aunque el día del dispositivo sea hoy',
      (tester) async {
    // now = 6 abr 10:00; nextDueAt = 6 abr 18:00 → en zona del dispositivo es
    // HOY, pero el backend lo marcó isDueToday=false (en la zona del hogar ya es
    // mañana). El tile debe seguir al backend y NO decir "Hoy".
    await tester.pumpWidget(_wrap(TodayTaskCardTodoV2(
      task: _task(
        isDueToday: false,
        isOverdue: false,
        nextDueAt: DateTime(2026, 4, 6, 18, 0),
      ),
      currentUid: 'someone-else',
      now: DateTime(2026, 4, 6, 10, 0),
    )));
    await tester.pump();

    expect(find.textContaining('Hoy'), findsNothing);
  });

  testWidgets('una tarea vencida muestra "Vencida", no "Hoy"', (tester) async {
    await tester.pumpWidget(_wrap(TodayTaskCardTodoV2(
      task: _task(
        isDueToday: false,
        isOverdue: true,
        nextDueAt: DateTime(2026, 4, 5, 9, 0),
      ),
      currentUid: 'someone-else',
      now: DateTime(2026, 4, 6, 10, 0),
    )));
    await tester.pump();

    expect(find.text('Vencida'), findsOneWidget);
    expect(find.textContaining('Hoy'), findsNothing);
  });
}
