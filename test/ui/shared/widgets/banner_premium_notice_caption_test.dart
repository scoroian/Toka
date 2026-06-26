import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:toka/core/constants/routes.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/l10n/app_localizations.dart';
import 'package:toka/shared/widgets/ad_banner_notice_provider.dart';
import 'package:toka/shared/widgets/banner_premium_notice_caption.dart';

class _FakeCurrentHome extends CurrentHome {
  @override
  Future<Home?> build() async => Home(
        id: 'h1',
        name: 'Casa',
        ownerUid: 'o',
        currentPayerUid: 'otro',
        lastPayerUid: null,
        premiumStatus: HomePremiumStatus.active,
        premiumPlan: null,
        premiumEndsAt: null,
        restoreUntil: null,
        autoRenewEnabled: false,
        limits: const HomeLimits(maxMembers: 5),
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
  @override
  Future<void> switchHome(String i) async {}
}

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
    await t.pumpWidget(ProviderScope(
      overrides: [currentHomeProvider.overrideWith(() => _FakeCurrentHome())],
      child: _app(_router()),
    ));
    await t.pumpAndSettle();
    expect(find.text('Quita también el banner con Toka Plus'), findsOneWidget);
    expect(find.byKey(const Key('banner_premium_notice_dismiss')), findsOneWidget);
  });

  testWidgets('tap en el CTA navega al paywall de Plus', (t) async {
    await t.pumpWidget(ProviderScope(
      overrides: [currentHomeProvider.overrideWith(() => _FakeCurrentHome())],
      child: _app(_router()),
    ));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('banner_premium_notice_cta')));
    await t.pumpAndSettle();
    expect(find.text('PLUS_PAYWALL'), findsOneWidget);
  });

  testWidgets('tap en ✕ descarta el hogar actual', (t) async {
    final container = ProviderContainer(
      overrides: [currentHomeProvider.overrideWith(() => _FakeCurrentHome())],
    );
    addTearDown(container.dispose);
    await container.read(currentHomeProvider.future);

    await t.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: _app(_router()),
    ));
    await t.pumpAndSettle();

    expect(container.read(adBannerNoticeDismissalProvider).contains('h1'), isFalse);
    await t.tap(find.byKey(const Key('banner_premium_notice_dismiss')));
    await t.pumpAndSettle();
    expect(container.read(adBannerNoticeDismissalProvider).contains('h1'), isTrue);
  });
}
