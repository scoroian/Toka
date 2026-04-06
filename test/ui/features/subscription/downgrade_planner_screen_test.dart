// test/ui/features/subscription/downgrade_planner_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/application/dashboard_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
import 'package:toka/features/members/application/members_provider.dart';
import 'package:toka/features/members/domain/member.dart';
import 'package:toka/features/subscription/application/paywall_provider.dart';
import 'package:toka/features/subscription/domain/purchase_result.dart';
import 'package:toka/features/subscription/presentation/downgrade_planner_screen.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';
import 'package:toka/l10n/app_localizations.dart';

final _rescueHome = Home(
  id: 'h1',
  name: 'Test',
  ownerUid: 'owner',
  currentPayerUid: 'owner',
  lastPayerUid: null,
  premiumStatus: HomePremiumStatus.rescue,
  premiumPlan: 'monthly',
  premiumEndsAt: DateTime.now().add(const Duration(days: 2)),
  restoreUntil: null,
  autoRenewEnabled: false,
  limits: const HomeLimits(maxMembers: 10),
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

class _FakeCurrentHome extends CurrentHome {
  @override
  Future<Home?> build() async => _rescueHome;
}

class _FakePaywall extends Paywall {
  @override
  AsyncValue<PurchaseResult?> build() {
    ref.onDispose(() {});
    return const AsyncValue.data(null);
  }
}

List<Member> _fiveMembers() => [
      Member(
          uid: 'owner',
          homeId: 'h1',
          nickname: 'Owner',
          photoUrl: null,
          bio: null,
          phone: null,
          phoneVisibility: 'none',
          role: MemberRole.owner,
          status: MemberStatus.active,
          joinedAt: DateTime(2026),
          tasksCompleted: 10,
          passedCount: 0,
          complianceRate: 1.0,
          currentStreak: 5,
          averageScore: 4.5),
      Member(
          uid: 'm1',
          homeId: 'h1',
          nickname: 'Alice',
          photoUrl: null,
          bio: null,
          phone: null,
          phoneVisibility: 'none',
          role: MemberRole.member,
          status: MemberStatus.active,
          joinedAt: DateTime(2026),
          tasksCompleted: 8,
          passedCount: 1,
          complianceRate: 0.89,
          currentStreak: 3,
          averageScore: 4.0),
      Member(
          uid: 'm2',
          homeId: 'h1',
          nickname: 'Bob',
          photoUrl: null,
          bio: null,
          phone: null,
          phoneVisibility: 'none',
          role: MemberRole.member,
          status: MemberStatus.active,
          joinedAt: DateTime(2026),
          tasksCompleted: 5,
          passedCount: 2,
          complianceRate: 0.71,
          currentStreak: 2,
          averageScore: 3.5),
      Member(
          uid: 'm3',
          homeId: 'h1',
          nickname: 'Carol',
          photoUrl: null,
          bio: null,
          phone: null,
          phoneVisibility: 'none',
          role: MemberRole.member,
          status: MemberStatus.active,
          joinedAt: DateTime(2026),
          tasksCompleted: 3,
          passedCount: 3,
          complianceRate: 0.50,
          currentStreak: 0,
          averageScore: 3.0),
      Member(
          uid: 'm4',
          homeId: 'h1',
          nickname: 'Dave',
          photoUrl: null,
          bio: null,
          phone: null,
          phoneVisibility: 'none',
          role: MemberRole.member,
          status: MemberStatus.active,
          joinedAt: DateTime(2026),
          tasksCompleted: 1,
          passedCount: 4,
          complianceRate: 0.20,
          currentStreak: 0,
          averageScore: 2.5),
    ];

HomeDashboard _emptyDashboard() => HomeDashboard(
      activeTasksPreview: [],
      doneTasksPreview: [],
      counters: DashboardCounters.empty(),
      memberPreview: [],
      premiumFlags: PremiumFlags.free(),
      adFlags: AdFlags.empty(),
      rescueFlags: RescueFlags.empty(),
      updatedAt: DateTime(2026),
    );

Widget _wrap(Widget child, {List<Override> overrides = const []}) =>
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

void main() {
  final overrides = <Override>[
    currentHomeProvider.overrideWith(() => _FakeCurrentHome()),
    homeMembersProvider('h1').overrideWith((ref) => Stream.value(_fiveMembers())),
    dashboardProvider.overrideWith((_) => Stream.value(_emptyDashboard())),
    paywallProvider.overrideWith(() => _FakePaywall()),
  ];

  testWidgets('DowngradePlannerScreen: owner siempre marcado y no desseleccionable',
      (tester) async {
    await tester.pumpWidget(
        _wrap(const DowngradePlannerScreen(), overrides: overrides));
    await tester.pumpAndSettle();

    final ownerCheckbox = tester.widget<CheckboxListTile>(
        find.byKey(const Key('member_check_owner')));
    expect(ownerCheckbox.value, true);
    expect(ownerCheckbox.onChanged, isNull);
  });

  testWidgets('DowngradePlannerScreen: botón Guardar plan está presente',
      (tester) async {
    await tester.pumpWidget(
        _wrap(const DowngradePlannerScreen(), overrides: overrides));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn_save_plan')), findsOneWidget);
  });

  testWidgets('DowngradePlannerScreen: muestra 5 miembros en la lista',
      (tester) async {
    await tester.pumpWidget(
        _wrap(const DowngradePlannerScreen(), overrides: overrides));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('member_check_owner')), findsOneWidget);
    expect(find.byKey(const Key('member_check_m1')), findsOneWidget);
    expect(find.byKey(const Key('member_check_m2')), findsOneWidget);
  });
}
