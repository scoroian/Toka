import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:toka/core/constants/routes.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/auth/domain/auth_user.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/application/homes_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
import 'package:toka/features/members/application/members_provider.dart';
import 'package:toka/features/members/domain/member.dart';
import 'package:toka/features/members/presentation/skins/members_screen_v2.dart';
import 'package:toka/l10n/app_localizations.dart';

const _ownerUser = AuthUser(
  uid: 'uid-owner',
  email: 'owner@test.com',
  displayName: 'Owner',
  photoUrl: null,
  emailVerified: true,
  providers: [],
);

final _fakeHome = Home(
  id: 'home1',
  name: 'Casa Test',
  ownerUid: 'uid-owner',
  currentPayerUid: null,
  lastPayerUid: null,
  premiumStatus: HomePremiumStatus.free,
  premiumPlan: null,
  premiumEndsAt: null,
  restoreUntil: null,
  autoRenewEnabled: false,
  limits: const HomeLimits(maxMembers: 3),
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

final _ownerMembership = HomeMembership(
  homeId: 'home1',
  homeNameSnapshot: 'Casa Test',
  role: MemberRole.owner,
  billingState: BillingState.currentPayer,
  status: MemberStatus.active,
  joinedAt: DateTime(2026, 1, 1),
);

Member _member({
  required String uid,
  required String nickname,
  required int tasksCompleted,
  required double complianceRate,
  MemberRole role = MemberRole.member,
}) =>
    Member(
      uid: uid,
      homeId: 'home1',
      nickname: nickname,
      photoUrl: null,
      bio: null,
      phone: null,
      phoneVisibility: 'hidden',
      role: role,
      status: MemberStatus.active,
      joinedAt: DateTime(2026, 1, 1),
      tasksCompleted: tasksCompleted,
      passedCount: 0,
      complianceRate: complianceRate,
      currentStreak: 0,
      averageScore: 8.0,
    );

// Desequilibrio real: balance promedio < 75 % y reparto dispar.
// 'Zoraida' es el "top" por tareas — el código viejo habría escrito "Zoraida +N".
final _unevenMembers = [
  _member(uid: 'uid-owner', nickname: 'Zoraida', tasksCompleted: 20, complianceRate: 0.55, role: MemberRole.owner),
  _member(uid: 'uid-2', nickname: 'Bruno', tasksCompleted: 2, complianceRate: 0.40),
];

final _balancedMembers = [
  _member(uid: 'uid-owner', nickname: 'Zoraida', tasksCompleted: 12, complianceRate: 0.92, role: MemberRole.owner),
  _member(uid: 'uid-2', nickname: 'Bruno', tasksCompleted: 11, complianceRate: 0.88),
];

final _soloMember = [
  _member(uid: 'uid-owner', nickname: 'Zoraida', tasksCompleted: 3, complianceRate: 0.30, role: MemberRole.owner),
];

class _FakeAuth extends Auth {
  final AuthState _state;
  _FakeAuth(this._state);
  @override
  AuthState build() => _state;
}

class _FakeCurrentHome extends CurrentHome {
  @override
  Future<Home?> build() async => _fakeHome;
}

List<Override> _overrides(List<Member> members) => [
      authProvider.overrideWith(
          () => _FakeAuth(const AuthState.authenticated(_ownerUser))),
      currentHomeProvider.overrideWith(() => _FakeCurrentHome()),
      userMembershipsProvider('uid-owner')
          .overrideWith((ref) => Stream.value([_ownerMembership])),
      homeMembersProvider('home1')
          .overrideWith((ref) => Stream.value(members)),
    ];

Widget _wrap(List<Member> members) {
  final router = GoRouter(
    initialLocation: AppRoutes.members,
    routes: [
      GoRoute(
        path: AppRoutes.members,
        builder: (_, __) => const MembersScreenV2(),
      ),
      GoRoute(
        path: AppRoutes.tasks,
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('TASKS_PAGE'))),
      ),
    ],
  );
  return ProviderScope(
    overrides: _overrides(members),
    child: MaterialApp.router(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      routerConfig: router,
    ),
  );
}

void main() {
  group('Balance card — reencuadre cooperativo (#07)', () {
    testWidgets('reparto desigual: copy cooperativo y CTA, sin nombre ni +N',
        (tester) async {
      await tester.pumpWidget(_wrap(_unevenMembers));
      await tester.pumpAndSettle();

      // Copy neutro nuevo + CTA presentes.
      expect(find.text('El reparto está algo desigual.'), findsOneWidget);
      expect(find.byKey(const Key('btn_balance_share')), findsOneWidget);
      expect(find.text('Repartir las tareas'), findsOneWidget);

      // Sin señalamiento: ni "+N" ni el copy viejo. El código antiguo habría
      // renderizado "Desequilibrado · Zoraida +18" (top 20 − resto 2 = 18).
      expect(find.textContaining('Zoraida +'), findsNothing);
      expect(find.textContaining('+18'), findsNothing);
      expect(find.textContaining('Desequilibrado'), findsNothing);
    });

    testWidgets('CTA navega a la pestaña Tareas', (tester) async {
      await tester.pumpWidget(_wrap(_unevenMembers));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_balance_share')));
      await tester.pumpAndSettle();

      expect(find.text('TASKS_PAGE'), findsOneWidget);
    });

    testWidgets('reparto equilibrado: "Bien repartido", sin CTA',
        (tester) async {
      await tester.pumpWidget(_wrap(_balancedMembers));
      await tester.pumpAndSettle();

      expect(find.text('Bien repartido'), findsOneWidget);
      expect(find.byKey(const Key('btn_balance_share')), findsNothing);
      expect(find.text('El reparto está algo desigual.'), findsNothing);
    });

    testWidgets('un solo miembro: nunca "desigual" ni CTA', (tester) async {
      await tester.pumpWidget(_wrap(_soloMember));
      await tester.pumpAndSettle();

      // Con 1 miembro no hay reparto que equilibrar → estado positivo, sin CTA.
      expect(find.byKey(const Key('btn_balance_share')), findsNothing);
      expect(find.text('El reparto está algo desigual.'), findsNothing);
      expect(find.text('Bien repartido'), findsOneWidget);
    });
  });

  group('Balance card — golden', () {
    testWidgets('golden: reparto desigual (copy neutro + CTA)',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(_unevenMembers));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/members_balance_uneven.png'),
      );
    });
  });
}
