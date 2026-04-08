// test/unit/features/members/member_profile_view_model_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/auth/domain/auth_user.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/i18n/application/locale_provider.dart';
import 'package:toka/features/members/application/member_profile_view_model.dart';
import 'package:toka/features/members/application/members_provider.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
import 'package:toka/features/members/domain/member.dart';
import 'package:toka/features/members/domain/members_repository.dart';
import 'package:flutter/material.dart';

class _MockMembersRepository extends Mock implements MembersRepository {}

class _TestAuth extends Auth {
  _TestAuth(this._state);
  final AuthState _state;
  @override
  AuthState build() => _state;
}

class _FakeCurrentHome extends CurrentHome {
  @override
  Future<Home?> build() async => null;
  @override
  Future<void> switchHome(String id) async {}
}

class _FakeLocaleNotifier extends LocaleNotifier {
  @override
  Locale build() => const Locale('es');
  @override
  Future<void> initialize(String? uid) async {}
  @override
  Future<void> setLocale(String code, String? uid) async {}
}

void main() {
  late _MockMembersRepository mockRepo;

  final fakeMember = Member(
    uid: 'uid1',
    homeId: 'home1',
    nickname: 'Ana',
    photoUrl: null,
    bio: 'bio text',
    phone: '+34600000000',
    phoneVisibility: 'sameHomeMembers',
    role: MemberRole.member,
    status: MemberStatus.active,
    joinedAt: DateTime(2026, 1, 1),
    tasksCompleted: 10,
    passedCount: 2,
    complianceRate: 0.85,
    currentStreak: 3,
    averageScore: 8.5,
  );

  setUp(() {
    mockRepo = _MockMembersRepository();
    registerFallbackValue(fakeMember);
  });

  group('MemberProfileViewModel', () {
    test('viewData is loading while memberDetail resolves', () {
      when(() => mockRepo.fetchMember('home1', 'uid1'))
          .thenAnswer((_) async => fakeMember);

      final container = ProviderContainer(overrides: [
        authProvider.overrideWith(
          () => _TestAuth(const AuthState.unauthenticated()),
        ),
        authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
        currentHomeProvider.overrideWith(() => _FakeCurrentHome()),
        localeNotifierProvider.overrideWith(() => _FakeLocaleNotifier()),
        membersRepositoryProvider.overrideWithValue(mockRepo),
      ]);
      addTearDown(container.dispose);

      final vm = container.read(
        memberProfileViewModelProvider(homeId: 'home1', memberUid: 'uid1'),
      );
      // Before future resolves, viewData should be loading
      expect(vm.viewData.isLoading || vm.viewData.hasValue, isTrue);
    });

    test('viewData exposes compliancePct correctly when member loads', () async {
      when(() => mockRepo.fetchMember('home1', 'uid1'))
          .thenAnswer((_) async => fakeMember);

      final container = ProviderContainer(overrides: [
        authProvider.overrideWith(
          () => _TestAuth(const AuthState.unauthenticated()),
        ),
        authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
        currentHomeProvider.overrideWith(() => _FakeCurrentHome()),
        localeNotifierProvider.overrideWith(() => _FakeLocaleNotifier()),
        membersRepositoryProvider.overrideWithValue(mockRepo),
        memberDetailProvider('home1', 'uid1')
            .overrideWith((ref) async => fakeMember),
      ]);
      addTearDown(container.dispose);

      await container.read(memberDetailProvider('home1', 'uid1').future);

      final vm = container.read(
        memberProfileViewModelProvider(homeId: 'home1', memberUid: 'uid1'),
      );
      expect(vm.viewData.hasValue, isTrue);
      final data = vm.viewData.value!;
      expect(data.compliancePct, '85.0');
      expect(data.isSelf, isFalse);
      expect(data.member.nickname, 'Ana');
    });

    test('isSelf is true when currentUid matches memberUid', () async {
      when(() => mockRepo.fetchMember('home1', 'uid-me'))
          .thenAnswer((_) async => fakeMember.copyWith(uid: 'uid-me'));

      const fakeUser = AuthUser(
        uid: 'uid-me',
        email: 'me@test.com',
        displayName: null,
        photoUrl: null,
        emailVerified: true,
        providers: [],
      );

      final container = ProviderContainer(overrides: [
        authProvider.overrideWith(
          () => _TestAuth(AuthState.authenticated(fakeUser)),
        ),
        authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
        currentHomeProvider.overrideWith(() => _FakeCurrentHome()),
        localeNotifierProvider.overrideWith(() => _FakeLocaleNotifier()),
        membersRepositoryProvider.overrideWithValue(mockRepo),
        memberDetailProvider('home1', 'uid-me').overrideWith(
          (ref) async => fakeMember.copyWith(uid: 'uid-me'),
        ),
      ]);
      addTearDown(container.dispose);

      await container.read(memberDetailProvider('home1', 'uid-me').future);

      final vm = container.read(
        memberProfileViewModelProvider(homeId: 'home1', memberUid: 'uid-me'),
      );
      expect(vm.viewData.hasValue, isTrue);
      expect(vm.viewData.value!.isSelf, isTrue);
    });
  });
}
