// Regresión §9 (QA 2026-06-16): la tile "Suscripción · Plan Premium/gratuito"
// (y "Restaurar compras") de Ajustes deben navegar a la pantalla de gestión de
// suscripción (AppRoutes.subscription). El reporte original ("no navega, solo
// hace scroll") resultó ser un artefacto de automatización por adb: el onTap
// está cableado y la ruta existe. Este test fija el contrato de navegación para
// evitar una regresión real futura.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:toka/core/constants/routes.dart';
import 'package:toka/features/settings/application/settings_view_model.dart';
import 'package:toka/features/settings/presentation/settings_screen.dart';
import 'package:toka/l10n/app_localizations.dart';

class _FakeSettingsViewModel implements SettingsViewModel {
  const _FakeSettingsViewModel({required this.viewData});
  @override
  final SettingsViewData viewData;
}

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: AppRoutes.settings,
    routes: [
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.subscription,
        builder: (_, __) => const Scaffold(
          key: Key('fake_subscription_destination'),
          body: Center(child: Text('subscription destination')),
        ),
      ),
    ],
  );
}

Widget _wrap({bool isPremium = false}) {
  final vm = _FakeSettingsViewModel(
    viewData: SettingsViewData(
      isPremium: isPremium,
      homeId: 'home1',
      uid: 'uid1',
    ),
  );
  return ProviderScope(
    overrides: [
      settingsViewModelProvider.overrideWithValue(vm),
    ],
    child: MaterialApp.router(
      routerConfig: _buildRouter(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
    ),
  );
}

void main() {
  testWidgets(
    'tocar la tile de Suscripción navega a la gestión de suscripción',
    (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.byKey(const Key('subscription_status_label')),
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.ensureVisible(
        find.byKey(const Key('subscription_status_label')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('subscription_status_label')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('fake_subscription_destination')),
        findsOneWidget,
      );
      expect(find.byType(SettingsScreen), findsNothing);
    },
  );

  testWidgets(
    'tocar "Restaurar compras" navega a la gestión de suscripción',
    (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.byKey(const Key('settings_restore_purchases')),
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.ensureVisible(
        find.byKey(const Key('settings_restore_purchases')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings_restore_purchases')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('fake_subscription_destination')),
        findsOneWidget,
      );
      expect(find.byType(SettingsScreen), findsNothing);
    },
  );
}
