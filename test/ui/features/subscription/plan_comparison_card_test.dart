// test/ui/features/subscription/plan_comparison_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/subscription/presentation/widgets/plan_comparison_card.dart';
import 'package:toka/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(width: 360, child: child),
        ),
      ),
    );

void main() {
  testWidgets('Pareja: muestra "Hasta 2 miembros"', (t) async {
    await t.pumpWidget(_wrap(const PlanComparisonCard(premiumMemberLimit: 2)));
    await t.pumpAndSettle();
    expect(find.text('Hasta 2 miembros'), findsOneWidget);
    expect(find.text('Hasta 10 miembros por hogar'), findsNothing);
  });

  testWidgets('Familia: muestra "Hasta 5 miembros"', (t) async {
    await t.pumpWidget(_wrap(const PlanComparisonCard(premiumMemberLimit: 5)));
    await t.pumpAndSettle();
    expect(find.text('Hasta 5 miembros'), findsOneWidget);
    expect(find.text('Hasta 10 miembros por hogar'), findsNothing);
  });

  testWidgets('Grupo: muestra "Hasta 10 miembros"', (t) async {
    await t.pumpWidget(_wrap(const PlanComparisonCard(premiumMemberLimit: 10)));
    await t.pumpAndSettle();
    expect(find.text('Hasta 10 miembros'), findsOneWidget);
    expect(find.text('Hasta 10 miembros por hogar'), findsNothing);
  });

  testWidgets('feature de anuncios es precisa (intersticial), no el genérico', (t) async {
    await t.pumpWidget(_wrap(const PlanComparisonCard(premiumMemberLimit: 5)));
    await t.pumpAndSettle();
    expect(find.text('Sin anuncios a pantalla completa'), findsOneWidget);
    expect(find.text('Sin publicidad'), findsNothing);
  });

  testWidgets('muestra la nota del banner (banner se quita por pagador / Plus)', (t) async {
    await t.pumpWidget(_wrap(const PlanComparisonCard(premiumMemberLimit: 5)));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('plan_comparison_ads_note')), findsOneWidget);
    expect(
      find.textContaining('El banner inferior se quita para quien paga'),
      findsOneWidget,
    );
  });

  testWidgets('golden: PlanComparisonCard Pareja (2)', (t) async {
    await t.pumpWidget(_wrap(const PlanComparisonCard(premiumMemberLimit: 2)));
    await t.pumpAndSettle();
    await expectLater(
      find.byKey(const Key('plan_comparison_card')),
      matchesGoldenFile('goldens/plan_comparison_card_2.png'),
    );
  });

  testWidgets('golden: PlanComparisonCard Familia (5)', (t) async {
    await t.pumpWidget(_wrap(const PlanComparisonCard(premiumMemberLimit: 5)));
    await t.pumpAndSettle();
    await expectLater(
      find.byKey(const Key('plan_comparison_card')),
      matchesGoldenFile('goldens/plan_comparison_card_5.png'),
    );
  });

  testWidgets('golden: PlanComparisonCard Grupo (10)', (t) async {
    await t.pumpWidget(_wrap(const PlanComparisonCard(premiumMemberLimit: 10)));
    await t.pumpAndSettle();
    await expectLater(
      find.byKey(const Key('plan_comparison_card')),
      matchesGoldenFile('goldens/plan_comparison_card_10.png'),
    );
  });
}
