import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:toka/features/members/presentation/members_screen.dart';
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

final _fakeMembers = [
  Member(
    uid: 'uid-owner',
    homeId: 'home1',
    nickname: 'María',
    photoUrl: null,
    bio: null,
    phone: null,
    phoneVisibility: 'hidden',
    role: MemberRole.owner,
    status: MemberStatus.active,
    joinedAt: DateTime(2026, 1, 1),
    tasksCompleted: 20,
    passedCount: 2,
    complianceRate: 0.9,
    currentStreak: 5,
    averageScore: 9.0,
  ),
  Member(
    uid: 'uid-admin',
    homeId: 'home1',
    nickname: 'Carlos',
    photoUrl: null,
    bio: null,
    phone: null,
    phoneVisibility: 'hidden',
    role: MemberRole.admin,
    status: MemberStatus.active,
    joinedAt: DateTime(2026, 1, 2),
    tasksCompleted: 10,
    passedCount: 3,
    complianceRate: 0.77,
    currentStreak: 2,
    averageScore: 7.5,
  ),
];

final _ownerMembership = HomeMembership(
  homeId: 'home1',
  homeNameSnapshot: 'Casa Test',
  role: MemberRole.owner,
  billingState: BillingState.currentPayer,
  status: MemberStatus.active,
  joinedAt: DateTime(2026, 1, 1),
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

List<Override> _baseOverrides({
  AsyncValue<List<Member>> membersValue = const AsyncData([]),
  MemberRole myRole = MemberRole.owner,
}) =>
    [
      authProvider.overrideWith(
          () => _FakeAuth(const AuthState.authenticated(_ownerUser))),
      currentHomeProvider.overrideWith(() => _FakeCurrentHome()),
      userMembershipsProvider('uid-owner').overrideWith(
        (ref) => Stream.value([_ownerMembership]),
      ),
      homeMembersProvider('home1').overrideWith((ref) {
        if (membersValue is AsyncData<List<Member>>) {
          return Stream.value(membersValue.value);
        }
        return const Stream.empty();
      }),
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

void main() {
  group('MembersScreen', () {
    testWidgets('muestra lista con roles y badges correctos', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MembersScreen(),
          overrides: _baseOverrides(
              membersValue: AsyncData(_fakeMembers)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('member_card_uid-owner')), findsOneWidget);
      expect(find.byKey(const Key('member_card_uid-admin')), findsOneWidget);
      expect(find.byKey(const Key('role_badge_owner')), findsOneWidget);
      expect(find.byKey(const Key('role_badge_admin')), findsOneWidget);
    });

    testWidgets('owner ve FAB de invitar', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MembersScreen(),
          overrides: _baseOverrides(
              membersValue: AsyncData(_fakeMembers)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fab_invite')), findsOneWidget);
    });

    testWidgets('admin NO ve botón cerrar hogar (ese botón está en HomeSettings, no aquí)',
        (tester) async {
      // MembersScreen no tiene botón de cerrar hogar. Solo HomeSettingsScreen lo tiene.
      await tester.pumpWidget(
        _wrap(
          const MembersScreen(),
          overrides: _baseOverrides(
              membersValue: AsyncData(_fakeMembers),
              myRole: MemberRole.admin),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('close_home_tile')), findsNothing);
    });

    testWidgets('golden: pantalla de miembros', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(
          const MembersScreen(),
          overrides: _baseOverrides(
              membersValue: AsyncData(_fakeMembers)),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/members_screen.png'),
      );
    });
  });
}
