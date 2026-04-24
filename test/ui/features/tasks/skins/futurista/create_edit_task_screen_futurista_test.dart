import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:toka/core/theme/app_skin.dart';
import 'package:toka/core/theme/skin_provider.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/tasks/presentation/skins/create_edit_task_screen.dart';
import 'package:toka/features/tasks/presentation/skins/create_edit_task_screen_v2.dart';
import 'package:toka/features/tasks/presentation/skins/futurista/create_edit_task_screen_futurista.dart';
import 'package:toka/l10n/app_localizations.dart';

class _FakeAuth extends Auth {
  @override
  AuthState build() => const AuthState.unauthenticated();
}

class _FakeCurrentHome extends CurrentHome {
  @override
  Future<Home?> build() async => null;
}

List<Override> _overrides() => [
      authProvider.overrideWith(_FakeAuth.new),
      currentHomeProvider.overrideWith(_FakeCurrentHome.new),
    ];

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
        home: CreateEditTaskScreen(),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => tz_data.initializeTimeZones());

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('wrapper renders v2 by default', (tester) async {
    final c = ProviderContainer(overrides: _overrides());
    addTearDown(c.dispose);
    await tester.pumpWidget(_harness(container: c));
    await tester.pump();

    expect(find.byType(CreateEditTaskScreenV2), findsOneWidget);
    expect(find.byType(CreateEditTaskScreenFuturista), findsNothing);
  });

  testWidgets('wrapper renders futurista when skin = futurista',
      (tester) async {
    SharedPreferences.setMockInitialValues(
      {SkinMode.persistKey: AppSkin.futurista.persistKey},
    );
    final c = ProviderContainer(overrides: _overrides());
    addTearDown(c.dispose);
    await tester.pumpWidget(_harness(container: c));
    // Pumps discretos: evitamos pumpAndSettle porque hay microtasks recurrentes
    // (VM init + AnimatedSwitcher 220ms) que dejarían el test colgado.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }

    expect(find.byType(CreateEditTaskScreenFuturista), findsOneWidget);
    expect(find.byType(CreateEditTaskScreenV2), findsNothing);
  });
}
