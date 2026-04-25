// test/ui/features/subscription/skins/futurista/downgrade_planner_screen_futurista_test.dart
//
// Smoke tests del wrapper `DowngradePlannerScreen`:
//   - Por defecto (skin v2) renderiza `DowngradePlannerScreenV2`.
//   - Con skin futurista persistido en SharedPreferences renderiza
//     `DowngradePlannerScreenFuturista`.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toka/core/theme/app_skin.dart';
import 'package:toka/core/theme/skin_provider.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/application/dashboard_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
import 'package:toka/features/members/application/members_provider.dart';
import 'package:toka/features/members/domain/member.dart';
import 'package:toka/features/subscription/application/paywall_provider.dart';
import 'package:toka/features/subscription/domain/purchase_result.dart';
import 'package:toka/features/subscription/presentation/skins/downgrade_planner_screen.dart';
import 'package:toka/features/subscription/presentation/skins/downgrade_planner_screen_v2.dart';
import 'package:toka/features/subscription/presentation/skins/futurista/downgrade_planner_screen_futurista.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';
import 'package:toka/l10n/app_localizations.dart';

final _home = Home(
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
  Future<Home?> build() async => _home;
}

class _FakePaywall extends Paywall {
  @override
  AsyncValue<PurchaseResult?> build() {
    ref.onDispose(() {});
    return const AsyncValue.data(null);
  }
}

List<Member> _members() => [
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
    ];

HomeDashboard _emptyDashboard() => HomeDashboard(
      activeTasksPreview: [],
      doneTasksPreview: [],
      counters: DashboardCounters.empty(),
      planCounters: PlanCounters.empty(),
      memberPreview: [],
      premiumFlags: PremiumFlags.free(),
      adFlags: AdFlags.empty(),
      rescueFlags: RescueFlags.empty(),
      updatedAt: DateTime(2026),
    );

Widget _harness({List<Override> overrides = const []}) => ProviderScope(
      overrides: overrides,
      child: const MaterialApp(
        locale: Locale('es'),
        supportedLocales: [Locale('es'), Locale('en'), Locale('ro')],
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: DowngradePlannerScreen(),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  final baseOverrides = <Override>[
    currentHomeProvider.overrideWith(_FakeCurrentHome.new),
    homeMembersProvider('h1').overrideWith((ref) => Stream.value(_members())),
    dashboardProvider.overrideWith((_) => Stream.value(_emptyDashboard())),
    paywallProvider.overrideWith(_FakePaywall.new),
  ];

  testWidgets('wrapper renders v2 by default', (tester) async {
    await tester.pumpWidget(_harness(overrides: baseOverrides));
    await tester.pump();
    expect(find.byType(DowngradePlannerScreenV2), findsOneWidget);
    expect(find.byType(DowngradePlannerScreenFuturista), findsNothing);
  });

  testWidgets('wrapper renders futurista when skin = futurista',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {SkinMode.persistKey: AppSkin.futurista.persistKey});
    await tester.pumpWidget(_harness(overrides: baseOverrides));
    // Pumps discretos para resolver microtask de SkinMode._load() y la
    // transición del AnimatedSwitcher (220ms).
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    expect(find.byType(DowngradePlannerScreenFuturista), findsOneWidget);
    expect(find.byType(DowngradePlannerScreenV2), findsNothing);
  });
}
