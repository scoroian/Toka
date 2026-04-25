import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toka/core/theme/app_skin.dart';
import 'package:toka/core/theme/skin_provider.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/subscription/application/paywall_provider.dart';
import 'package:toka/features/subscription/domain/purchase_result.dart';
import 'package:toka/features/subscription/presentation/skins/futurista/subscription_management_screen_futurista.dart';
import 'package:toka/features/subscription/presentation/skins/subscription_management_screen.dart';
import 'package:toka/features/subscription/presentation/skins/subscription_management_screen_v2.dart';
import 'package:toka/l10n/app_localizations.dart';

class _FakeAuth extends Auth {
  @override
  AuthState build() => const AuthState.unauthenticated();
}

class _FakeCurrentHome extends CurrentHome {
  @override
  Future<Home?> build() async => null;
}

class _FakePaywall extends Paywall {
  @override
  AsyncValue<PurchaseResult?> build() {
    ref.onDispose(() {});
    return const AsyncValue.data(null);
  }

  @override
  Future<void> startPurchase({
    required String homeId,
    required String productId,
  }) async {}

  @override
  Future<void> saveDowngradePlan({
    required String homeId,
    required List<String> memberIds,
    required List<String> taskIds,
  }) async {}

  @override
  Future<void> restorePremium({required String homeId}) async {}
}

Widget _harness({required ProviderContainer container}) =>
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        locale: Locale('es'),
        supportedLocales: [Locale('es'), Locale('en'), Locale('ro')],
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: SubscriptionManagementScreen(),
      ),
    );

List<Override> _baseOverrides() => [
      authProvider.overrideWith(_FakeAuth.new),
      currentHomeProvider.overrideWith(_FakeCurrentHome.new),
      paywallProvider.overrideWith(_FakePaywall.new),
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('wrapper renders v2 by default', (tester) async {
    final c = ProviderContainer(overrides: _baseOverrides());
    addTearDown(c.dispose);
    await tester.pumpWidget(_harness(container: c));
    await tester.pump();
    expect(find.byType(SubscriptionManagementScreenV2), findsOneWidget);
    expect(find.byType(SubscriptionManagementScreenFuturista), findsNothing);
  });

  testWidgets('wrapper renders futurista when skin = futurista',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {SkinMode.persistKey: AppSkin.futurista.persistKey});
    final c = ProviderContainer(overrides: _baseOverrides());
    addTearDown(c.dispose);
    await tester.pumpWidget(_harness(container: c));
    // Pumps discretos: evitamos pumpAndSettle porque AnimatedSwitcher encadena
    // transiciones y algún frame puede no estacionarse.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    expect(find.byType(SubscriptionManagementScreenFuturista), findsOneWidget);
    expect(find.byType(SubscriptionManagementScreenV2), findsNothing);
  });
}
