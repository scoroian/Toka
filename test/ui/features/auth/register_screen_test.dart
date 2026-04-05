import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/auth/domain/auth_repository.dart';
import 'package:toka/features/auth/domain/auth_user.dart';
import 'package:toka/features/auth/presentation/register_screen.dart';
import 'package:toka/l10n/app_localizations.dart';

GoRouter _fakeRouter() => GoRouter(
      initialLocation: '/register',
      routes: [
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(path: '/login', builder: (_, __) => const Scaffold()),
        GoRoute(path: '/verify-email', builder: (_, __) => const Scaffold()),
      ],
    );

class _FakeAuthNotifier extends Auth {
  _FakeAuthNotifier(this._state);
  final AuthState _state;

  @override
  AuthState build() => _state;

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signInWithApple() async {}

  @override
  Future<void> signInWithEmail(String email, String password) async {}

  @override
  Future<void> register(String email, String password) async {}

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> signOut() async {}
}

class _FakeRepo implements AuthRepository {
  @override
  Stream<AuthUser?> get authStateChanges => const Stream.empty();
  @override
  AuthUser? get currentUser => null;
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
  Future<void> sendEmailVerification() => throw UnimplementedError();
  @override
  Future<void> linkWithGoogle() => throw UnimplementedError();
  @override
  Future<void> linkWithApple() => throw UnimplementedError();
  @override
  Future<void> linkWithEmailPassword(String e, String p) =>
      throw UnimplementedError();
  @override
  Future<void> updatePassword(String c, String n) =>
      throw UnimplementedError();
}

Widget _wrap({AuthState authState = const AuthState.unauthenticated()}) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(() => _FakeAuthNotifier(authState)),
      authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
      authRepositoryProvider.overrideWithValue(_FakeRepo()),
    ],
    child: MaterialApp.router(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      routerConfig: _fakeRouter(),
    ),
  );
}

void main() {
  testWidgets('shows email validation error for invalid email', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('email_field')), 'not-an-email');
    await tester.tap(find.byKey(const Key('submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Introduce un email válido'), findsOneWidget);
  });

  testWidgets('shows password min length error for short password',
      (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('email_field')), 'test@test.com');
    await tester.enterText(find.byKey(const Key('password_field')), 'short');
    await tester.enterText(
        find.byKey(const Key('confirm_password_field')), 'short');
    await tester.tap(find.byKey(const Key('submit_button')));
    await tester.pumpAndSettle();

    expect(
      find.text('La contraseña debe tener al menos 8 caracteres'),
      findsOneWidget,
    );
  });

  testWidgets('shows error when passwords do not match', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('email_field')), 'test@test.com');
    await tester.enterText(
        find.byKey(const Key('password_field')), 'password123');
    await tester.enterText(
        find.byKey(const Key('confirm_password_field')), 'different456');
    await tester.tap(find.byKey(const Key('submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
  });
}
