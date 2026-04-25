import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/profile/application/edit_profile_view_model.dart';
import 'package:toka/features/profile/presentation/skins/edit_profile_screen.dart';
import 'package:toka/features/profile/presentation/skins/edit_profile_screen_v2.dart';
import 'package:toka/features/profile/presentation/skins/futurista/edit_profile_screen_futurista.dart';
import 'package:toka/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Fake Auth notifier (unauthenticated — avoids Firestore listener / timers).
// ---------------------------------------------------------------------------
class _FakeAuth extends Auth {
  @override
  AuthState build() => const AuthState.unauthenticated();
}

// ---------------------------------------------------------------------------
// Fake ViewModel — simula `isInitialized: false` para que el body no renderice
// los TextFields (que requieren initialized). Mantiene el árbol estable y
// evita cualquier acceso a Firestore.
// ---------------------------------------------------------------------------
class _FakeEditProfileVM implements EditProfileViewModel {
  const _FakeEditProfileVM();

  @override
  bool get isInitialized => false;
  @override
  bool get phoneVisible => false;
  @override
  bool get isLoading => false;
  @override
  bool get savedSuccessfully => false;
  @override
  String? get initialNickname => null;
  @override
  String? get initialBio => null;
  @override
  String? get initialPhone => null;
  @override
  String? get initialPhotoUrl => null;
  @override
  String? get selectedPhotoPath => null;

  @override
  void setPhoneVisible(bool v) {}
  @override
  void setPhoto(String? path) {}
  @override
  Future<void> save({
    required String nickname,
    required String bio,
    required String phone,
  }) async {}
}

Widget harness({required ProviderContainer container}) =>
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        locale: Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: EditProfileScreen(),
      ),
    );

ProviderContainer _container() => ProviderContainer(
      overrides: [
        authProvider.overrideWith(() => _FakeAuth()),
        editProfileViewModelProvider
            .overrideWithValue(const _FakeEditProfileVM()),
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('wrapper renders v2 by default', (tester) async {
    final c = _container();
    addTearDown(c.dispose);
    await tester.pumpWidget(harness(container: c));
    await tester.pump();
    expect(find.byType(EditProfileScreenV2), findsOneWidget);
    expect(find.byType(EditProfileScreenFuturista), findsNothing);
  });

  testWidgets('wrapper renders futurista when skin = futurista',
      (tester) async {
    SharedPreferences.setMockInitialValues({'tocka.skin': 'futurista'});
    final c = _container();
    addTearDown(c.dispose);
    await tester.pumpWidget(harness(container: c));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    expect(find.byType(EditProfileScreenFuturista), findsOneWidget);
    expect(find.byType(EditProfileScreenV2), findsNothing);
  });
}
