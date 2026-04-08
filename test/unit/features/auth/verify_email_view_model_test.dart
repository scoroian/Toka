// test/unit/features/auth/verify_email_view_model_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/verify_email_view_model.dart';
import 'package:toka/features/auth/domain/auth_repository.dart';
import 'package:toka/features/auth/domain/auth_user.dart';

class _FakeRepo implements AuthRepository {
  @override
  Stream<AuthUser?> get authStateChanges => const Stream.empty();

  @override
  AuthUser? get currentUser => const AuthUser(
        uid: 'u',
        email: 'test@test.com',
        displayName: 'U',
        photoUrl: null,
        emailVerified: false,
        providers: ['password'],
      );

  @override
  Future<void> signOut() async {}

  @override
  Future<AuthUser> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<AuthUser> signInWithApple() => throw UnimplementedError();

  @override
  Future<AuthUser> signInWithEmailPassword(String e, String p) =>
      throw UnimplementedError();

  @override
  Future<AuthUser> registerWithEmailPassword(String e, String p) =>
      throw UnimplementedError();

  @override
  Future<void> sendPasswordResetEmail(String e) => throw UnimplementedError();

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<void> linkWithGoogle() => throw UnimplementedError();

  @override
  Future<void> linkWithApple() => throw UnimplementedError();

  @override
  Future<void> linkWithEmailPassword(String e, String p) =>
      throw UnimplementedError();

  @override
  Future<void> updatePassword(String c, String n) => throw UnimplementedError();
}

void main() {
  late ProviderContainer container;
  tearDown(() => container.dispose());

  ProviderContainer makeContainer() => ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(_FakeRepo()),
        authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
      ]);

  test('email is read from currentUser on build', () {
    container = makeContainer();
    final vm = container.read(verifyEmailViewModelProvider);
    expect(vm.email, 'test@test.com');
  });

  test('isSending false initially, resendCooldownSeconds 0', () {
    container = makeContainer();
    final vm = container.read(verifyEmailViewModelProvider);
    expect(vm.isSending, false);
    expect(vm.resendCooldownSeconds, 0);
  });

  test('resendVerification is ignored when already sending', () async {
    container = makeContainer();
    container.read(verifyEmailViewModelProvider);
    // Manually set isSending = true
    final notifier =
        container.read(verifyEmailViewModelNotifierProvider.notifier);
    notifier.state =
        notifier.state.copyWith(isSending: true); // direct state manipulation
    await notifier.resendVerification(); // should be a no-op
    // isSending stays true (no second send triggered)
    expect(container.read(verifyEmailViewModelProvider).isSending, true);
  });

  test('after resendVerification cooldown is set to 60', () async {
    container = makeContainer();
    container.read(verifyEmailViewModelProvider);
    await container
        .read(verifyEmailViewModelNotifierProvider.notifier)
        .resendVerification();
    expect(container.read(verifyEmailViewModelProvider).resendCooldownSeconds,
        60);
    expect(container.read(verifyEmailViewModelProvider).isSending, false);
  });
}
