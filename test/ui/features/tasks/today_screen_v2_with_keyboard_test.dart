// Verifica que, al ocultarse el banner por teclado visible, el padding
// inferior del scroll de Hoy se reduce exactamente en la altura del banner
// (y que con el teclado cerrado y banner visible, el padding lo incluye).
// Spec: docs/superpowers/specs/2026-04-21-ad-banner-keyboard-and-list-bottom-design.md
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/tasks/application/today_view_model.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';
import 'package:toka/features/tasks/presentation/skins/today_screen_v2.dart';
import 'package:toka/l10n/app_localizations.dart';
import 'package:toka/shared/widgets/ad_banner.dart';
import 'package:toka/shared/widgets/ad_banner_config_provider.dart';
import 'package:toka/shared/widgets/keyboard_visible_provider.dart';
import 'package:toka/shared/widgets/skins/main_shell_v2.dart';
import 'package:toka/shared/widgets/skins/shell_presence_marker.dart';

class _MockTodayViewModel extends Mock implements TodayViewModel {}

class _FakeAuth extends Auth {
  @override
  AuthState build() => const AuthState.unauthenticated();
}

class _FakeCurrentHome extends CurrentHome {
  @override
  Future<Home?> build() async => null;
}

TodayViewData _buildData({required int todoCount}) {
  final todos = List<TaskPreview>.generate(
    todoCount,
    (i) => TaskPreview(
      taskId: 'task_$i',
      title: 'Tarea $i',
      visualKind: 'emoji',
      visualValue: '🧹',
      recurrenceType: 'daily',
      currentAssigneeUid: 'uid1',
      currentAssigneeName: 'Yo',
      currentAssigneePhoto: null,
      nextDueAt: DateTime(2026, 4, 21, 9),
      isOverdue: false,
      status: 'active',
    ),
  );
  return TodayViewData(
    grouped: {
      'daily': (todos: todos, dones: <DoneTaskPreview>[]),
    },
    counters: const DashboardCounters(
      totalActiveTasks: 10,
      totalMembers: 2,
      tasksDueToday: 10,
      tasksDoneToday: 0,
    ),
    showAdBanner: true,
    adBannerUnit: 'unit-test',
    currentUid: 'uid1',
    homeId: 'home1',
    recurrenceOrder: const ['daily'],
  );
}

Widget _wrap(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('es')],
      // En producción TodayScreenV2 siempre vive bajo MainShellV2 / Futurista;
      // el shell aporta `ShellPresenceMarker`. Aquí lo simulamos para que
      // adAwareBottomPadding NO caiga en el early-return out-of-shell.
      home: ShellPresenceMarker(child: TodayScreenV2()),
    ),
  );
}

ProviderContainer _makeContainer({
  required TodayViewModel vm,
  required AdBannerConfig bannerConfig,
  required bool keyboardVisible,
}) {
  final container = ProviderContainer(
    overrides: [
      todayViewModelProvider.overrideWith((_) => vm),
      adBannerConfigProvider.overrideWith((_) => bannerConfig),
      authProvider.overrideWith(_FakeAuth.new),
      currentHomeProvider.overrideWith(_FakeCurrentHome.new),
    ],
  );
  // Inicializamos el provider y seteamos directamente desde el container.
  container.read(keyboardVisibleProvider);
  container
      .read(keyboardVisibleProvider.notifier)
      .setVisible(keyboardVisible);
  return container;
}

double _bottomSpacerHeight(WidgetTester tester) {
  final tree = tester.widget<CustomScrollView>(find.byType(CustomScrollView));
  final lastSliver = tree.slivers.last as SliverToBoxAdapter;
  final sizedBox = lastSliver.child as SizedBox;
  return sizedBox.height ?? 0;
}

void main() {
  late _MockTodayViewModel vm;

  setUp(() {
    vm = _MockTodayViewModel();
    when(() => vm.homes).thenReturn([]);
    when(() => vm.viewData).thenReturn(AsyncValue.data(_buildData(todoCount: 12)));
  });

  testWidgets(
      'con teclado oculto y banner visible, el padding inferior incluye el banner',
      (tester) async {
    final container = _makeContainer(
      vm: vm,
      bannerConfig: const AdBannerConfig(show: true, unitId: 'unit-test'),
      keyboardVisible: false,
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(_wrap(container));
    await tester.pump();

    final padding = _bottomSpacerHeight(tester);
    // banner(58) + gap(6) + navBar(56) + navBarBottom(12) + safeArea(≈0) + extra(16)
    const expectedMin =
        AdBanner.kBannerHeight + AdBanner.kBannerGap +
        MainShellV2.kNavBarHeight + MainShellV2.kNavBarBottom +
        16;
    expect(padding, greaterThanOrEqualTo(expectedMin));
  });

  testWidgets(
      'con teclado visible, el banner desaparece del cálculo y el padding se reduce',
      (tester) async {
    // Usamos un único container y alternamos el estado del teclado para evitar
    // que el tree de Auth/CurrentHome se reconstruya y deje timers pendientes.
    final container = _makeContainer(
      vm: vm,
      bannerConfig: const AdBannerConfig(show: true, unitId: 'unit-test'),
      keyboardVisible: false,
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(_wrap(container));
    await tester.pump();
    final paddingWithBanner = _bottomSpacerHeight(tester);

    // Activamos teclado y re-renderizamos sin cambiar el container.
    container.read(keyboardVisibleProvider.notifier).setVisible(true);
    await tester.pump();
    final paddingWithKeyboard = _bottomSpacerHeight(tester);

    expect(
      paddingWithBanner - paddingWithKeyboard,
      closeTo(
        AdBanner.kBannerHeight +
            AdBanner.kBannerGap +
            MainShellV2.kNavBarHeight +
            MainShellV2.kNavBarBottom,
        0.5,
      ),
      reason: 'El padding inferior debe reducirse en ~banner+gap+navBar cuando '
          'el teclado está visible (se ocultan banner y NavBar).',
    );
  });

  testWidgets('último card queda por encima de NavBar+banner en lista larga',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = _makeContainer(
      vm: vm,
      bannerConfig: const AdBannerConfig(show: true, unitId: 'unit-test'),
      keyboardVisible: false,
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(_wrap(container));
    await tester.pump();

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Tarea 11'),
      400,
      scrollable: scrollable,
    );
    final cardPos = tester.getBottomLeft(find.text('Tarea 11'));
    final screenHeight = tester.view.physicalSize.height /
        tester.view.devicePixelRatio;
    // El último card debe quedar al menos navBar+gap por encima del borde inferior.
    const minMargin = MainShellV2.kNavBarHeight + MainShellV2.kNavBarBottom;
    expect(
      screenHeight - cardPos.dy,
      greaterThanOrEqualTo(minMargin),
      reason: 'El último card debe quedar por encima de la NavBar+banner.',
    );
  });
}
