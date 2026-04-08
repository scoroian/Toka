// test/unit/features/tasks/create_edit_task_view_model_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/i18n/application/locale_provider.dart';
import 'package:toka/features/tasks/application/create_edit_task_view_model.dart';
import 'package:toka/features/tasks/application/task_form_provider.dart';

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
  group('CreateEditTaskViewModel — create mode', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(overrides: [
        authProvider.overrideWith(
            () => _FakeAuth(const AuthState.unauthenticated())),
        authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
        currentHomeProvider.overrideWith(() => _FakeCurrentHome()),
        localeNotifierProvider.overrideWith(() => _FakeLocaleNotifier()),
      ]);
    });

    tearDown(() => container.dispose());

    test('savedSuccessfully starts false', () {
      final vm = container.read(createEditTaskViewModelProvider(null));
      expect(vm.savedSuccessfully, isFalse);
    });

    test('loadedTitle is null in create mode', () {
      final vm = container.read(createEditTaskViewModelProvider(null));
      expect(vm.loadedTitle, isNull);
    });

    test('setTitle propagates to TaskFormNotifier', () {
      container
          .read(createEditTaskViewModelProvider(null))
          .setTitle('Limpiar baño');
      expect(container.read(taskFormNotifierProvider).title, 'Limpiar baño');
    });
  });
}
