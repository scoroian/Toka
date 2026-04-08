// test/ui/features/auth/register_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/auth/application/register_view_model.dart';
import 'package:toka/features/auth/presentation/register_screen.dart';
import 'package:toka/l10n/app_localizations.dart';

class _MockRegisterViewModel extends Mock implements RegisterViewModel {}

GoRouter _fakeRouter() => GoRouter(
      initialLocation: '/register',
      routes: [
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(path: '/login', builder: (_, __) => const Scaffold()),
        GoRoute(path: '/verify-email', builder: (_, __) => const Scaffold()),
      ],
    );

_MockRegisterViewModel _defaultMock() {
  final m = _MockRegisterViewModel();
  when(() => m.isLoading).thenReturn(false);
  when(() => m.error).thenReturn(null);
  when(() => m.registrationComplete).thenReturn(false);
  when(() => m.register(any(), any())).thenAnswer((_) async {});
  when(() => m.clearError()).thenReturn(null);
  return m;
}

Widget _wrap({_MockRegisterViewModel? vm}) => ProviderScope(
      overrides: [
        registerViewModelProvider.overrideWithValue(vm ?? _defaultMock()),
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

void main() {
  testWidgets('renders email and password fields', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('email_field')), findsOneWidget);
    expect(find.byKey(const Key('password_field')), findsOneWidget);
  });

  testWidgets('shows spinner when loading', (tester) async {
    final m = _MockRegisterViewModel();
    when(() => m.isLoading).thenReturn(true);
    when(() => m.error).thenReturn(null);
    when(() => m.registrationComplete).thenReturn(false);
    await tester.pumpWidget(_wrap(vm: m));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });

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
