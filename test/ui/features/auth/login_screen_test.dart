import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/auth/domain/auth_repository.dart';
import 'package:toka/features/auth/domain/auth_user.dart';
import 'package:toka/features/auth/presentation/login_screen.dart';
import 'package:toka/l10n/app_localizations.dart';

GoRouter _fakeRouter() => GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const Scaffold()),
        GoRoute(path: '/forgot-password', builder: (_, __) => const Scaffold()),
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
  testWidgets('renders Google button and email form fields', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.text('Continuar con Google'), findsOneWidget);
    expect(find.byKey(const Key('email_field')), findsOneWidget);
    expect(find.byKey(const Key('password_field')), findsOneWidget);
  });

  testWidgets('Apple button is NOT visible on non-iOS test platform',
      (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('apple_button')), findsNothing);
  });

  testWidgets('email form shows validation errors when submitted empty',
      (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Este campo es obligatorio'), findsWidgets);
  });

  testWidgets('shows spinner when loading', (tester) async {
    await tester.pumpWidget(_wrap(authState: const AuthState.loading()));
    await tester.pump(); // no pumpAndSettle — spinner animates indefinitely

    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });

  testWidgets('golden: login screen default state', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(LoginScreen),
      matchesGoldenFile('goldens/login_screen.png'),
    );
  });
}
