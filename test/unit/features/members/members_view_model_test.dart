// test/unit/features/members/members_view_model_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/i18n/application/locale_provider.dart';
import 'package:toka/features/members/application/members_view_model.dart';

class _TestAuth extends Auth {
  _TestAuth(this._state);
  final AuthState _state;
  @override
  AuthState build() => _state;
}

class _FakeCurrentHome extends CurrentHome {
  @override
  Future<Home?> build() async => null;
  @override
  Future<void> switchHome(String id) async {}
}

class _FakeLocaleNotifier extends LocaleNotifier {
  @override
  Locale build() => const Locale('es');
  @override
  Future<void> initialize(String? uid) async {}
  @override
  Future<void> setLocale(String code, String? uid) async {}
}

void main() {
  group('MembersViewModel', () {
    test('viewData is loading while currentHome resolves', () async {
      final container = ProviderContainer(overrides: [
        authProvider.overrideWith(
          () => _TestAuth(const AuthState.unauthenticated()),
        ),
        authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
        currentHomeProvider.overrideWith(() => _FakeCurrentHome()),
        localeNotifierProvider.overrideWith(() => _FakeLocaleNotifier()),
      ]);
      addTearDown(container.dispose);
      final vm = container.read(membersViewModelProvider);
      // currentHome is async; before it resolves viewData is loading or data
      expect(vm.viewData.hasValue || vm.viewData.isLoading, isTrue);
    });

    test('viewData is data(null) when home resolves to null', () async {
      final container = ProviderContainer(overrides: [
        authProvider.overrideWith(
          () => _TestAuth(const AuthState.unauthenticated()),
        ),
        authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
        currentHomeProvider.overrideWith(() => _FakeCurrentHome()),
        localeNotifierProvider.overrideWith(() => _FakeLocaleNotifier()),
      ]);
      addTearDown(container.dispose);

      // Wait for currentHome to settle
      await container.read(currentHomeProvider.future);

      final vm = container.read(membersViewModelProvider);
      expect(vm.viewData, isA<AsyncData<MembersViewData?>>());
      expect(vm.viewData.value, isNull);
    });

    test('MembersViewData exposes correct fields', () {
      const data = MembersViewData(
        activeMembers: [],
        frozenMembers: [],
        canInvite: false,
        homeId: 'home1',
        isPremium: true,
        activeMembersCount: 0,
        maxMembersFree: 3,
        freeLimitReached: false,
      );
      expect(data.homeId, 'home1');
      expect(data.canInvite, isFalse);
      expect(data.activeMembers, isEmpty);
      expect(data.frozenMembers, isEmpty);
      expect(data.isPremium, isTrue);
      expect(data.freeLimitReached, isFalse);
    });
  });
}
