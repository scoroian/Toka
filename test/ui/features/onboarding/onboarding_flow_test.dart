import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/homes/application/join_home_error.dart';
import 'package:toka/features/i18n/application/language_provider.dart';
import 'package:toka/features/i18n/domain/language.dart';
import 'package:toka/features/i18n/domain/languages_result.dart';
import 'package:toka/features/onboarding/application/onboarding_provider.dart';
import 'package:toka/features/onboarding/application/onboarding_state.dart';
import 'package:toka/features/onboarding/application/onboarding_view_model.dart';
import 'package:toka/features/onboarding/presentation/onboarding_flow_screen.dart';
import 'package:toka/features/onboarding/presentation/steps/skins/home_choice_step_v2.dart';
import 'package:toka/features/onboarding/presentation/steps/skins/profile_step_v2.dart';
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

/// El OnboardingFlowScreen lee currentStep/totalSteps de onboardingNotifierProvider
/// (no del mock). Este fake fija ese estado y deja loadSavedProgress como no-op
/// para no tocar SharedPreferences ni reescribir el paso durante la init del
/// onboardingViewModelNotifierProvider real (que pone isInitialized=true).
class _FakeOnboardingNotifier extends OnboardingNotifier {
  _FakeOnboardingNotifier(this._initial);
  final OnboardingState _initial;

  @override
  OnboardingState build() => _initial;

  @override
  Future<void> loadSavedProgress() async {}
}

_MockOnboardingVM _defaultMock({
  int currentStep = 0,
  int totalSteps = 4,
  bool phoneVisible = false,
  String? phoneNumber,
}) {
  final m = _MockOnboardingVM();
  when(() => m.isInitialized).thenReturn(true);
  when(() => m.shouldNavigateHome).thenReturn(false);
  when(() => m.currentStep).thenReturn(currentStep);
  when(() => m.totalSteps).thenReturn(totalSteps);
  when(() => m.selectedLocale).thenReturn(null);
  when(() => m.nickname).thenReturn(null);
  when(() => m.phoneNumber).thenReturn(phoneNumber);
  when(() => m.phoneVisible).thenReturn(phoneVisible);
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
  when(() => m.clearError()).thenReturn(null);
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
      onboardingNotifierProvider.overrideWith(
        () => _FakeOnboardingNotifier(
          OnboardingState(currentStep: currentStep, totalSteps: totalSteps),
        ),
      ),
      availableLanguagesProvider.overrideWith(
          (ref) => Future.value(LanguagesResult(languages: languages))),
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

  // Se prueba HomeChoiceStepV2 aislado (igual que ProfileStepV2) para no
  // depender de la animación del PageView ni del GoRouter del flow completo.
  Widget wrapHomeChoiceStep() => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es')],
        home: Scaffold(
          body: HomeChoiceStepV2(
            isLoading: false,
            error: null,
            onCreateHome: (_, __) async {},
            onJoinHome: (_) async {},
            onPrev: () {},
          ),
        ),
      );

  testWidgets('HomeChoiceStepV2 título cambia a "Crea tu hogar" al elegir crear',
      (tester) async {
    await tester.pumpWidget(wrapHomeChoiceStep());
    await tester.pumpAndSettle();

    // En la elección inicial se ve el título de la pantalla.
    expect(find.text('¿Qué quieres hacer?'), findsOneWidget);
    expect(find.text('Crea tu hogar'), findsNothing);

    // Al entrar al subformulario de crear, el título es propio y el anterior
    // desaparece (antes persistía "¿Qué quieres hacer?").
    await tester.tap(find.byKey(const Key('create_home_card')));
    await tester.pumpAndSettle();

    expect(find.text('Crea tu hogar'), findsOneWidget);
    expect(find.text('¿Qué quieres hacer?'), findsNothing);
    expect(find.byKey(const Key('home_name_field')), findsOneWidget);
  });

  testWidgets(
      'HomeChoiceStepV2 título cambia a "Únete a un hogar" al elegir unirse',
      (tester) async {
    await tester.pumpWidget(wrapHomeChoiceStep());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('join_home_card')));
    await tester.pumpAndSettle();

    expect(find.text('Únete a un hogar'), findsOneWidget);
    expect(find.text('¿Qué quieres hacer?'), findsNothing);
    expect(find.byKey(const Key('invite_code_field')), findsOneWidget);
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

  // Se prueba ProfileStepV2 aislado (no a través del flow) para no depender de
  // la animación del PageView del OnboardingFlowScreen.
  Widget wrapProfileStep() => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es')],
        home: Scaffold(
          body: ProfileStepV2(
            nickname: null,
            phoneNumber: null,
            phoneVisible: false,
            photoLocalPath: null,
            isLoading: false,
            error: null,
            onNicknameChanged: (_) {},
            onPhoneChanged: (_) {},
            onPhoneVisibleChanged: (_) {},
            onPhotoChanged: (_) {},
            onNext: () {},
            onPrev: () {},
          ),
        ),
      );

  testWidgets(
      'ProfileStepV2 limpia el error del apodo al escribir uno válido',
      (tester) async {
    await tester.pumpWidget(wrapProfileStep());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('next_button')));
    await tester.pumpAndSettle();
    expect(find.text('El apodo es obligatorio'), findsOneWidget);

    // Al escribir un apodo válido, el error desaparece sin reenviar.
    await tester.enterText(find.byKey(const Key('nickname_field')), 'Seba');
    await tester.pumpAndSettle();
    expect(find.text('El apodo es obligatorio'), findsNothing);
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

  testWidgets('HomeJoinForm muestra error genérico con motivo unexpected',
      (tester) async {
    await tester
        .pumpWidget(wrapJoinForm(error: JoinHomeError.unexpected.name));
    await tester.pumpAndSettle();

    expect(
      find.text('Algo salió mal. Inténtalo de nuevo.'),
      findsOneWidget,
    );
  });

  testWidgets('HomeJoinForm muestra error de red con motivo network',
      (tester) async {
    await tester.pumpWidget(wrapJoinForm(error: JoinHomeError.network.name));
    await tester.pumpAndSettle();

    expect(
      find.text(
          'Sin conexión a internet. Comprueba tu red e inténtalo de nuevo.'),
      findsOneWidget,
    );
  });

  testWidgets('HomeJoinForm muestra "hogar lleno" con motivo homeFull '
      '(Hallazgo #04: ya NO cae en "Algo salió mal")', (tester) async {
    await tester.pumpWidget(wrapJoinForm(error: JoinHomeError.homeFull.name));
    await tester.pumpAndSettle();

    expect(
      find.text(
          'Este hogar ya está completo. Pídele a un administrador que amplíe '
          'el plan o libere una plaza.'),
      findsOneWidget,
    );
    // Y NO el genérico.
    expect(find.text('Algo salió mal. Inténtalo de nuevo.'), findsNothing);
  });

  testWidgets('HomeJoinForm muestra error de código inválido con motivo '
      'invalidCode', (tester) async {
    await tester
        .pumpWidget(wrapJoinForm(error: JoinHomeError.invalidCode.name));
    await tester.pumpAndSettle();

    expect(find.text('Código de invitación inválido'), findsOneWidget);
  });

  testWidgets('HomeJoinForm no muestra error cuando error es null',
      (tester) async {
    await tester.pumpWidget(wrapJoinForm());
    await tester.pumpAndSettle();

    expect(
      find.text('Algo salió mal. Inténtalo de nuevo.'),
      findsNothing,
    );
    expect(find.text('Código de invitación inválido'), findsNothing);
  });

  testWidgets(
      'HomeJoinForm limpia el error de longitud al completar el código',
      (tester) async {
    await tester.pumpWidget(wrapJoinForm());
    await tester.pumpAndSettle();

    // Submit con el campo vacío → error de longitud.
    await tester.tap(find.byKey(const Key('join_button')));
    await tester.pumpAndSettle();
    expect(find.text('El código debe tener 6 caracteres'), findsOneWidget);

    // Al completar los 6 caracteres, el error desaparece al teclear.
    await tester.enterText(
        find.byKey(const Key('invite_code_field')), 'ABC123');
    await tester.pumpAndSettle();
    expect(find.text('El código debe tener 6 caracteres'), findsNothing);
  });

  // Host con estado que simula el view model: al editar el código se llama a
  // onClearError, que pone el error a null (como hace OnboardingNotifier).
  Widget wrapJoinFormStateful({required String initialError}) {
    String? error = initialError;
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => HomeJoinForm(
            isLoading: false,
            error: error,
            onJoin: (_) async {},
            onBack: () {},
            onClearError: () => setState(() => error = null),
          ),
        ),
      ),
    );
  }

  testWidgets(
      'HomeJoinForm limpia el error de servidor al editar el código',
      (tester) async {
    await tester.pumpWidget(
        wrapJoinFormStateful(initialError: JoinHomeError.invalidCode.name));
    await tester.pumpAndSettle();
    expect(find.text('Código de invitación inválido'), findsOneWidget);

    // Al corregir el código, el error de servidor desaparece sin reenviar.
    await tester.enterText(
        find.byKey(const Key('invite_code_field')), 'XYZ789');
    await tester.pumpAndSettle();
    expect(find.text('Código de invitación inválido'), findsNothing);
  });

  // ── Hallazgo #09: aviso de transparencia en el form de unión ──────────────
  Widget wrapJoinFormPhone({required bool phoneShared}) => MaterialApp(
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
            error: null,
            phoneShared: phoneShared,
            onJoin: (_) async {},
            onBack: () {},
          ),
        ),
      );

  testWidgets(
      'HomeJoinForm (#09) muestra el aviso de transparencia antes del botón, '
      'sin enlace Cambiar (mención textual en onboarding)', (tester) async {
    await tester.pumpWidget(wrapJoinFormPhone(phoneShared: false));
    await tester.pumpAndSettle();

    // El aviso está presente y antes del botón Unirme.
    expect(find.byKey(const Key('join_privacy_notice')), findsOneWidget);
    expect(find.byKey(const Key('join_button')), findsOneWidget);
    // En onboarding no hay enlace navegable: mención textual.
    expect(find.byKey(const Key('join_privacy_change_visibility')), findsNothing);
    expect(
        find.text('Puedes ajustar la visibilidad de tu teléfono en tu perfil.'),
        findsOneWidget);
    // Teléfono oculto → no promete mostrarlo.
    expect(find.text('Tu teléfono permanece oculto.'), findsOneWidget);
  });

  testWidgets(
      'HomeJoinForm (#09) con phoneShared=true promete teléfono visible',
      (tester) async {
    await tester.pumpWidget(wrapJoinFormPhone(phoneShared: true));
    await tester.pumpAndSettle();

    expect(find.text('Tu teléfono también será visible para ellos.'),
        findsOneWidget);
    expect(find.text('Tu teléfono permanece oculto.'), findsNothing);
  });

  // ── Hallazgo #09: propagación end-to-end desde el flow real ──────────────
  // Estos tests montan el OnboardingFlowScreen COMPLETO (no HomeJoinForm
  // directamente) para verificar que el cálculo en onboarding_flow_screen.dart
  // (`phoneShared: vm.phoneVisible && (vm.phoneNumber?.trim().isNotEmpty ?? false)`)
  // se propaga correctamente a través de HomeChoiceStep → HomeChoiceStepV2 →
  // HomeJoinForm → JoinPrivacyNotice.
  // Una regresión que rompa la propagación (p.ej. hardcodear phoneShared:false)
  // fallaría aquí pero NO en wrapJoinFormPhone, que instancia HomeJoinForm directo.

  testWidgets(
      '#09 flow end-to-end: phoneVisible+número real → aviso "teléfono visible" '
      'llega hasta JoinPrivacyNotice (prueba toda la cadena de propagación)',
      (tester) async {
    // phoneVisible=true y número no vacío → AND verdadero → phoneShared=true
    final vm = _defaultMock(
      currentStep: 3,
      phoneVisible: true,
      phoneNumber: '+34600000000',
    );
    await tester.pumpWidget(_wrap(vm: vm, currentStep: 3));
    await tester.pumpAndSettle();

    // Navegar al sub-form de unión igual que el test existente (línea ~203)
    await tester.tap(find.byKey(const Key('join_home_card')));
    await tester.pumpAndSettle();

    // El flow calculó phoneShared=true y lo propagó: debe aparecer el aviso
    // de teléfono visible, NO el de oculto.
    expect(
      find.text('Tu teléfono también será visible para ellos.'),
      findsOneWidget,
    );
    expect(find.text('Tu teléfono permanece oculto.'), findsNothing);
  });

  testWidgets(
      '#09 flow end-to-end: phoneVisible=true pero número vacío → AND falso → '
      'aviso "teléfono oculto" (verifica que el AND con phoneNumber se respeta)',
      (tester) async {
    // phoneVisible=true pero número vacío → AND falso → phoneShared=false
    final vm = _defaultMock(
      currentStep: 3,
      phoneVisible: true,
      phoneNumber: '',
    );
    await tester.pumpWidget(_wrap(vm: vm, currentStep: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('join_home_card')));
    await tester.pumpAndSettle();

    // El número vacío hace que el AND sea false → phoneShared=false →
    // el aviso debe ser "teléfono permanece oculto".
    expect(find.text('Tu teléfono permanece oculto.'), findsOneWidget);
    expect(
      find.text('Tu teléfono también será visible para ellos.'),
      findsNothing,
    );
  });
}
