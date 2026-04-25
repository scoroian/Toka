// test/ui/features/homes/my_homes_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/homes/application/my_homes_view_model.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
import 'package:toka/features/homes/presentation/skins/my_homes_screen_v2.dart';
import 'package:toka/l10n/app_localizations.dart';
import 'package:toka/shared/widgets/loading_widget.dart';

// ---------------------------------------------------------------------------
// Fake ViewModel
// ---------------------------------------------------------------------------

class _FakeMyHomesVM implements MyHomesViewModel {
  const _FakeMyHomesVM({
    required this.memberships,
    this.currentHomeId = '',
  });

  @override
  final AsyncValue<List<HomeMembership>> memberships;

  @override
  final String currentHomeId;

  @override
  void switchHome(String homeId) {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

HomeMembership _makeMembership({
  required String homeId,
  required String name,
}) =>
    HomeMembership(
      homeId: homeId,
      homeNameSnapshot: name,
      role: MemberRole.member,
      billingState: BillingState.none,
      status: MemberStatus.active,
      joinedAt: DateTime(2024, 1, 1),
    );

Widget _wrap(MyHomesViewModel vm) => ProviderScope(
      overrides: [
        myHomesViewModelProvider.overrideWithValue(vm),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('es')],
        home: MyHomesScreenV2(),
      ),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('MyHomesScreen', () {
    testWidgets('muestra LoadingWidget mientras carga', (tester) async {
      const vm = _FakeMyHomesVM(memberships: AsyncValue.loading());
      await tester.pumpWidget(_wrap(vm));
      await tester.pump();

      expect(find.byType(LoadingWidget), findsOneWidget);
    });

    testWidgets('muestra los nombres de los hogares en la lista', (tester) async {
      final memberships = [
        _makeMembership(homeId: 'home1', name: 'Casa Principal'),
        _makeMembership(homeId: 'home2', name: 'Casa Vacaciones'),
      ];
      final vm = _FakeMyHomesVM(
        memberships: AsyncValue.data(memberships),
        currentHomeId: 'home1',
      );

      await tester.pumpWidget(_wrap(vm));
      await tester.pumpAndSettle();

      expect(find.text('Casa Principal'), findsOneWidget);
      expect(find.text('Casa Vacaciones'), findsOneWidget);
    });

    testWidgets('el hogar activo muestra el icono de check', (tester) async {
      final memberships = [
        _makeMembership(homeId: 'home1', name: 'Casa Principal'),
        _makeMembership(homeId: 'home2', name: 'Casa Vacaciones'),
      ];
      final vm = _FakeMyHomesVM(
        memberships: AsyncValue.data(memberships),
        currentHomeId: 'home1',
      );

      await tester.pumpWidget(_wrap(vm));
      await tester.pumpAndSettle();

      // Active tile has a check icon
      expect(find.byIcon(Icons.check), findsOneWidget);

      // The active tile is the one for home1
      final activeTile = find.byKey(const Key('home_list_tile_home1'));
      expect(activeTile, findsOneWidget);
      expect(
        find.descendant(of: activeTile, matching: find.byIcon(Icons.check)),
        findsOneWidget,
      );
    });

    testWidgets('el hogar inactivo no muestra el icono de check', (tester) async {
      final memberships = [
        _makeMembership(homeId: 'home1', name: 'Casa Principal'),
        _makeMembership(homeId: 'home2', name: 'Casa Vacaciones'),
      ];
      final vm = _FakeMyHomesVM(
        memberships: AsyncValue.data(memberships),
        currentHomeId: 'home1',
      );

      await tester.pumpWidget(_wrap(vm));
      await tester.pumpAndSettle();

      // Inactive tile (home2) has no check icon as a descendant
      final inactiveTile = find.byKey(const Key('home_list_tile_home2'));
      expect(inactiveTile, findsOneWidget);
      expect(
        find.descendant(of: inactiveTile, matching: find.byIcon(Icons.check)),
        findsNothing,
      );
    });

    testWidgets('lista vacía no muestra ningún ListTile', (tester) async {
      const vm = _FakeMyHomesVM(
        memberships: AsyncValue.data([]),
      );

      await tester.pumpWidget(_wrap(vm));
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsNothing);
    });
  });
}
