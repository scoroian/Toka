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
  when(() => m.resendVerification()).thenAnswer((_) async {});
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
        home: VerifyEmailScreen(),
      ),
    );

void main() {
  testWidgets('screen renders a Scaffold', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('has at least one FilledButton when cooldown is zero',
      (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('resend button is disabled while isSending=true', (tester) async {
    final m = _MockVerifyEmailViewModel();
    when(() => m.email).thenReturn('user@example.com');
    when(() => m.resendCooldownSeconds).thenReturn(0);
    when(() => m.isSending).thenReturn(true);
    when(() => m.resendVerification()).thenAnswer((_) async {});

    await tester.pumpWidget(_wrap(vm: m));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('resend button is disabled when cooldown > 0', (tester) async {
    final m = _MockVerifyEmailViewModel();
    when(() => m.email).thenReturn('user@example.com');
    when(() => m.resendCooldownSeconds).thenReturn(45);
    when(() => m.isSending).thenReturn(false);
    when(() => m.resendVerification()).thenAnswer((_) async {});

    await tester.pumpWidget(_wrap(vm: m));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });
}
