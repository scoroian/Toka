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
  testWidgets('muestra los dos valores de compliance', (tester) async {
    await _openDialog(tester, compliance: 0.87, estimated: 0.81);

    expect(find.textContaining('87'), findsOneWidget);
    expect(find.textContaining('81'), findsOneWidget);
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
}
