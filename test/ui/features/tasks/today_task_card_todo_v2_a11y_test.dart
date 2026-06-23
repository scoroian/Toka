import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/profile/application/profile_provider.dart';
import 'package:toka/features/profile/domain/user_profile.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';
import 'package:toka/features/tasks/presentation/skins/widgets/today_task_card_todo_v2.dart';
import 'package:toka/l10n/app_localizations.dart';

// Accesibilidad (H-019) de la card "Por hacer" de Hoy (la skin viva v2):
//  - Los botones Hecho/Pasar deben anunciarse como BOTÓN con etiqueta (antes
//    eran GestureDetector y el lector leía los glifos ✓/↻, no "botón").
//  - Con fuente grande (textScaler 1.3, el máximo tras el clamp) y textos
//    largos, la card NO debe desbordar.

Widget _wrap(
  Widget child, {
  TextScaler textScaler = TextScaler.noScaling,
  double width = 411, // ancho típico de móvil en px lógicos
}) =>
    ProviderScope(
      overrides: [
        for (final uid in const ['me', 'other'])
          userProfileProvider(uid)
              .overrideWith((ref) => const Stream<UserProfile>.empty()),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es')],
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: width,
                  child: SingleChildScrollView(child: child),
                ),
              ),
            ),
          ),
        ),
      ),
    );

TaskPreview _ownTask({
  String title = 'Barrer la cocina',
  String? assigneeName = 'Ana',
}) =>
    TaskPreview(
      taskId: 't1',
      title: title,
      visualKind: 'emoji',
      visualValue: '🧹',
      recurrenceType: 'daily',
      currentAssigneeUid: 'me',
      currentAssigneeName: assigneeName,
      currentAssigneePhoto: null,
      nextDueAt: DateTime(2026, 4, 6, 18, 0),
      isOverdue: false,
      isDueToday: true,
      status: 'active',
    );

void main() {
  group('semántica de los botones críticos', () {
    testWidgets('"Hecho" se expone como botón con etiqueta, sin el glifo ✓',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(TodayTaskCardTodoV2(
        task: _ownTask(),
        currentUid: 'me',
        now: DateTime(2026, 4, 6, 10, 0),
      )));
      await tester.pump();

      final l10n =
          AppLocalizations.of(tester.element(find.byKey(const Key('btn_done'))));
      final sem = tester
          .getSemantics(find.byKey(const Key('btn_done')))
          .getSemanticsData();

      expect(sem.flagsCollection.isButton, isTrue,
          reason: 'Hecho debe anunciarse como botón');
      expect(sem.label, l10n.today_btn_done);
      expect(sem.label.contains('✓'), isFalse,
          reason: 'el glifo ✓ no debe leerse');
      expect(sem.hasAction(SemanticsAction.tap), isTrue);
      handle.dispose();
    });

    testWidgets('"Pasar" se expone como botón con etiqueta, sin el glifo ↻',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(TodayTaskCardTodoV2(
        task: _ownTask(),
        currentUid: 'me',
        onPass: () {},
        now: DateTime(2026, 4, 6, 10, 0),
      )));
      await tester.pump();

      final l10n =
          AppLocalizations.of(tester.element(find.byKey(const Key('btn_pass'))));
      final sem = tester
          .getSemantics(find.byKey(const Key('btn_pass')))
          .getSemanticsData();

      expect(sem.flagsCollection.isButton, isTrue,
          reason: 'Pasar debe anunciarse como botón');
      expect(sem.label, l10n.today_btn_pass);
      expect(sem.label.contains('↻'), isFalse,
          reason: 'el glifo ↻ no debe leerse');
      expect(sem.hasAction(SemanticsAction.tap), isTrue);
      handle.dispose();
    });
  });

  group('sin overflow con fuente grande y textos largos', () {
    const longTitle =
        'Limpiar a fondo el horno, la campana extractora y los azulejos de la cocina';
    const longName = 'María José de la Inmaculada Concepción del Sagrado Corazón';

    testWidgets('card propia con título y nombre largos a textScaler 1.3',
        (tester) async {
      await tester.pumpWidget(_wrap(
        TodayTaskCardTodoV2(
          task: _ownTask(title: longTitle, assigneeName: longName),
          currentUid: 'me',
          onPass: () {},
          now: DateTime(2026, 4, 6, 10, 0),
        ),
        textScaler: const TextScaler.linear(1.3),
      ));
      await tester.pump();

      expect(tester.takeException(), isNull,
          reason: 'no debe haber RenderFlex overflow');
      // El título sigue presente (elipsado, pero el widget conserva el texto).
      expect(find.text(longTitle), findsOneWidget);
    });

    testWidgets('card de otro responsable (sin botones) con textos largos a 1.3',
        (tester) async {
      final task = TaskPreview(
        taskId: 't2',
        title: longTitle,
        visualKind: 'emoji',
        visualValue: '🧹',
        recurrenceType: 'daily',
        currentAssigneeUid: 'other',
        currentAssigneeName: longName,
        currentAssigneePhoto: null,
        nextDueAt: DateTime(2026, 4, 6, 18, 0),
        isOverdue: true,
        isDueToday: false,
        status: 'active',
      );
      await tester.pumpWidget(_wrap(
        TodayTaskCardTodoV2(
          task: task,
          currentUid: 'me',
          now: DateTime(2026, 4, 6, 10, 0),
        ),
        textScaler: const TextScaler.linear(1.3),
      ));
      await tester.pump();

      expect(tester.takeException(), isNull,
          reason: 'no debe haber RenderFlex overflow');
    });
  });

  group('golden', () {
    testWidgets('card v2 con botones a textScaler 1.3 y textos largos',
        (tester) async {
      await tester.pumpWidget(_wrap(
        TodayTaskCardTodoV2(
          task: _ownTask(
            title: 'Limpiar a fondo el horno y la campana extractora',
            assigneeName: 'María José de la Concepción',
          ),
          currentUid: 'me',
          onPass: () {},
          now: DateTime(2026, 4, 6, 10, 0),
        ),
        textScaler: const TextScaler.linear(1.3),
      ));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/today_card_todo_v2_xl_long.png'),
      );
    });
  });
}
