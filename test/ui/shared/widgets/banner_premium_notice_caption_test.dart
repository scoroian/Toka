import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:toka/core/constants/routes.dart';
import 'package:toka/l10n/app_localizations.dart';
import 'package:toka/shared/widgets/ad_banner_notice_provider.dart';
import 'package:toka/shared/widgets/banner_premium_notice_caption.dart';

GoRouter _router() => GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, __) =>
            const Scaffold(body: Center(child: BannerPremiumNoticeCaption())),
      ),
      GoRoute(
        path: AppRoutes.plusPaywall,
        builder: (_, __) => const Scaffold(body: Text('PLUS_PAYWALL')),
      ),
    ]);

Widget _app(GoRouter r) => MaterialApp.router(
      routerConfig: r,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
    );

void main() {
  testWidgets('renderiza texto + botón descartar', (t) async {
    await t.pumpWidget(ProviderScope(child: _app(_router())));
    await t.pumpAndSettle();
    expect(find.text('Quita también el banner con Toka Plus'), findsOneWidget);
    expect(
        find.byKey(const Key('banner_premium_notice_dismiss')), findsOneWidget);
  });

  testWidgets('tap en el CTA navega al paywall de Plus', (t) async {
    await t.pumpWidget(ProviderScope(child: _app(_router())));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('banner_premium_notice_cta')));
    await t.pumpAndSettle();
    expect(find.text('PLUS_PAYWALL'), findsOneWidget);
  });

  testWidgets('tap en ✕ descarta la caption en la sesión', (t) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await t.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: _app(_router()),
    ));
    await t.pumpAndSettle();

    expect(container.read(adBannerNoticeDismissedProvider), isFalse);
    await t.tap(find.byKey(const Key('banner_premium_notice_dismiss')));
    await t.pumpAndSettle();
    expect(container.read(adBannerNoticeDismissedProvider), isTrue);
  });
}
