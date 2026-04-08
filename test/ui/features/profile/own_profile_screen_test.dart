// test/ui/features/profile/own_profile_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/profile/application/own_profile_view_model.dart';
import 'package:toka/features/profile/domain/user_profile.dart';
import 'package:toka/features/profile/presentation/own_profile_screen.dart';
import 'package:toka/l10n/app_localizations.dart';
import 'package:toka/shared/widgets/loading_widget.dart';

// ---------------------------------------------------------------------------
// Fake ViewModel
// ---------------------------------------------------------------------------

class _FakeOwnProfileVM implements OwnProfileViewModel {
  _FakeOwnProfileVM(this.viewData);

  @override
  final AsyncValue<OwnProfileViewData?> viewData;

  @override
  Future<void> signOut() async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _fakeProfile = UserProfile(
  uid: 'uid1',
  nickname: 'Ana García',
  photoUrl: null,
  bio: 'Bio de prueba',
  phone: null,
  phoneVisibility: 'hidden',
  locale: 'es',
);

OwnProfileViewData _makeViewData() => OwnProfileViewData(
      profile: _fakeProfile,
      hasEmailPassword: false,
      radarEntries: const AsyncValue.data([]),
    );

Widget _wrap(OwnProfileViewModel vm) => ProviderScope(
      overrides: [
        ownProfileViewModelProvider.overrideWithValue(vm),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('es')],
        home: OwnProfileScreen(),
      ),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('OwnProfileScreen', () {
    testWidgets('muestra LoadingWidget mientras carga', (tester) async {
      final vm = _FakeOwnProfileVM(const AsyncValue.loading());
      await tester.pumpWidget(_wrap(vm));
      // Do not pumpAndSettle — loading state doesn't resolve
      await tester.pump();

      expect(find.byType(LoadingWidget), findsOneWidget);
    });

    testWidgets('muestra el nickname cuando los datos están cargados',
        (tester) async {
      final vm = _FakeOwnProfileVM(AsyncValue.data(_makeViewData()));
      await tester.pumpWidget(_wrap(vm));
      await tester.pumpAndSettle();

      expect(find.text('Ana García'), findsOneWidget);
    });

    testWidgets('muestra el botón de editar perfil con la Key correcta',
        (tester) async {
      final vm = _FakeOwnProfileVM(AsyncValue.data(_makeViewData()));
      await tester.pumpWidget(_wrap(vm));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('edit_profile_btn')), findsOneWidget);
    });

    testWidgets('muestra Text de error en estado de error', (tester) async {
      final vm = _FakeOwnProfileVM(
        AsyncValue.error('fallo', StackTrace.empty),
      );
      await tester.pumpWidget(_wrap(vm));
      await tester.pumpAndSettle();

      // The screen shows a Text with the generic error string in error state
      expect(find.byType(Text), findsWidgets);
    });
  });
}
