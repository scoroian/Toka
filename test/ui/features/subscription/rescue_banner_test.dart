// test/ui/features/subscription/rescue_banner_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/auth/domain/auth_user.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/features/subscription/application/subscription_provider.dart';
import 'package:toka/features/subscription/domain/subscription_state.dart';
import 'package:toka/features/subscription/presentation/widgets/rescue_banner.dart';
import 'package:toka/l10n/app_localizations.dart';

const _user = AuthUser(
  uid: 'u1',
  email: 'test@test.com',
  displayName: 'Test',
  photoUrl: null,
  emailVerified: true,
  providers: [],
);

final _rescueHome = Home(
  id: 'h1',
  name: 'Test',
  ownerUid: 'u1',
  currentPayerUid: 'u1',
  lastPayerUid: null,
  premiumStatus: HomePremiumStatus.rescue,
  premiumPlan: 'monthly',
  premiumEndsAt: DateTime.now().add(const Duration(days: 2)),
  restoreUntil: null,
  autoRenewEnabled: false,
  limits: const HomeLimits(maxMembers: 10),
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

final _activeHome = _rescueHome.copyWith(
  premiumStatus: HomePremiumStatus.active,
);

class _FakeAuth extends Auth {
  final AuthState _state;
  _FakeAuth(this._state);

  @override
  AuthState build() => _state;
}

class _FakeCurrentHome extends CurrentHome {
  final Home home;
  _FakeCurrentHome(this.home);

  @override
  Future<Home?> build() async => home;
}

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
        home: Scaffold(body: child),
      ),
    );

void main() {
  testWidgets('RescueBanner visible para owner en estado rescue',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const RescueBanner(),
      overrides: [
        authProvider.overrideWith(
            () => _FakeAuth(const AuthState.authenticated(_user))),
        currentHomeProvider
            .overrideWith(() => _FakeCurrentHome(_rescueHome)),
        subscriptionStateProvider.overrideWith((_) =>
            const SubscriptionState.rescue(
                plan: 'monthly', endsAt: null, daysLeft: 2)),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('rescue_banner_text')), findsOneWidget);
    expect(find.byKey(const Key('rescue_banner_renew_btn')), findsOneWidget);
  });

  testWidgets('RescueBanner no visible cuando premiumStatus != rescue',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const RescueBanner(),
      overrides: [
        authProvider.overrideWith(
            () => _FakeAuth(const AuthState.authenticated(_user))),
        currentHomeProvider
            .overrideWith(() => _FakeCurrentHome(_activeHome)),
        subscriptionStateProvider.overrideWith((_) => SubscriptionState.active(
              plan: 'monthly',
              endsAt: DateTime.now().add(const Duration(days: 30)),
              autoRenew: true,
            )),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('rescue_banner_text')), findsNothing);
  });

  testWidgets('golden: RescueBanner en estado rescue', (tester) async {
    await tester.pumpWidget(_wrap(
      const RescueBanner(),
      overrides: [
        authProvider.overrideWith(
            () => _FakeAuth(const AuthState.authenticated(_user))),
        currentHomeProvider
            .overrideWith(() => _FakeCurrentHome(_rescueHome)),
        subscriptionStateProvider.overrideWith((_) =>
            const SubscriptionState.rescue(
                plan: 'monthly', endsAt: null, daysLeft: 2)),
      ],
    ));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/rescue_banner.png'),
    );
  });
}
