import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/settings/presentation/settings_screen.dart';
import 'package:toka/features/subscription/application/subscription_provider.dart';
import 'package:toka/features/subscription/domain/subscription_state.dart';
import 'package:toka/l10n/app_localizations.dart';

/// Stub package_info_plus so it doesn't throw MissingPluginException in tests.
void _setupPackageInfoStub() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('dev.fluttercommunity.plus/package_info'),
    (call) async {
      if (call.method == 'getAll') {
        return <String, dynamic>{
          'appName': 'Toka',
          'packageName': 'com.toka.app',
          'version': '1.0.0',
          'buildNumber': '1',
          'buildSignature': '',
          'installerStore': '',
        };
      }
      return null;
    },
  );
}

Widget _wrap({SubscriptionState? subscription}) => ProviderScope(
      overrides: [
        if (subscription != null)
          subscriptionStateProvider.overrideWith((ref) => subscription),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: const SettingsScreen(),
      ),
    );

void main() {
  setUp(_setupPackageInfoStub);

  testWidgets('SettingsScreen renderiza sección Cuenta', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings_section_account')), findsOneWidget);
  });

  testWidgets('SettingsScreen renderiza sección Suscripción', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings_section_subscription')), findsOneWidget);
  });

  testWidgets('SettingsScreen muestra "Plan Premium" cuando hay Premium activo', (tester) async {
    await tester.pumpWidget(_wrap(
      subscription: SubscriptionState.active(
        plan: 'monthly',
        endsAt: DateTime(2027, 1, 1),
        autoRenew: true,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('subscription_status_label')), findsOneWidget);
    expect(find.text('Plan Premium'), findsOneWidget);
  });

  testWidgets('SettingsScreen muestra "Plan gratuito" cuando no hay Premium', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('subscription_status_label')), findsOneWidget);
    expect(find.text('Plan gratuito'), findsOneWidget);
  });

  testWidgets('SettingsScreen renderiza sección Acerca de', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    // Scroll to the bottom to reveal the "Acerca de" section.
    await tester.dragUntilVisible(
      find.byKey(const Key('settings_section_about')),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings_section_about')), findsOneWidget);
  });

  testWidgets('golden: SettingsScreen', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(SettingsScreen),
      matchesGoldenFile('goldens/settings_screen.png'),
    );
  });
}
