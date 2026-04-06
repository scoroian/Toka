import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/auth/domain/auth_user.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
import 'package:toka/features/members/application/members_provider.dart';
import 'package:toka/features/members/domain/member.dart';
import 'package:toka/features/members/domain/members_repository.dart';
import 'package:toka/features/members/presentation/member_profile_screen.dart';
import 'package:toka/l10n/app_localizations.dart';

class _MockMembersRepo implements MembersRepository {
  _MockMembersRepo(this.member);
  final Member member;

  @override
  Future<Member> fetchMember(String homeId, String uid) async => member;

  @override
  Stream<List<Member>> watchHomeMembers(String homeId) =>
      Stream.value([member]);

  @override
  Future<void> inviteMember(String homeId, String? email) async {}
  @override
  Future<String> generateInviteCode(String homeId) async => 'ABC123';
  @override
  Future<void> removeMember(String homeId, String uid) async {}
  @override
  Future<void> promoteToAdmin(String homeId, String uid) async {}
  @override
  Future<void> demoteFromAdmin(String homeId, String uid) async {}
  @override
  Future<void> transferOwnership(String homeId, String newOwnerUid) async {}
}

const _viewerUser = AuthUser(
  uid: 'uid-viewer',
  email: 'viewer@test.com',
  displayName: 'Viewer',
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

void main() {
  group('MemberProfileScreen', () {
    testWidgets(
        'perfil ajeno con phoneVisibility=hidden NO muestra teléfono',
        (tester) async {
      final member = Member(
        uid: 'uid-other',
        homeId: 'home1',
        nickname: 'Pedro',
        photoUrl: null,
        bio: 'Hola soy Pedro',
        phone: '666123456',
        phoneVisibility: 'hidden',
        role: MemberRole.member,
        status: MemberStatus.active,
        joinedAt: DateTime(2026, 1, 1),
        tasksCompleted: 5,
        passedCount: 1,
        complianceRate: 0.83,
        currentStreak: 2,
        averageScore: 8.0,
      );

      await tester.pumpWidget(
        _wrap(
          const MemberProfileScreen(homeId: 'home1', memberUid: 'uid-other'),
          overrides: [
            authProvider.overrideWith(
                () => _FakeAuth(const AuthState.authenticated(_viewerUser))),
            membersRepositoryProvider
                .overrideWith((ref) => _MockMembersRepo(member)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('member_phone_tile')), findsNothing);
      expect(find.text('666123456'), findsNothing);
    });

    testWidgets(
        'perfil ajeno con phoneVisibility=sameHomeMembers SÍ muestra teléfono',
        (tester) async {
      final member = Member(
        uid: 'uid-other',
        homeId: 'home1',
        nickname: 'Laura',
        photoUrl: null,
        bio: null,
        phone: '666123456',
        phoneVisibility: 'sameHomeMembers',
        role: MemberRole.member,
        status: MemberStatus.active,
        joinedAt: DateTime(2026, 1, 1),
        tasksCompleted: 8,
        passedCount: 0,
        complianceRate: 1.0,
        currentStreak: 8,
        averageScore: 9.5,
      );

      await tester.pumpWidget(
        _wrap(
          const MemberProfileScreen(homeId: 'home1', memberUid: 'uid-other'),
          overrides: [
            authProvider.overrideWith(
                () => _FakeAuth(const AuthState.authenticated(_viewerUser))),
            membersRepositoryProvider
                .overrideWith((ref) => _MockMembersRepo(member)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('member_phone_tile')), findsOneWidget);
      expect(find.text('666123456'), findsOneWidget);
    });

    testWidgets('perfil ajeno NO muestra notas textuales privadas',
        (tester) async {
      final member = Member(
        uid: 'uid-other',
        homeId: 'home1',
        nickname: 'Juan',
        photoUrl: null,
        bio: null,
        phone: null,
        phoneVisibility: 'hidden',
        role: MemberRole.member,
        status: MemberStatus.active,
        joinedAt: DateTime(2026, 1, 1),
        tasksCompleted: 3,
        passedCount: 0,
        complianceRate: 1.0,
        currentStreak: 3,
        averageScore: 8.0,
      );

      await tester.pumpWidget(
        _wrap(
          const MemberProfileScreen(homeId: 'home1', memberUid: 'uid-other'),
          overrides: [
            authProvider.overrideWith(
                () => _FakeAuth(const AuthState.authenticated(_viewerUser))),
            membersRepositoryProvider
                .overrideWith((ref) => _MockMembersRepo(member)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('notes_section')), findsNothing);
    });

    testWidgets('golden: pantalla de perfil ajeno', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final member = Member(
        uid: 'uid-other',
        homeId: 'home1',
        nickname: 'Laura',
        photoUrl: null,
        bio: 'Me gusta cocinar y mantener el orden',
        phone: '666123456',
        phoneVisibility: 'sameHomeMembers',
        role: MemberRole.admin,
        status: MemberStatus.active,
        joinedAt: DateTime(2026, 1, 1),
        tasksCompleted: 42,
        passedCount: 5,
        complianceRate: 0.87,
        currentStreak: 5,
        averageScore: 8.2,
      );

      await tester.pumpWidget(
        _wrap(
          const MemberProfileScreen(homeId: 'home1', memberUid: 'uid-other'),
          overrides: [
            authProvider.overrideWith(
                () => _FakeAuth(const AuthState.authenticated(_viewerUser))),
            membersRepositoryProvider
                .overrideWith((ref) => _MockMembersRepo(member)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/member_profile_screen.png'),
      );
    });
  });
}
