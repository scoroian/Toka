import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/support/application/support_providers.dart';
import 'package:toka/features/support/domain/home_diagnostics.dart';
import 'package:toka/features/support/presentation/support_diagnostics_screen.dart';
import 'package:toka/l10n/app_localizations.dart';

HomeDiagnostics _fakeDiagnostics() => const HomeDiagnostics(
      homeId: 'home-x',
      generatedAt: '2026-06-22T10:00:00.000Z',
      requestedBy: 'support-uid',
      home: DiagHome(
        name: 'Casa QA',
        premiumStatus: 'active',
        premiumPlan: 'yearly',
        premiumEndsAt: '2026-12-01T00:00:00.000Z',
        restoreUntil: null,
        ownerUid: 'owner-uid',
        currentPayerUid: 'owner-uid',
        timezone: 'Europe/Madrid',
        autoRenewEnabled: true,
      ),
      memberCount: 1,
      members: [
        DiagMember(
          uid: 'member-uid',
          nickname: 'Miembro QA',
          role: 'owner',
          status: 'active',
          billingState: 'currentPayer',
          tasksCompleted: 5,
          averageScore: 8.0,
          ratingsCount: 3,
          currentStreak: 2,
          phoneVisibility: 'hidden',
          hasPhone: true,
          hasFcmToken: false,
        ),
      ],
      upcomingTasks: [
        DiagTask(
          taskId: 't1',
          title: 'Fregar',
          status: 'active',
          nextDueAt: '2026-06-22T18:00:00.000Z',
          currentAssigneeUid: 'member-uid',
          recurrenceType: 'weekly',
        ),
      ],
      recentEvents: [
        DiagEvent(
          eventId: 'e1',
          eventType: 'completed',
          taskId: 't1',
          performerUid: 'member-uid',
          createdAt: '2026-06-21T18:00:00.000Z',
        ),
      ],
    );

Widget _wrap(List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('es')],
      home: SupportDiagnosticsScreen(),
    ),
  );
}

void main() {
  testWidgets('sin claim de soporte → muestra estado no autorizado', (tester) async {
    await tester.pumpWidget(_wrap([
      isSupportAgentProvider.overrideWith((ref) async => false),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('No tienes permiso de soporte.'), findsOneWidget);
    // No debe mostrar el campo de búsqueda.
    expect(find.byKey(const Key('support_homeid_field')), findsNothing);
  });

  testWidgets('con claim → diagnostica y renderiza datos redactados', (tester) async {
    // Viewport alto para que el ListView perezoso construya todas las tarjetas
    // (Home/Miembros/Tareas/Eventos) sin necesidad de scroll.
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap([
      isSupportAgentProvider.overrideWith((ref) async => true),
      homeDiagnosticsProvider('home-x')
          .overrideWith((ref) async => _fakeDiagnostics()),
    ]));
    await tester.pumpAndSettle();

    // Banner de privacidad siempre visible.
    expect(find.textContaining('Datos redactados'), findsOneWidget);

    // Buscar el hogar.
    await tester.enterText(find.byKey(const Key('support_homeid_field')), 'home-x');
    await tester.tap(find.byKey(const Key('support_diagnose_button')));
    await tester.pumpAndSettle();

    // Renderiza secciones y datos.
    expect(find.byKey(const Key('support_results_list')), findsOneWidget);
    expect(find.text('Casa QA'), findsOneWidget);
    expect(find.text('Miembro QA'), findsOneWidget);
    expect(find.text('Fregar'), findsOneWidget);

    // Chips de presencia (etiquetas), nunca valores.
    expect(find.text('Teléfono'), findsWidgets);
    expect(find.text('Push'), findsWidgets);
  });
}
