// test/ui/features/subscription/premium_feature_gate_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/subscription/application/subscription_provider.dart';
import 'package:toka/features/subscription/domain/subscription_state.dart';
import 'package:toka/features/subscription/presentation/widgets/premium_feature_gate.dart';
import 'package:toka/l10n/app_localizations.dart';

Widget _wrap(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es')],
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: child,
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('PremiumFeatureGate: en Free muestra overlay de upgrade',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const PremiumFeatureGate(
        requiresPremium: true,
        featureName: 'Distribución inteligente',
        child: Text('Contenido Premium'),
      ),
      overrides: [
        subscriptionStateProvider
            .overrideWith((_) => const SubscriptionState.free()),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('premium_gate_overlay')), findsOneWidget);
    expect(find.byKey(const Key('btn_upgrade')), findsOneWidget);
  });

  testWidgets('PremiumFeatureGate: en Premium muestra el child sin overlay',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const PremiumFeatureGate(
        requiresPremium: true,
        featureName: 'Distribución inteligente',
        child: Text('Contenido Premium'),
      ),
      overrides: [
        subscriptionStateProvider.overrideWith((_) => SubscriptionState.active(
              plan: 'monthly',
              endsAt: DateTime.now().add(const Duration(days: 30)),
              autoRenew: true,
            )),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('premium_gate_overlay')), findsNothing);
    expect(find.text('Contenido Premium'), findsOneWidget);
  });

  testWidgets('PremiumFeatureGate: requiresPremium=false siempre muestra child',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const PremiumFeatureGate(
        requiresPremium: false,
        featureName: 'Feature sin restricción',
        child: Text('Visible siempre'),
      ),
      overrides: [
        subscriptionStateProvider
            .overrideWith((_) => const SubscriptionState.free()),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Visible siempre'), findsOneWidget);
    expect(find.byKey(const Key('premium_gate_overlay')), findsNothing);
  });
}
