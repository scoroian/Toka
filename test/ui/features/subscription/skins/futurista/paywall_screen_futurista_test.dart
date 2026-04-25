import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toka/core/theme/app_skin.dart';
import 'package:toka/core/theme/skin_provider.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/subscription/application/paywall_provider.dart';
import 'package:toka/features/subscription/domain/purchase_result.dart';
import 'package:toka/features/subscription/presentation/paywall_entry_context.dart';
import 'package:toka/features/subscription/presentation/skins/futurista/paywall_screen_futurista.dart';
import 'package:toka/features/subscription/presentation/skins/paywall_screen.dart';
import 'package:toka/features/subscription/presentation/skins/paywall_screen_v2.dart';
import 'package:toka/l10n/app_localizations.dart';

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
}

Widget _harness({List<Override> overrides = const []}) => ProviderScope(
      overrides: overrides,
      child: const MaterialApp(
        locale: Locale('es'),
        supportedLocales: [Locale('es'), Locale('en'), Locale('ro')],
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: PaywallScreen(entryContext: PaywallEntryContext.fromFree),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  final baseOverrides = <Override>[
    currentHomeProvider.overrideWith(_FakeCurrentHome.new),
    paywallProvider.overrideWith(_FakePaywall.new),
  ];

  testWidgets('wrapper renders v2 by default', (tester) async {
    await tester.pumpWidget(_harness(overrides: baseOverrides));
    await tester.pump();
    expect(find.byType(PaywallScreenV2), findsOneWidget);
    expect(find.byType(PaywallScreenFuturista), findsNothing);
  });

  testWidgets('wrapper renders futurista when skin = futurista',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {SkinMode.persistKey: AppSkin.futurista.persistKey});
    await tester.pumpWidget(_harness(overrides: baseOverrides));
    // Pumps discretos para resolver microtask de SkinMode._load() y la
    // transición del AnimatedSwitcher (220ms).
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    expect(find.byType(PaywallScreenFuturista), findsOneWidget);
    expect(find.byType(PaywallScreenV2), findsNothing);
  });
}
