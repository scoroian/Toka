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
  currentPayerUid: null,
  lastPayerUid: null,
  premiumStatus: HomePremiumStatus.free,
  premiumPlan: null,
  premiumEndsAt: null,
  restoreUntil: null,
  autoRenewEnabled: false,
  limits: const HomeLimits(maxMembers: 3),
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

HomeDashboard _dashboard({
  required bool isPremium,
  required String tier,
  required int maxMembers,
}) =>
    HomeDashboard.fromFirestore({
      'activeTasksPreview': [],
      'doneTasksPreview': [],
      'counters': {},
      'planCounters': {'activeMembers': 0},
      'memberPreview': [],
      'premiumFlags': {
        'isPremium': isPremium,
        'showAds': !isPremium,
        'tier': tier,
        'maxMembers': maxMembers,
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
}) =>
    [
      authProvider.overrideWith(() => _FakeAuth()),
      currentHomeProvider.overrideWith(() => _FakeCurrentHome()),
      userMembershipsProvider('uid-owner')
          .overrideWith((_) => Stream.value([_ownerMembership])),
      homeMembersProvider('home1')
          .overrideWith((_) => Stream.value(_members(memberCount))),
      leftMembersProvider('home1').overrideWith((_) => Stream.value(const [])),
      dashboardProvider.overrideWith((_) => Stream.value(dashboard)),
    ];

void main() {
  testWidgets('Free en el tope (3): banner con mensaje Free + CTA Premium',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const MembersScreenV2(),
      overrides: _overrides(
        memberCount: 3,
        dashboard:
            _dashboard(isPremium: false, tier: 'free', maxMembers: 3),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('members_free_limit_banner')), findsOneWidget);
    expect(find.byKey(const Key('members_free_limit_banner_cta')),
        findsOneWidget);
    expect(find.text('Hazte Premium'), findsWidgets);
  });

  testWidgets('Pareja premium en el tope (2): banner Pareja + CTA Subir de plan',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const MembersScreenV2(),
      overrides: _overrides(
        memberCount: 2,
        dashboard:
            _dashboard(isPremium: true, tier: 'pareja', maxMembers: 2),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('members_free_limit_banner')), findsOneWidget);
    expect(find.textContaining('Toka Pareja'), findsOneWidget);
    expect(find.text('Subir de plan'), findsOneWidget);
  });

  testWidgets('Grupo premium en el tope (10): banner Grupo SIN CTA (es el máximo)',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const MembersScreenV2(),
      overrides: _overrides(
        memberCount: 10,
        dashboard:
            _dashboard(isPremium: true, tier: 'grupo', maxMembers: 10),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('members_free_limit_banner')), findsOneWidget);
    expect(find.textContaining('Toka Grupo'), findsOneWidget);
    expect(find.byKey(const Key('members_free_limit_banner_cta')), findsNothing);
  });

  testWidgets('Familia premium por debajo del tope (4/5): sin banner',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const MembersScreenV2(),
      overrides: _overrides(
        memberCount: 4,
        dashboard:
            _dashboard(isPremium: true, tier: 'familia', maxMembers: 5),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('members_free_limit_banner')), findsNothing);
  });
}
