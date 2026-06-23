import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';
import 'package:toka/features/tasks/presentation/widgets/pass_turn_dialog.dart';
import 'package:toka/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      home: Scaffold(body: child),
    );

TaskPreview _task() => TaskPreview(
      taskId: 't1',
      title: 'Barrer',
      visualKind: 'emoji',
      visualValue: '🧹',
      recurrenceType: 'daily',
      currentAssigneeUid: 'uid1',
      currentAssigneeName: 'Ana',
      currentAssigneePhoto: null,
      nextDueAt: DateTime(2026, 4, 6, 18, 0),
      isOverdue: false,
      status: 'active',
    );

Future<void> _openDialog(
  WidgetTester tester, {
  double compliance = 0.87,
  double estimated = 0.81,
  String? nextName,
  void Function(String?)? onConfirm,
}) async {
  await tester.pumpWidget(_wrap(Builder(
    builder: (context) => ElevatedButton(
      onPressed: () => showDialog<void>(
        context: context,
        builder: (_) => PassTurnDialog(
          task: _task(),
          currentComplianceRate: compliance,
          estimatedComplianceAfter: estimated,
          nextAssigneeName: nextName,
          onConfirm: onConfirm ?? (_) {},
        ),
      ),
      child: const Text('open'),
    ),
  )));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra los dos valores de compliance cuando hay caída visible',
      (tester) async {
    await _openDialog(tester, compliance: 0.87, estimated: 0.81);

    expect(find.textContaining('87'), findsOneWidget);
    expect(find.textContaining('81'), findsOneWidget);
  });

  // Hallazgo #11(a): la penalización debe avisarse SIEMPRE (regla de producto
  // #7), también cuando un usuario consolidado pasa turno y la caída redondea a
  // 0 pp. Antes el umbral `diff >= 1%` la ocultaba (penalización silenciosa).
  testWidgets(
      'avisa de impacto mínimo cuando la caída redondea a 0 pp (consolidado)',
      (tester) async {
    // 1000 completadas, 0 pasadas → 100% → 1000/1001 ≈ 99.9% → ambos redondean
    // a 100%, pero la penalización (passedCount++) se aplica igual.
    await _openDialog(tester, compliance: 1.0, estimated: 1000 / 1001);

    expect(
      find.text('El impacto en tu cumplimiento será mínimo.'),
      findsOneWidget,
    );
    // No debe mostrar un delta numérico engañoso "100% → 100%".
    expect(find.textContaining('bajará'), findsNothing);
  });

  // El escenario exacto del bug: 100 completadas → 100% → ~99.0%. Antes el diff
  // sin redondear (0.99) caía por debajo del umbral y NO se avisaba; ahora la
  // caída redondeada (100→99) SÍ es perceptible y se muestra.
  testWidgets('avisa con números cuando la caída redondeada es 1 pp',
      (tester) async {
    await _openDialog(tester, compliance: 1.0, estimated: 100 / 101);

    expect(find.textContaining('bajará'), findsOneWidget);
    expect(find.textContaining('100'), findsOneWidget);
    expect(find.textContaining('99'), findsOneWidget);
  });

  testWidgets('muestra banner con números cuando hay caída clara',
      (tester) async {
    await _openDialog(tester, compliance: 0.90, estimated: 0.80);

    expect(find.textContaining('90'), findsOneWidget);
    expect(find.textContaining('80'), findsOneWidget);
  });

  testWidgets('muestra nombre del siguiente responsable', (tester) async {
    await _openDialog(tester, nextName: 'Carlos');

    expect(find.textContaining('Carlos'), findsOneWidget);
  });

  testWidgets('muestra mensaje sin candidato cuando nextName es null',
      (tester) async {
    await _openDialog(tester, nextName: null);

    expect(
      find.text(
          'No hay otro miembro disponible, seguirás siendo el responsable'),
      findsOneWidget,
    );
  });

  testWidgets('campo de motivo es opcional y visible', (tester) async {
    await _openDialog(tester);

    expect(find.byKey(const Key('field_pass_reason')), findsOneWidget);
  });

  testWidgets('botón Pasar turno dispara confirmación con reason',
      (tester) async {
    String? capturedReason;
    await _openDialog(tester, onConfirm: (r) => capturedReason = r);

    await tester.enterText(
      find.byKey(const Key('field_pass_reason')),
      'Me voy de viaje',
    );
    await tester.tap(find.byKey(const Key('btn_confirm_pass')));
    await tester.pumpAndSettle();

    expect(capturedReason, 'Me voy de viaje');
  });

  testWidgets('golden: diálogo pasar turno con next assignee', (tester) async {
    await _openDialog(tester,
        compliance: 0.87, estimated: 0.81, nextName: 'Carlos');

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/pass_turn_dialog.png'),
    );
  });

  testWidgets('golden: aviso de penalización con delta pequeño (consolidado)',
      (tester) async {
    await _openDialog(tester,
        compliance: 1.0, estimated: 1000 / 1001, nextName: 'Carlos');

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/pass_turn_dialog_minimal.png'),
    );
  });
}
