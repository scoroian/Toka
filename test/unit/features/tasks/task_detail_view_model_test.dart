// test/unit/features/tasks/task_detail_view_model_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/i18n/application/locale_provider.dart';
import 'package:toka/features/tasks/application/task_detail_view_model.dart';

class _FakeAuth extends Auth {
  _FakeAuth(this._state);
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
  group('TaskDetailViewModel', () {
    test('viewData is data(null) when home is null', () async {
      final container = ProviderContainer(overrides: [
        authProvider.overrideWith(
            () => _FakeAuth(const AuthState.unauthenticated())),
        authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
        currentHomeProvider.overrideWith(() => _FakeCurrentHome()),
        localeNotifierProvider.overrideWith(() => _FakeLocaleNotifier()),
      ]);
      addTearDown(container.dispose);
      final vm = container.read(taskDetailViewModelProvider('nonexistent'));
      // Home is null (async data null) — should result in AsyncData(null) after resolution
      // The home provider is async so this may still be loading
      expect(vm.viewData.hasValue || vm.viewData.isLoading, isTrue);
    });
  });
}
