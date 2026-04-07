// test/ui/features/auth/login_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/auth/application/login_view_model.dart';
import 'package:toka/features/auth/presentation/login_screen.dart';
import 'package:toka/l10n/app_localizations.dart';

class _MockLoginViewModel extends Mock implements LoginViewModel {}

GoRouter _fakeRouter() => GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const Scaffold()),
        GoRoute(
            path: '/forgot-password', builder: (_, __) => const Scaffold()),
        GoRoute(path: '/home', builder: (_, __) => const Scaffold()),
      ],
    );

_MockLoginViewModel _defaultMock() {
  final m = _MockLoginViewModel();
  when(() => m.isLoading).thenReturn(false);
  when(() => m.error).thenReturn(null);
  when(() => m.isAuthenticated).thenReturn(false);
  when(() => m.signInWithGoogle()).thenAnswer((_) async {});
  when(() => m.signInWithApple()).thenAnswer((_) async {});
  when(() => m.signInWithEmail(any(), any())).thenAnswer((_) async {});
  when(() => m.clearError()).thenReturn(null);
  return m;
}

Widget _wrap({_MockLoginViewModel? vm}) {
  return ProviderScope(
    overrides: [
      loginViewModelProvider.overrideWithValue(vm ?? _defaultMock()),
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
    final m = _MockLoginViewModel();
    when(() => m.isLoading).thenReturn(true);
    when(() => m.error).thenReturn(null);
    when(() => m.isAuthenticated).thenReturn(false);
    await tester.pumpWidget(_wrap(vm: m));
    await tester.pump();
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
