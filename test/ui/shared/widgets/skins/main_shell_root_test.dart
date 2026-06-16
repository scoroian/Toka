import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toka/core/theme/app_skin.dart';
import 'package:toka/core/theme/skin_provider.dart';
import 'package:toka/l10n/app_localizations.dart';
import 'package:toka/shared/widgets/ad_banner_config_provider.dart';
import 'package:toka/shared/widgets/skins/main_shell_root.dart';
import 'package:toka/shared/widgets/skins/main_shell_v2.dart';

/// Harness ligero: monta MainShellRoot con un child identificable usando un
/// ShellRoute dentro de un GoRouter mínimo. Inyecta un AdBannerConfig OFF para
/// evitar timers / streams Firestore reales del banner.
Widget harness({required ProviderContainer container}) {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      ShellRoute(
        builder: (_, __, child) => MainShellRoot(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) => const Text('home-content'),
          ),
        ],
      ),
    ],
  );
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('skin v2 renders MainShellV2 + child', (tester) async {
    final c = ProviderContainer(
      overrides: [
        skinModeProvider.overrideWith(_FakeSkinMode.new),
        adBannerConfigProvider.overrideWith(
          (ref) => const AdBannerConfig(show: false, unitId: ''),
        ),
      ],
    );
    addTearDown(c.dispose);
    c.read(skinModeProvider.notifier).set(AppSkin.v2);

    await tester.pumpWidget(harness(container: c));
    await tester.pumpAndSettle();

    expect(find.byType(MainShellV2), findsOneWidget);
    expect(find.text('home-content'), findsOneWidget);
  });
}

/// SkinMode fake síncrono: no lee SharedPreferences, permite set() inmediato.
class _FakeSkinMode extends SkinMode {
  @override
  AppSkin build() => AppSkin.v2;

  @override
  Future<void> set(AppSkin skin) async {
    state = skin;
  }
}
