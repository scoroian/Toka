// test/ui/features/auth/verify_email_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/auth/application/verify_email_view_model.dart';
import 'package:toka/features/auth/presentation/verify_email_screen.dart';
import 'package:toka/l10n/app_localizations.dart';

class _MockVerifyEmailViewModel extends Mock implements VerifyEmailViewModel {}

_MockVerifyEmailViewModel _defaultMock() {
  final m = _MockVerifyEmailViewModel();
  when(() => m.email).thenReturn('user@example.com');
  when(() => m.resendCooldownSeconds).thenReturn(0);
  when(() => m.isSending).thenReturn(false);
  when(() => m.isChecking).thenReturn(false);
  when(() => m.resendVerification()).thenAnswer((_) async {});
  when(() => m.pollVerification()).thenAnswer((_) async {});
  when(() => m.cancelAndSignOut()).thenAnswer((_) async {});
  when(() => m.continueIfVerified())
      .thenAnswer((_) async => VerifyCheckOutcome.notVerified);
  return m;
}

Widget _wrap({_MockVerifyEmailViewModel? vm}) => ProviderScope(
      overrides: [
        verifyEmailViewModelProvider.overrideWithValue(vm ?? _defaultMock()),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('es')],
        // Polling desactivado en tests: un Timer.periodic vivo cuelga pumpAndSettle.
        home: VerifyEmailScreen(enablePolling: false),
      ),
    );

void main() {
  testWidgets('renders Scaffold + botón Continuar', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byKey(const Key('btn_continue_verification')), findsOneWidget);
  });

  testWidgets('Reenviar deshabilitado durante cooldown', (tester) async {
    final m = _defaultMock();
    when(() => m.resendCooldownSeconds).thenReturn(45);
    await tester.pumpWidget(_wrap(vm: m));
    await tester.pumpAndSettle();
    final button = tester.widget<OutlinedButton>(
        find.byKey(const Key('btn_resend_verification')));
    expect(button.onPressed, isNull);
  });

  testWidgets('Continuar con notVerified muestra SnackBar', (tester) async {
    final m = _defaultMock();
    when(() => m.continueIfVerified())
        .thenAnswer((_) async => VerifyCheckOutcome.notVerified);
    await tester.pumpWidget(_wrap(vm: m));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_continue_verification')));
    await tester.pump(); // resuelve el future de continueIfVerified()
    await tester.pump(); // muestra el SnackBar
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('Volver invoca cancelAndSignOut', (tester) async {
    final m = _defaultMock();
    await tester.pumpWidget(_wrap(vm: m));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_back_verification')));
    await tester.pump();
    verify(() => m.cancelAndSignOut()).called(1);
  });

  testWidgets('isChecking deshabilita Continuar', (tester) async {
    final m = _defaultMock();
    when(() => m.isChecking).thenReturn(true);
    await tester.pumpWidget(_wrap(vm: m));
    await tester.pumpAndSettle();
    final button = tester.widget<FilledButton>(
        find.byKey(const Key('btn_continue_verification')));
    expect(button.onPressed, isNull);
  });
}
