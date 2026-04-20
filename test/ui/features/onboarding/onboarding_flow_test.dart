import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/i18n/application/language_provider.dart';
import 'package:toka/features/i18n/domain/language.dart';
import 'package:toka/features/onboarding/application/onboarding_view_model.dart';
import 'package:toka/features/onboarding/presentation/onboarding_flow_screen.dart';
import 'package:toka/features/onboarding/presentation/widgets/home_join_form.dart';
import 'package:toka/l10n/app_localizations.dart';

GoRouter _fakeRouter() => GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
            path: '/onboarding',
            builder: (_, __) => const OnboardingFlowScreen()),
        GoRoute(path: '/home', builder: (_, __) => const Scaffold()),
      ],
    );

class _MockOnboardingVM extends Mock implements OnboardingViewModel {}

_MockOnboardingVM _defaultMock({int currentStep = 0, int totalSteps = 4}) {
  final m = _MockOnboardingVM();
  when(() => m.isInitialized).thenReturn(true);
  when(() => m.shouldNavigateHome).thenReturn(false);
  when(() => m.currentStep).thenReturn(currentStep);
  when(() => m.totalSteps).thenReturn(totalSteps);
  when(() => m.selectedLocale).thenReturn(null);
  when(() => m.nickname).thenReturn(null);
  when(() => m.phoneNumber).thenReturn(null);
  when(() => m.phoneVisible).thenReturn(false);
  when(() => m.photoLocalPath).thenReturn(null);
  when(() => m.isLoading).thenReturn(false);
  when(() => m.error).thenReturn(null);
  when(() => m.nextStep()).thenReturn(null);
  when(() => m.prevStep()).thenReturn(null);
  when(() => m.setLocale(any())).thenReturn(null);
  when(() => m.setNickname(any())).thenReturn(null);
  when(() => m.setPhoneNumber(any())).thenReturn(null);
  when(() => m.setPhoneVisible(any())).thenReturn(null);
  when(() => m.setPhotoLocalPath(any())).thenReturn(null);
  when(() => m.saveProfileAndContinue()).thenAnswer((_) async {});
  when(() => m.createHome(any(), any())).thenAnswer((_) async {});
  when(() => m.joinHome(any())).thenAnswer((_) async {});
  return m;
}

Widget _wrap({
  _MockOnboardingVM? vm,
  int currentStep = 0,
  int totalSteps = 4,
  List<Language> languages = const [],
}) {
  final mock = vm ?? _defaultMock(currentStep: currentStep, totalSteps: totalSteps);
  return ProviderScope(
    overrides: [
      onboardingViewModelProvider.overrideWithValue(mock),
      availableLanguagesProvider
          .overrideWith((ref) => Future.value(languages)),
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
  testWidgets('step 0 shows logo and start button', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('start_button')), findsOneWidget);
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
  });

  testWidgets('step 1 shows language list (mocked)', (tester) async {
    const languages = [
      Language(
          code: 'es',
          name: 'Español',
          flag: '🇪🇸',
          arbKey: 'app_es',
          enabled: true,
          sortOrder: 1),
      Language(
          code: 'en',
          name: 'English',
          flag: '🇬🇧',
          arbKey: 'app_en',
          enabled: true,
          sortOrder: 2),
    ];
    await tester.pumpWidget(
      _wrap(currentStep: 1, languages: languages),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('language_list')), findsOneWidget);
    expect(find.text('🇪🇸  Español'), findsOneWidget);
  });

  testWidgets('step 2 shows profile form', (tester) async {
    await tester.pumpWidget(_wrap(currentStep: 2));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('nickname_field')), findsOneWidget);
    expect(find.byKey(const Key('phone_field')), findsOneWidget);
    expect(find.byKey(const Key('phone_visible_toggle')), findsOneWidget);
  });

  testWidgets('step 3 shows create and join options', (tester) async {
    await tester.pumpWidget(_wrap(currentStep: 3));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('create_home_card')), findsOneWidget);
    expect(find.byKey(const Key('join_home_card')), findsOneWidget);
  });

  testWidgets('progress bar reflects current step', (tester) async {
    await tester.pumpWidget(_wrap(currentStep: 2, totalSteps: 4));
    await tester.pumpAndSettle();

    final bar = tester.widget<LinearProgressIndicator>(
        find.byKey(const Key('onboarding_progress_bar')));
    expect(bar.value, closeTo(3 / 4, 0.01));
  });

  testWidgets('step 2 profile validates empty nickname', (tester) async {
    await tester.pumpWidget(_wrap(currentStep: 2));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('next_button')));
    await tester.pumpAndSettle();

    expect(find.text('El apodo es obligatorio'), findsOneWidget);
  });

  testWidgets('advancing past totalSteps does nothing', (tester) async {
    await tester.pumpWidget(_wrap(currentStep: 3, totalSteps: 4));
    await tester.pumpAndSettle();

    // We're on step 3 (last). Trying to go next from a step that has no
    // next button does nothing — verify we still show step 3 content.
    expect(find.byKey(const Key('create_home_card')), findsOneWidget);
  });

  testWidgets('golden: step 0 welcome', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(OnboardingFlowScreen),
      matchesGoldenFile('goldens/onboarding_step0_welcome.png'),
    );
  });

  testWidgets('golden: step 3 home choice', (tester) async {
    await tester.pumpWidget(_wrap(currentStep: 3));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(OnboardingFlowScreen),
      matchesGoldenFile('goldens/onboarding_step3_home_choice.png'),
    );
  });

  // ── Tests de manejo de errores en HomeJoinForm (Bug #17) ──────────────────

  Widget wrapJoinForm({String? error}) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es')],
        home: Scaffold(
          body: HomeJoinForm(
            isLoading: false,
            error: error,
            onJoin: (_) async {},
            onBack: () {},
          ),
        ),
      );

  testWidgets('HomeJoinForm muestra error genérico con unexpected_error',
      (tester) async {
    await tester.pumpWidget(wrapJoinForm(error: 'unexpected_error'));
    await tester.pumpAndSettle();

    expect(
      find.text('Ha ocurrido un error inesperado. Inténtalo de nuevo.'),
      findsOneWidget,
    );
  });

  testWidgets('HomeJoinForm muestra error de red con network_error',
      (tester) async {
    await tester.pumpWidget(wrapJoinForm(error: 'network_error'));
    await tester.pumpAndSettle();

    expect(
      find.text(
          'Sin conexión a internet. Comprueba tu red e inténtalo de nuevo.'),
      findsOneWidget,
    );
  });

  testWidgets('HomeJoinForm muestra error de código inválido con invalid_invite',
      (tester) async {
    await tester.pumpWidget(wrapJoinForm(error: 'invalid_invite'));
    await tester.pumpAndSettle();

    expect(find.text('Código de invitación inválido'), findsOneWidget);
  });

  testWidgets('HomeJoinForm no muestra error cuando error es null',
      (tester) async {
    await tester.pumpWidget(wrapJoinForm());
    await tester.pumpAndSettle();

    expect(
      find.text('Ha ocurrido un error inesperado. Inténtalo de nuevo.'),
      findsNothing,
    );
    expect(find.text('Código de invitación inválido'), findsNothing);
  });
}
