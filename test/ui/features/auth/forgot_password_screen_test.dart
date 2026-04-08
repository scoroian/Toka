// test/ui/features/auth/forgot_password_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/auth/application/forgot_password_view_model.dart';
import 'package:toka/features/auth/presentation/forgot_password_screen.dart';
import 'package:toka/l10n/app_localizations.dart';

class _MockForgotPasswordViewModel extends Mock
    implements ForgotPasswordViewModel {}

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

  testWidgets('shows confirmation view (no TextFormField) when resetSent=true',
      (tester) async {
    final m = _MockForgotPasswordViewModel();
    when(() => m.isLoading).thenReturn(false);
    when(() => m.resetSent).thenReturn(true);
    when(() => m.sendPasswordReset(any())).thenAnswer((_) async {});

    await tester.pumpWidget(_wrap(vm: m));
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNothing);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
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
}
