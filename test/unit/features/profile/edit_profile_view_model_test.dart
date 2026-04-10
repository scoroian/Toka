// test/unit/features/profile/edit_profile_view_model_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/auth/domain/auth_user.dart';
import 'package:toka/features/i18n/application/locale_provider.dart';
import 'package:toka/features/profile/application/edit_profile_view_model.dart';
import 'package:toka/features/profile/application/profile_provider.dart';
import 'package:toka/features/profile/domain/user_profile.dart';

class _FakeAuth extends Auth {
  @override
  AuthState build() => const AuthState.authenticated(AuthUser(
        uid: 'uid1',
        email: 'u@u.com',
        displayName: 'User',
        photoUrl: null,
        emailVerified: true,
        providers: [],
      ));
}

class _FakeLocaleNotifier extends LocaleNotifier {
  @override
  Locale build() => const Locale('es');

  @override
  Future<void> initialize(String? uid) async {}

  @override
  Future<void> setLocale(String code, String? uid) async {}
}

class _FakeProfileEditor extends ProfileEditor {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  @override
  Future<void> updateProfile(
    String uid, {
    String? nickname,
    String? bio,
    String? phone,
    String? phoneVisibility,
  }) async {}
}

ProviderContainer _makeContainer() {
  return ProviderContainer(overrides: [
    authProvider.overrideWith(_FakeAuth.new),
    authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
    localeNotifierProvider.overrideWith(_FakeLocaleNotifier.new),
    profileEditorProvider.overrideWith(_FakeProfileEditor.new),
    userProfileProvider('uid1').overrideWith(
      (ref) => Stream.value(const UserProfile(
        uid: 'uid1',
        nickname: 'TestUser',
        photoUrl: null,
        bio: 'Mi bio',
        phone: null,
        phoneVisibility: 'hidden',
        locale: 'es',
      )),
    ),
  ]);
}

void main() {
  group('EditProfileViewModel', () {
    test('savedSuccessfully empieza en false', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(editProfileViewModelNotifierProvider.notifier);
      expect(notifier.savedSuccessfully, isFalse);
    });

    test('isLoading empieza en false', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(editProfileViewModelNotifierProvider.notifier);
      expect(notifier.isLoading, isFalse);
    });

    test('save con datos válidos pone savedSuccessfully = true', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(editProfileViewModelNotifierProvider.notifier);
      await notifier.save(nickname: 'NuevoNombre', bio: '', phone: '');

      expect(notifier.savedSuccessfully, isTrue);
    });

    test('setPhoneVisible actualiza phoneVisible', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(editProfileViewModelNotifierProvider.notifier);
      notifier.setPhoneVisible(true);
      expect(notifier.phoneVisible, isTrue);
      notifier.setPhoneVisible(false);
      expect(notifier.phoneVisible, isFalse);
    });
  });
}
