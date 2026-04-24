import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toka/core/theme/app_skin.dart';
import 'package:toka/core/theme/skin_provider.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/tasks/application/all_tasks_view_model.dart';
import 'package:toka/features/tasks/presentation/skins/all_tasks_screen.dart';
import 'package:toka/features/tasks/presentation/skins/all_tasks_screen_v2.dart';
import 'package:toka/features/tasks/presentation/skins/futurista/all_tasks_screen_futurista.dart';
import 'package:toka/l10n/app_localizations.dart';

class _MockAllTasksViewModel extends Mock implements AllTasksViewModel {}

class _FakeAuth extends Auth {
  @override
  AuthState build() => const AuthState.unauthenticated();
}

class _FakeCurrentHome extends CurrentHome {
  @override
  Future<Home?> build() async => null;
}

Widget _harness(List<Override> overrides) => ProviderScope(
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
        home: AllTasksScreen(),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockAllTasksViewModel vm;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    vm = _MockAllTasksViewModel();
    when(() => vm.isSelectionMode).thenReturn(false);
    when(() => vm.selectedIds).thenReturn(<String>{});
    when(() => vm.viewData).thenReturn(const AsyncValue.loading());
  });

  group('AllTasksScreen wrapper', () {
    testWidgets('renders AllTasksScreenV2 when skin is v2 (default)',
        (tester) async {
      await tester.pumpWidget(_harness([
        allTasksViewModelProvider.overrideWith((_) => vm),
        authProvider.overrideWith(_FakeAuth.new),
        currentHomeProvider.overrideWith(_FakeCurrentHome.new),
      ]));
      await tester.pump();

      expect(find.byType(AllTasksScreenV2), findsOneWidget);
      expect(find.byType(AllTasksScreenFuturista), findsNothing);
    });

    testWidgets('renders AllTasksScreenFuturista when skin is futurista',
        (tester) async {
      SharedPreferences.setMockInitialValues(
          {SkinMode.persistKey: AppSkin.futurista.persistKey});
      await tester.pumpWidget(_harness([
        allTasksViewModelProvider.overrideWith((_) => vm),
        authProvider.overrideWith(_FakeAuth.new),
        currentHomeProvider.overrideWith(_FakeCurrentHome.new),
      ]));
      // Esperar a que el microtask de SharedPreferences se resuelva y
      // AnimatedSwitcher complete la transición (220ms). No se usa
      // pumpAndSettle porque el estado loading muestra un
      // CircularProgressIndicator infinito.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AllTasksScreenFuturista), findsOneWidget);
      expect(find.byType(AllTasksScreenV2), findsNothing);
    });
  });
}
