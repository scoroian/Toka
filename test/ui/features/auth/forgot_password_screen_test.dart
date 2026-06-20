// test/ui/features/auth/forgot_password_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/auth/application/forgot_password_view_model.dart';
import 'package:toka/features/auth/presentation/forgot_password_screen.dart';
import 'package:toka/l10n/app_localizations.dart';

class _MockForgotPasswordViewModel extends Mock
    implements ForgotPasswordViewModel {}

/// Fake del notifier Auth: sendPasswordReset siempre tiene éxito (no-op).
class _FakeAuth extends Auth {
  @override
  AuthState build() => const AuthState.unauthenticated();
  @override
  Future<void> sendPasswordReset(String email) async {}
}

/// Wrap con el provider REAL de forgot password (solo se fakea authProvider),
/// para ejercitar la transición resetSent=false→true y su rebuild.
Widget _wrapReal() => ProviderScope(
      overrides: [authProvider.overrideWith(() => _FakeAuth())],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('es')],
        home: ForgotPasswordScreen(),
      ),
    );

_MockForgotPasswordViewModel _defaultMock() {
  final m = _MockForgotPasswordViewModel();
  when(() => m.isLoading).thenReturn(false);
  when(() => m.resetSent).thenReturn(false);
  when(() => m.sendPasswordReset(any())).thenAnswer((_) async {});
  return m;
}

Widget _wrap({_MockForgotPasswordViewModel? vm}) => ProviderScope(
      overrides: [
        forgotPasswordViewModelProvider
            .overrideWithValue(vm ?? _defaultMock()),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('es')],
        home: ForgotPasswordScreen(),
      ),
    );

void main() {
  testWidgets('renders email TextFormField in initial state', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsOneWidget);
  });

  testWidgets('send button is enabled when not loading', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    // FilledButton should be present and enabled
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
  });

  // (El antiguo test que mockeaba forgotPasswordViewModelProvider con
  // resetSent=true se sustituyó por el test de flujo real de abajo, porque la
  // pantalla ahora observa el STATE del notifier — no el notifier derivado — y
  // _ForgotPasswordState es privado y no se puede construir en el test.)

  testWidgets(
      'provider REAL: tras enviar con éxito muestra la confirmación (rebuild)',
      (tester) async {
    await tester.pumpWidget(_wrapReal());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'luna@test.com');
    await tester.tap(find.text('Enviar enlace'));
    await tester.pumpAndSettle();

    // La pantalla debe reconstruirse al cambiar resetSent y mostrar la
    // vista de confirmación.
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('shows validation error for invalid email format',
      (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'not-an-email');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('Introduce un email válido'), findsOneWidget);
    // Form stays visible — no confirmation icon
    expect(find.byType(TextFormField), findsOneWidget);
  });

  testWidgets('email validation error clears after correcting the email',
      (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'not-an-email');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text('Introduce un email válido'), findsOneWidget);

    // Corregir el email → el error desaparece al teclear (sin reenviar).
    await tester.enterText(find.byType(TextFormField), 'user@toka.app');
    await tester.pumpAndSettle();
    expect(find.text('Introduce un email válido'), findsNothing);
  });
}
