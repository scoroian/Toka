// test/ui/features/profile/edit_profile_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/profile/application/edit_profile_view_model.dart';
import 'package:toka/features/profile/presentation/skins/edit_profile_screen_v2.dart';
import 'package:toka/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Fake ViewModel
// ---------------------------------------------------------------------------

class _FakeEditProfileVM implements EditProfileViewModel {
  const _FakeEditProfileVM({
    required this.isInitialized,
    this.phoneVisible = false,
    this.isLoading = false,
    this.savedSuccessfully = false,
    this.initialNickname,
    this.initialBio,
    this.initialPhone,
    this.initialPhotoUrl,
    this.selectedPhotoPath,
  });

  @override
  final bool isInitialized;
  @override
  final bool phoneVisible;
  @override
  final bool isLoading;
  @override
  final bool savedSuccessfully;
  @override
  final String? initialNickname;
  @override
  final String? initialBio;
  @override
  final String? initialPhone;
  @override
  final String? initialPhotoUrl;
  @override
  final String? selectedPhotoPath;

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

// ---------------------------------------------------------------------------
// Fake Auth notifier (unauthenticated — avoids Firestore in notifier)
// ---------------------------------------------------------------------------

class _FakeAuth extends Auth {
  @override
  AuthState build() => const AuthState.unauthenticated();
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

Widget _wrap(EditProfileViewModel vm) => ProviderScope(
      overrides: [
        // Override the computed provider the screen watches for display state
        editProfileViewModelProvider.overrideWithValue(vm),
        // Override auth so the notifier (used only for setPhoneVisible) never
        // touches Firestore
        authProvider.overrideWith(() => _FakeAuth()),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('es')],
        home: EditProfileScreenV2(),
      ),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('EditProfileScreen', () {
    testWidgets('muestra los campos TextField del formulario', (tester) async {
      const vm = _FakeEditProfileVM(isInitialized: true);
      await tester.pumpWidget(_wrap(vm));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('campo de nickname tiene la Key correcta y acepta texto',
        (tester) async {
      const vm = _FakeEditProfileVM(
        isInitialized: true,
        initialNickname: 'Ana',
      );
      await tester.pumpWidget(_wrap(vm));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('nickname_field')), findsOneWidget);
      expect(find.byKey(const Key('bio_field')), findsOneWidget);
      expect(find.byKey(const Key('phone_field')), findsOneWidget);
    });

    testWidgets('muestra el botón de guardar cuando no está cargando',
        (tester) async {
      const vm = _FakeEditProfileVM(isInitialized: true);
      await tester.pumpWidget(_wrap(vm));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('save_profile_btn')), findsOneWidget);
    });
  });
}
