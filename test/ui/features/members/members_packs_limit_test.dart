import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/auth/domain/auth_user.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/application/dashboard_provider.dart';
import 'package:toka/features/homes/application/homes_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
import 'package:toka/features/members/application/members_provider.dart';
import 'package:toka/features/members/domain/member.dart';
import 'package:toka/features/members/presentation/skins/members_screen_v2.dart';
import 'package:toka/features/subscription/application/member_packs_enabled_provider.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';
import 'package:toka/l10n/app_localizations.dart';

const _owner = AuthUser(
  uid: 'uid-owner',
  email: 'o@test.com',
  displayName: 'Owner',
  photoUrl: null,
  emailVerified: true,
  providers: [],
);

final _home = Home(
  id: 'home1',
  name: 'Casa',
  ownerUid: 'uid-owner',
  currentPayerUid: 'uid-owner',
  lastPayerUid: 'uid-owner',
  premiumStatus: HomePremiumStatus.active,
  premiumPlan: 'toka_grupo_annual',
  premiumEndsAt: DateTime(2027),
  restoreUntil: null,
  autoRenewEnabled: true,
  limits: const HomeLimits(maxMembers: 10),
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

final _ownerMembership = HomeMembership(
  homeId: 'home1',
  homeNameSnapshot: 'Casa',
  role: MemberRole.owner,
  billingState: BillingState.none,
  status: MemberStatus.active,
  joinedAt: DateTime(2026),
);

class _FakeAuth extends Auth {
  @override
  AuthState build() => const AuthState.authenticated(_owner);
}

class _FakeCurrentHome extends CurrentHome {
  @override
  Future<Home?> build() async => _home;
}

List<Member> _members(int n) => List.generate(
      n,
      (i) => Member(
        uid: 'm$i',
        homeId: 'home1',
        nickname: 'M$i',
        photoUrl: null,
        bio: null,
        phone: null,
        phoneVisibility: 'hidden',
        role: i == 0 ? MemberRole.owner : MemberRole.member,
        status: MemberStatus.active,
        joinedAt: DateTime(2026, 1, i + 1),
        tasksCompleted: 0,
        passedCount: 0,
        complianceRate: 1.0,
        currentStreak: 0,
        averageScore: 0.0,
      ),
    );

HomeDashboard _dashboard({required int maxMembers, bool plus5 = false, bool plus10 = false}) =>
    HomeDashboard.fromFirestore({
      'activeTasksPreview': [],
      'doneTasksPreview': [],
      'counters': {},
      'planCounters': {'activeMembers': 0},
      'memberPreview': [],
      'premiumFlags': {
        'isPremium': true,
        'showAds': false,
        'tier': 'grupo',
        'maxMembers': maxMembers,
        'memberPacks': {'plus5': plus5, 'plus10': plus10},
      },
      'adFlags': {},
      'rescueFlags': {},
      'updatedAt': Timestamp.fromDate(DateTime(2026, 6, 1)),
    });

Widget _wrap(Widget child, {required List<Override> overrides}) => ProviderScope(
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
  required int memberCount,
  required HomeDashboard dashboard,
  bool packsEnabled = true,
}) =>
    [
      authProvider.overrideWith(() => _FakeAuth()),
      memberPacksEnabledProvider.overrideWithValue(packsEnabled),
      currentHomeProvider.overrideWith(() => _FakeCurrentHome()),
      userMembershipsProvider('uid-owner')
          .overrideWith((_) => Stream.value([_ownerMembership])),
      homeMembersProvider('home1')
          .overrideWith((_) => Stream.value(_members(memberCount))),
      leftMembersProvider('home1').overrideWith((_) => Stream.value(const [])),
      dashboardProvider.overrideWith((_) => Stream.value(dashboard)),
    ];

void main() {
  testWidgets('Grupo + packs ON en el tope (10/10): banner ofrece "Añadir pack"',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const MembersScreenV2(),
      overrides: _overrides(
        memberCount: 10,
        dashboard: _dashboard(maxMembers: 10),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('members_free_limit_banner')), findsOneWidget);
    expect(find.byKey(const Key('members_free_limit_banner_cta')),
        findsOneWidget);
    expect(find.text('Añadir pack'), findsOneWidget);
    expect(find.byKey(const Key('members_business_cta')), findsNothing);
  });

  testWidgets('Grupo + packs ON con +5 (15/15): sigue ofreciendo pack',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const MembersScreenV2(),
      overrides: _overrides(
        memberCount: 15,
        dashboard: _dashboard(maxMembers: 15, plus5: true),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('members_free_limit_banner_cta')),
        findsOneWidget);
    expect(find.text('Añadir pack'), findsOneWidget);
  });

  testWidgets('Grupo + packs ON en el tope absoluto (25/25): CTA Toka Business',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const MembersScreenV2(),
      overrides: _overrides(
        memberCount: 25,
        dashboard: _dashboard(maxMembers: 25, plus5: true, plus10: true),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('members_business_cta')), findsOneWidget);
    expect(find.byKey(const Key('members_free_limit_banner_cta')), findsNothing);
    expect(find.text('Toka Business'), findsOneWidget);
  });

  testWidgets('El CTA Toka Business abre el diálogo informativo', (tester) async {
    await tester.pumpWidget(_wrap(
      const MembersScreenV2(),
      overrides: _overrides(
        memberCount: 25,
        dashboard: _dashboard(maxMembers: 25, plus5: true, plus10: true),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('members_business_cta')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('toka_business_dialog')), findsOneWidget);
  });

  testWidgets('Grupo con flag de packs OFF en 10/10: comportamiento actual (sin CTA)',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const MembersScreenV2(),
      overrides: _overrides(
        memberCount: 10,
        dashboard: _dashboard(maxMembers: 10),
        packsEnabled: false,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('members_free_limit_banner')), findsOneWidget);
    expect(find.textContaining('Toka Grupo'), findsOneWidget);
    expect(find.byKey(const Key('members_free_limit_banner_cta')), findsNothing);
    expect(find.byKey(const Key('members_business_cta')), findsNothing);
  });

  testWidgets('golden: banner tope dinámico Grupo ofrece pack (es)',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 1400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(
      const MembersScreenV2(),
      overrides: _overrides(
        memberCount: 10,
        dashboard: _dashboard(maxMembers: 10),
      ),
    ));
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const Key('members_free_limit_banner')),
      matchesGoldenFile('goldens/members_banner_packs.png'),
    );
  });

  testWidgets('golden: banner Toka Business en el tope absoluto (es)',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 1400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(
      const MembersScreenV2(),
      overrides: _overrides(
        memberCount: 25,
        dashboard: _dashboard(maxMembers: 25, plus5: true, plus10: true),
      ),
    ));
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const Key('members_free_limit_banner')),
      matchesGoldenFile('goldens/members_banner_business.png'),
    );
  });
}
