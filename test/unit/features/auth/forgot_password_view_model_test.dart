// test/unit/features/auth/forgot_password_view_model_test.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/auth/application/forgot_password_view_model.dart';
import 'package:toka/features/i18n/application/locale_provider.dart';

class _FakeAuth extends Auth {
  @override
  AuthState build() => const AuthState.unauthenticated();

  void push(AuthState s) => state = s;

  @override Future<void> signInWithGoogle() async {}
  @override Future<void> signInWithApple() async {}
  @override Future<void> signInWithEmail(String e, String p) async {}
  @override Future<void> register(String e, String p) async {}
  @override Future<void> sendPasswordReset(String email) async {}
  @override Future<void> signOut() async {}
}

class _FakeLocaleNotifier extends LocaleNotifier {
  @override Locale build() => const Locale('es');
  @override Future<void> initialize(String? uid) async {}
  @override Future<void> setLocale(String code, String? uid) async {}
}

ProviderContainer _makeContainer() => ProviderContainer(overrides: [
      authProvider.overrideWith(() => _FakeAuth()),
      authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
      localeNotifierProvider.overrideWith(() => _FakeLocaleNotifier()),
    ]);

void main() {
  late ProviderContainer container;
  tearDown(() => container.dispose());

  test('initial state: not loading, not sent', () {
    container = _makeContainer();
    final vm = container.read(forgotPasswordViewModelProvider);
    expect(vm.isLoading, false);
    expect(vm.resetSent, false);
  });

  test('sendPasswordReset sets resetSent to true on completion', () async {
    container = _makeContainer();
    await container
        .read(forgotPasswordViewModelProvider)
        .sendPasswordReset('user@example.com');
    expect(container.read(forgotPasswordViewModelProvider).resetSent, true);
    expect(container.read(forgotPasswordViewModelProvider).isLoading, false);
  });
}
