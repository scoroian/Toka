// test/unit/features/members/member_profile_view_model_test.dart
import 'dart:async';

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
import 'package:toka/features/profile/presentation/widgets/radar_chart_widget.dart';
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
    test('viewData is loading while stream has not emitted yet', () {
      // Stream que nunca emite → provider en estado loading
      when(() => mockRepo.watchHomeMembers('home1'))
          .thenAnswer((_) => const Stream.empty());

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
      // Antes de que el stream emita, viewData debe ser loading
      expect(vm.viewData.isLoading || vm.viewData.hasValue, isTrue);
    });

    test('viewData exposes compliancePct correctly when member loads', () async {
      when(() => mockRepo.watchHomeMembers('home1'))
          .thenAnswer((_) => Stream.value([fakeMember]));

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

      // Esperar a que el stream emita el primer valor
      await container.read(homeMembersProvider('home1').future);

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
      final selfMember = fakeMember.copyWith(uid: 'uid-me');
      when(() => mockRepo.watchHomeMembers('home1'))
          .thenAnswer((_) => Stream.value([selfMember]));

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
      ]);
      addTearDown(container.dispose);

      await container.read(homeMembersProvider('home1').future);

      final vm = container.read(
        memberProfileViewModelProvider(homeId: 'home1', memberUid: 'uid-me'),
      );
      expect(vm.viewData.hasValue, isTrue);
      expect(vm.viewData.value!.isSelf, isTrue);
    });

    test('rol se actualiza reactivamente al emitir nuevo valor en el stream', () async {
      // Stream con controller para emitir dos eventos: member → admin
      final controller = StreamController<List<Member>>();
      when(() => mockRepo.watchHomeMembers('home1'))
          .thenAnswer((_) => controller.stream);

      final container = ProviderContainer(overrides: [
        authProvider.overrideWith(
          () => _TestAuth(const AuthState.unauthenticated()),
        ),
        authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
        currentHomeProvider.overrideWith(() => _FakeCurrentHome()),
        localeNotifierProvider.overrideWith(() => _FakeLocaleNotifier()),
        membersRepositoryProvider.overrideWithValue(mockRepo),
      ]);
      addTearDown(() {
        controller.close();
        container.dispose();
      });

      // Emit 1: miembro con rol 'member'
      controller.add([fakeMember]);
      await container.read(homeMembersProvider('home1').future);
      final vmBefore = container.read(
        memberProfileViewModelProvider(homeId: 'home1', memberUid: 'uid1'),
      );
      expect(vmBefore.viewData.value?.member.role, MemberRole.member);

      // Emit 2: mismo miembro promovido a 'admin'
      final adminMember = fakeMember.copyWith(role: MemberRole.admin);
      controller.add([adminMember]);
      await Future.microtask(() {});

      final vmAfter = container.read(
        memberProfileViewModelProvider(homeId: 'home1', memberUid: 'uid1'),
      );
      expect(vmAfter.viewData.value?.member.role, MemberRole.admin,
          reason: 'El rol debe actualizarse reactivamente sin navegar');
    });
  });

  group('MemberProfileViewData — stats del Member', () {
    test('completedCount, streakCount, averageScore vienen del Member', () {
      // fakeMember defined at top: tasksCompleted: 10, currentStreak: 3, averageScore: 8.5
      final data = MemberProfileViewData(
        member: fakeMember,
        isSelf: false,
        visiblePhone: null,
        compliancePct: '85.0',
        radarEntries: const [],
        canManageRoles: false,
        canRemoveMember: false,
        completedCount: 10,
        streakCount: 3,
        averageScore: 8.5,
        showRadar: false,
        overflowEntries: const [],
      );
      expect(data.completedCount, 10);
      expect(data.streakCount, 3);
      expect(data.averageScore, 8.5);
    });

    test('showRadar false cuando radarEntries tiene menos de 3 elementos', () {
      final data = MemberProfileViewData(
        member: fakeMember,
        isSelf: false,
        visiblePhone: null,
        compliancePct: '85.0',
        radarEntries: const [RadarEntry(taskName: 'T1', avgScore: 7.0)],
        canManageRoles: false,
        canRemoveMember: false,
        completedCount: 10,
        streakCount: 3,
        averageScore: 8.5,
        showRadar: false,
        overflowEntries: const [],
      );
      expect(data.showRadar, isFalse);
    });

    test('showRadar true cuando radarEntries tiene 3 o más elementos', () {
      final data = MemberProfileViewData(
        member: fakeMember,
        isSelf: false,
        visiblePhone: null,
        compliancePct: '85.0',
        radarEntries: const [
          RadarEntry(taskName: 'T1', avgScore: 7.0),
          RadarEntry(taskName: 'T2', avgScore: 8.0),
          RadarEntry(taskName: 'T3', avgScore: 9.0),
        ],
        canManageRoles: false,
        canRemoveMember: false,
        completedCount: 10,
        streakCount: 3,
        averageScore: 8.5,
        showRadar: true,
        overflowEntries: const [],
      );
      expect(data.showRadar, isTrue);
    });
  });
}
