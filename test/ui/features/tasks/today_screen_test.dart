import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/auth/domain/auth_user.dart';
import 'package:toka/features/homes/application/dashboard_provider.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';
import 'package:toka/features/tasks/presentation/today_screen.dart';
import 'package:toka/features/tasks/presentation/widgets/today_skeleton_loader.dart';
import 'package:toka/features/tasks/presentation/widgets/today_empty_state.dart';
import 'package:toka/l10n/app_localizations.dart';

const _fakeUser = AuthUser(
  uid: 'uid1',
  email: 'u@u.com',
  displayName: 'User',
  photoUrl: null,
  emailVerified: true,
  providers: [],
);

class _FakeAuth extends Auth {
  final AuthState _state;
  _FakeAuth(this._state);
  @override
  AuthState build() => _state;
}

HomeDashboard _buildDashboard({
  List<TaskPreview> activeTasks = const [],
  List<DoneTaskPreview> doneTasks = const [],
  bool showBanner = false,
}) =>
    HomeDashboard(
      activeTasksPreview: activeTasks,
      doneTasksPreview: doneTasks,
      counters: DashboardCounters(
          totalActiveTasks: activeTasks.length,
          totalMembers: 2,
          tasksDueToday: activeTasks.length,
          tasksDoneToday: doneTasks.length),
      memberPreview: const [],
      premiumFlags: PremiumFlags.free(),
      adFlags: AdFlags(showBanner: showBanner, bannerUnit: ''),
      rescueFlags: RescueFlags.empty(),
      updatedAt: DateTime(2026, 4, 6),
    );

Widget _wrap(Widget child, {required List<Override> overrides}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es')],
        home: child,
      ),
    );

List<Override> _overrides({
  AsyncValue<HomeDashboard?> dashboardValue = const AsyncValue.data(null),
}) =>
    [
      authProvider.overrideWith(
          () => _FakeAuth(const AuthState.authenticated(_fakeUser))),
      dashboardProvider.overrideWith((ref) {
        if (dashboardValue is AsyncData<HomeDashboard?>) {
          return Stream.value(dashboardValue.value);
        }
        return const Stream.empty();
      }),
    ];

void main() {
  group('TodayScreen', () {
    testWidgets('estado de carga: muestra TodaySkeletonLoader', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TodayScreen(),
          overrides: [
            authProvider.overrideWith(
                () => _FakeAuth(const AuthState.authenticated(_fakeUser))),
            dashboardProvider.overrideWith((ref) => const Stream.empty()),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(TodaySkeletonLoader), findsOneWidget);
    });

    testWidgets('estado vacío: muestra TodayEmptyState cuando data es null',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TodayScreen(),
          overrides: _overrides(dashboardValue: const AsyncData(null)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TodayEmptyState), findsOneWidget);
    });

    testWidgets('con datos: muestra sección daily', (tester) async {
      final dashboard = _buildDashboard(
        activeTasks: [
          TaskPreview(
            taskId: 't1',
            title: 'Barrer',
            visualKind: 'emoji',
            visualValue: '🧹',
            recurrenceType: 'daily',
            currentAssigneeUid: 'uid1',
            currentAssigneeName: 'Ana',
            currentAssigneePhoto: null,
            nextDueAt: DateTime(2026, 4, 6, 18, 0),
            isOverdue: false,
            status: 'active',
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(
          const TodayScreen(),
          overrides: _overrides(dashboardValue: AsyncData(dashboard)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('section_title_daily')), findsOneWidget);
      expect(find.text('🧹 Barrer'), findsOneWidget);
    });

    testWidgets('sección sin tareas no aparece', (tester) async {
      final dashboard = _buildDashboard(
        activeTasks: [
          TaskPreview(
            taskId: 't1',
            title: 'Barrer',
            visualKind: 'emoji',
            visualValue: '🧹',
            recurrenceType: 'daily',
            currentAssigneeUid: null,
            currentAssigneeName: null,
            currentAssigneePhoto: null,
            nextDueAt: DateTime(2026, 4, 6, 18, 0),
            isOverdue: false,
            status: 'active',
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(
          const TodayScreen(),
          overrides: _overrides(dashboardValue: AsyncData(dashboard)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('section_title_weekly')), findsNothing);
      expect(find.byKey(const Key('section_title_monthly')), findsNothing);
    });

    testWidgets('usuario responsable ve botones de acción', (tester) async {
      final dashboard = _buildDashboard(
        activeTasks: [
          TaskPreview(
            taskId: 't1',
            title: 'Barrer',
            visualKind: 'emoji',
            visualValue: '🧹',
            recurrenceType: 'daily',
            currentAssigneeUid: 'uid1',
            currentAssigneeName: 'Ana',
            currentAssigneePhoto: null,
            nextDueAt: DateTime(2026, 4, 6, 18, 0),
            isOverdue: false,
            status: 'active',
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(
          const TodayScreen(),
          overrides: _overrides(dashboardValue: AsyncData(dashboard)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_done')), findsOneWidget);
      expect(find.byKey(const Key('btn_pass')), findsOneWidget);
    });

    testWidgets('usuario no responsable NO ve botones de acción', (tester) async {
      final dashboard = _buildDashboard(
        activeTasks: [
          TaskPreview(
            taskId: 't1',
            title: 'Barrer',
            visualKind: 'emoji',
            visualValue: '🧹',
            recurrenceType: 'daily',
            currentAssigneeUid: 'uid-otro',
            currentAssigneeName: 'Carlos',
            currentAssigneePhoto: null,
            nextDueAt: DateTime(2026, 4, 6, 18, 0),
            isOverdue: false,
            status: 'active',
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(
          const TodayScreen(),
          overrides: _overrides(dashboardValue: AsyncData(dashboard)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_done')), findsNothing);
      expect(find.byKey(const Key('btn_pass')), findsNothing);
    });

    testWidgets('golden: pantalla con datos de ejemplo', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final dashboard = _buildDashboard(
        activeTasks: [
          TaskPreview(
            taskId: 't1',
            title: 'Barrer cocina',
            visualKind: 'emoji',
            visualValue: '🧹',
            recurrenceType: 'daily',
            currentAssigneeUid: 'uid1',
            currentAssigneeName: 'Ana',
            currentAssigneePhoto: null,
            nextDueAt: DateTime(2026, 4, 6, 18, 0),
            isOverdue: false,
            status: 'active',
          ),
          TaskPreview(
            taskId: 't2',
            title: 'Lavar ropa',
            visualKind: 'emoji',
            visualValue: '👕',
            recurrenceType: 'weekly',
            currentAssigneeUid: 'uid2',
            currentAssigneeName: 'Carlos',
            currentAssigneePhoto: null,
            nextDueAt: DateTime(2026, 4, 8, 10, 0),
            isOverdue: false,
            status: 'active',
          ),
        ],
        doneTasks: [
          DoneTaskPreview(
            taskId: 'd1',
            title: 'Fregar platos',
            visualKind: 'emoji',
            visualValue: '🍽️',
            recurrenceType: 'daily',
            completedByUid: 'uid2',
            completedByName: 'Carlos',
            completedByPhoto: null,
            completedAt: DateTime(2026, 4, 6, 9, 30),
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(
          const TodayScreen(),
          overrides: _overrides(dashboardValue: AsyncData(dashboard)),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/today_screen.png'),
      );
    });
  });
}
