// test/ui/features/subscription/premium_state_banner_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/features/subscription/application/subscription_provider.dart';
import 'package:toka/features/subscription/domain/subscription_state.dart';
import 'package:toka/features/subscription/presentation/widgets/premium_state_banner.dart';
import 'package:toka/l10n/app_localizations.dart';

Home _homeWith({
  HomePremiumStatus status = HomePremiumStatus.free,
  DateTime? premiumEndsAt,
  DateTime? restoreUntil,
}) =>
    Home(
      id: 'h1',
      name: 'Test',
      ownerUid: 'u1',
      currentPayerUid: 'u1',
      lastPayerUid: null,
      premiumStatus: status,
      premiumPlan: 'monthly',
      premiumEndsAt: premiumEndsAt,
      restoreUntil: restoreUntil,
      autoRenewEnabled: false,
      limits: const HomeLimits(maxMembers: 10),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

class _FakeCurrentHome extends CurrentHome {
  _FakeCurrentHome(this.home);
  final Home home;

  @override
  Future<Home?> build() async => home;
}

Widget _wrap(Widget child, {List<Override> overrides = const []}) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => Scaffold(body: child)),
    ],
  );
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      routerConfig: router,
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
  group('PremiumStateBanner', () {
    testWidgets('free → no renderiza nada', (tester) async {
      await tester.pumpWidget(_wrap(
        const PremiumStateBanner(),
        overrides: [
          currentHomeProvider.overrideWith(() => _FakeCurrentHome(_homeWith())),
          subscriptionStateProvider
              .overrideWith((_) => const SubscriptionState.free()),
        ],
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('banner_rescue')), findsNothing);
      expect(find.byKey(const Key('banner_cancelled_pending_end')),
          findsNothing);
      expect(find.byKey(const Key('banner_expired_free')), findsNothing);
      expect(find.byKey(const Key('banner_restorable')), findsNothing);
    });

    testWidgets('active → no renderiza nada', (tester) async {
      await tester.pumpWidget(_wrap(
        const PremiumStateBanner(),
        overrides: [
          currentHomeProvider
              .overrideWith(() => _FakeCurrentHome(_homeWith(
                    status: HomePremiumStatus.active,
                    premiumEndsAt:
                        DateTime.now().add(const Duration(days: 30)),
                  ))),
          subscriptionStateProvider.overrideWith((_) => SubscriptionState.active(
                plan: 'monthly',
                endsAt: DateTime.now().add(const Duration(days: 30)),
                autoRenew: true,
              )),
        ],
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('banner_rescue')), findsNothing);
    });

    testWidgets('rescue (2 días) → banner rojo con título', (tester) async {
      final endsAt = DateTime.now().add(const Duration(days: 2, hours: 5));
      await tester.pumpWidget(_wrap(
        const PremiumStateBanner(),
        overrides: [
          currentHomeProvider
              .overrideWith(() => _FakeCurrentHome(_homeWith(
                    status: HomePremiumStatus.rescue,
                    premiumEndsAt: endsAt,
                  ))),
          subscriptionStateProvider.overrideWith(
            (_) => SubscriptionState.rescue(
              plan: 'monthly',
              endsAt: endsAt,
              daysLeft: 3,
            ),
          ),
        ],
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('banner_rescue')), findsOneWidget);
      expect(find.byKey(const Key('banner_rescue_text')), findsOneWidget);
      expect(find.byKey(const Key('banner_rescue_cta')), findsOneWidget);
    });

    testWidgets('rescue (<1 día) → banner rojo último día', (tester) async {
      final endsAt = DateTime.now().add(const Duration(hours: 7));
      await tester.pumpWidget(_wrap(
        const PremiumStateBanner(),
        overrides: [
          currentHomeProvider
              .overrideWith(() => _FakeCurrentHome(_homeWith(
                    status: HomePremiumStatus.rescue,
                    premiumEndsAt: endsAt,
                  ))),
          subscriptionStateProvider.overrideWith(
            (_) => SubscriptionState.rescue(
              plan: 'monthly',
              endsAt: endsAt,
              daysLeft: 1,
            ),
          ),
        ],
      ));
      await tester.pump();
      expect(find.byKey(const Key('banner_rescue')), findsOneWidget);
      // Con <1 día debe usar el texto "vence hoy"
      expect(find.text('Tu Premium vence hoy. Renueva antes de medianoche.'),
          findsOneWidget);
    });

    testWidgets('cancelledPendingEnd → banner ámbar con fecha', (tester) async {
      final endsAt = DateTime(2026, 5, 10);
      await tester.pumpWidget(_wrap(
        const PremiumStateBanner(),
        overrides: [
          currentHomeProvider
              .overrideWith(() => _FakeCurrentHome(_homeWith(
                    status: HomePremiumStatus.cancelledPendingEnd,
                    premiumEndsAt: endsAt,
                  ))),
          subscriptionStateProvider.overrideWith(
            (_) => SubscriptionState.cancelledPendingEnd(
              plan: 'monthly',
              endsAt: endsAt,
            ),
          ),
        ],
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('banner_cancelled_pending_end')),
          findsOneWidget);
      expect(find.textContaining('10/05/2026'), findsOneWidget);
    });

    testWidgets('expiredFree → banner neutro y CTA Reactivar',
        (tester) async {
      final expiredOn = DateTime(2026, 3, 15);
      await tester.pumpWidget(_wrap(
        const PremiumStateBanner(),
        overrides: [
          currentHomeProvider
              .overrideWith(() => _FakeCurrentHome(_homeWith(
                    status: HomePremiumStatus.expiredFree,
                    premiumEndsAt: expiredOn,
                  ))),
          subscriptionStateProvider
              .overrideWith((_) => const SubscriptionState.expiredFree()),
        ],
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('banner_expired_free')), findsOneWidget);
      expect(find.text('Reactivar Premium'), findsOneWidget);
      expect(find.textContaining('15/03/2026'), findsOneWidget);
    });

    testWidgets('restorable → banner verde con fecha', (tester) async {
      final until = DateTime(2026, 5, 20);
      await tester.pumpWidget(_wrap(
        const PremiumStateBanner(),
        overrides: [
          currentHomeProvider
              .overrideWith(() => _FakeCurrentHome(_homeWith(
                    status: HomePremiumStatus.restorable,
                    restoreUntil: until,
                  ))),
          subscriptionStateProvider.overrideWith(
            (_) => SubscriptionState.restorable(restoreUntil: until),
          ),
        ],
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('banner_restorable')), findsOneWidget);
      expect(find.textContaining('20/05/2026'), findsOneWidget);
    });
  });

  group('PremiumStateBanner goldens', () {
    testWidgets('golden: rescue', (tester) async {
      final endsAt = DateTime.now().add(const Duration(days: 2, hours: 6));
      await tester.pumpWidget(_wrap(
        const PremiumStateBanner(),
        overrides: [
          currentHomeProvider
              .overrideWith(() => _FakeCurrentHome(_homeWith(
                    status: HomePremiumStatus.rescue,
                    premiumEndsAt: endsAt,
                  ))),
          subscriptionStateProvider.overrideWith(
            (_) => SubscriptionState.rescue(
              plan: 'monthly',
              endsAt: endsAt,
              daysLeft: 3,
            ),
          ),
        ],
      ));
      // No usar pumpAndSettle porque el banner no se anima en este caso
      // pero pumpAndSettle bloquearía si el widget tuviera animaciones
      // (cuando daysLeft < 1).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await expectLater(
        find.byKey(const Key('banner_rescue')),
        matchesGoldenFile('goldens/premium_state_banner_rescue.png'),
      );
    });

    testWidgets('golden: cancelledPendingEnd', (tester) async {
      final endsAt = DateTime(2026, 5, 10);
      await tester.pumpWidget(_wrap(
        const PremiumStateBanner(),
        overrides: [
          currentHomeProvider
              .overrideWith(() => _FakeCurrentHome(_homeWith(
                    status: HomePremiumStatus.cancelledPendingEnd,
                    premiumEndsAt: endsAt,
                  ))),
          subscriptionStateProvider.overrideWith(
            (_) => SubscriptionState.cancelledPendingEnd(
              plan: 'monthly',
              endsAt: endsAt,
            ),
          ),
        ],
      ));
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(const Key('banner_cancelled_pending_end')),
        matchesGoldenFile(
            'goldens/premium_state_banner_cancelled_pending_end.png'),
      );
    });

    testWidgets('golden: expiredFree', (tester) async {
      final expiredOn = DateTime(2026, 3, 15);
      await tester.pumpWidget(_wrap(
        const PremiumStateBanner(),
        overrides: [
          currentHomeProvider
              .overrideWith(() => _FakeCurrentHome(_homeWith(
                    status: HomePremiumStatus.expiredFree,
                    premiumEndsAt: expiredOn,
                  ))),
          subscriptionStateProvider
              .overrideWith((_) => const SubscriptionState.expiredFree()),
        ],
      ));
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(const Key('banner_expired_free')),
        matchesGoldenFile('goldens/premium_state_banner_expired_free.png'),
      );
    });

    testWidgets('golden: restorable', (tester) async {
      final until = DateTime(2026, 5, 20);
      await tester.pumpWidget(_wrap(
        const PremiumStateBanner(),
        overrides: [
          currentHomeProvider
              .overrideWith(() => _FakeCurrentHome(_homeWith(
                    status: HomePremiumStatus.restorable,
                    restoreUntil: until,
                  ))),
          subscriptionStateProvider.overrideWith(
            (_) => SubscriptionState.restorable(restoreUntil: until),
          ),
        ],
      ));
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(const Key('banner_restorable')),
        matchesGoldenFile('goldens/premium_state_banner_restorable.png'),
      );
    });
  });
}
