// test/unit/features/history/rated_events_optimistic_test.dart
//
// §11 — El botón "Valorar" debe pasar a "valorado" en VIVO tras enviar la
// valoración, sin esperar al round-trip del `snapshots()` de Firestore.
//
// `submitReview` (CF) escribe `ratedEventIds`, pero el listener puede tardar
// segundos en propagar el cambio. La marca optimista (OptimisticRatedEventIds)
// fusionada en `historyViewModel` hace que `item.isRated` pase a true al
// instante. Este test FALLA sin la marca optimista (la stream de ratedEventIds
// NO emite el id en ningún momento) y PASA con ella.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/auth/domain/auth_user.dart';
import 'package:toka/features/history/application/history_provider.dart';
import 'package:toka/features/history/application/history_view_model.dart';
import 'package:toka/features/history/application/rated_events_provider.dart';
import 'package:toka/features/history/domain/history_repository.dart';
import 'package:toka/features/history/domain/task_event.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/application/dashboard_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
import 'package:toka/features/members/application/members_provider.dart';
import 'package:toka/features/members/domain/member.dart';
import 'package:toka/features/members/domain/members_repository.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';

class _MockHistoryRepository extends Mock implements HistoryRepository {}

class _MockMembersRepository extends Mock implements MembersRepository {}

class _FakeAuth extends Auth {
  _FakeAuth(this._state);
  final AuthState _state;
  @override
  AuthState build() => _state;
}

class _FakeCurrentHome extends CurrentHome {
  _FakeCurrentHome(this._home);
  final Home? _home;
  @override
  Future<Home?> build() async => _home;
  @override
  Future<void> switchHome(String homeId) async {}
}

AuthUser _user(String uid) => AuthUser(
      uid: uid,
      email: '$uid@test.com',
      displayName: uid,
      photoUrl: null,
      emailVerified: true,
      providers: const [],
    );

Home _home() => Home(
      id: 'home1',
      name: 'Hogar QA',
      ownerUid: 'me',
      currentPayerUid: 'me',
      lastPayerUid: 'me',
      premiumStatus: HomePremiumStatus.active,
      premiumPlan: 'monthly',
      premiumEndsAt: DateTime(2026, 12),
      restoreUntil: null,
      autoRenewEnabled: true,
      limits: const HomeLimits(maxMembers: 5),
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

Member _member(String uid, String nickname) => Member(
      uid: uid,
      homeId: 'home1',
      nickname: nickname,
      photoUrl: null,
      bio: null,
      phone: null,
      phoneVisibility: 'hidden',
      role: MemberRole.member,
      status: MemberStatus.active,
      joinedAt: DateTime(2026),
      tasksCompleted: 0,
      passedCount: 0,
      complianceRate: 1.0,
      currentStreak: 0,
      averageScore: 0,
    );

HomeDashboard _premiumDashboard() => HomeDashboard(
      activeTasksPreview: const [],
      doneTasksPreview: const [],
      counters: DashboardCounters.empty(),
      planCounters: PlanCounters.empty(),
      memberPreview: const [],
      premiumFlags: const PremiumFlags(
        isPremium: true,
        showAds: false,
        canUseSmartDistribution: true,
        canUseVacations: true,
        canUseReviews: true,
      ),
      adFlags: AdFlags.empty(),
      rescueFlags: RescueFlags.empty(),
      updatedAt: DateTime(2026),
    );

final _completedByOther = TaskEvent.completed(
  id: 'evt1',
  taskId: 't1',
  taskTitleSnapshot: 'Fregar',
  taskVisualSnapshot: const TaskVisual(kind: 'emoji', value: '🧹'),
  actorUid: 'other',
  performerUid: 'other',
  completedAt: DateTime(2026, 4, 20),
  createdAt: DateTime(2026, 4, 20),
);

void main() {
  setUpAll(() {
    registerFallbackValue(const HistoryFilter());
  });

  late _MockHistoryRepository historyRepo;
  late _MockMembersRepository membersRepo;
  // Stream de ratedEventIds que NUNCA llega a emitir el id valorado, simulando
  // el retardo del listener de Firestore tras escribir la CF.
  late StreamController<Set<String>> ratedController;

  setUp(() {
    historyRepo = _MockHistoryRepository();
    membersRepo = _MockMembersRepository();
    ratedController = StreamController<Set<String>>.broadcast();

    when(() => historyRepo.fetchPage(
          homeId: any(named: 'homeId'),
          filter: any(named: 'filter'),
          startAfter: any(named: 'startAfter'),
          limit: any(named: 'limit'),
          isPremium: any(named: 'isPremium'),
        )).thenAnswer((_) async => ([_completedByOther], null));

    when(() => membersRepo.submitReview(
          homeId: any(named: 'homeId'),
          taskEventId: any(named: 'taskEventId'),
          score: any(named: 'score'),
          note: any(named: 'note'),
        )).thenAnswer((_) async {});
  });

  tearDown(() => ratedController.close());

  ProviderContainer makeContainer() {
    final container = ProviderContainer(overrides: [
      authProvider
          .overrideWith(() => _FakeAuth(AuthState.authenticated(_user('me')))),
      currentHomeProvider.overrideWith(() => _FakeCurrentHome(_home())),
      dashboardProvider.overrideWith((_) => Stream.value(_premiumDashboard())),
      homeMembersProvider('home1').overrideWith(
        (ref) => Stream.value([_member('me', 'Yo'), _member('other', 'Ana')]),
      ),
      historyRepositoryProvider.overrideWithValue(historyRepo),
      membersRepositoryProvider.overrideWithValue(membersRepo),
      ratedEventIdsProvider(homeId: 'home1', currentUid: 'me')
          .overrideWith((ref) => ratedController.stream),
    ]);
    // Mantener vivo el view model durante todo el test (autoDispose).
    container.listen(historyViewModelProvider, (_, __) {});
    return container;
  }

  Future<void> settle(ProviderContainer container) async {
    await container.read(currentHomeProvider.future);
    await container.read(dashboardProvider.future);
    await container.read(homeMembersProvider('home1').future);
    ratedController.add(<String>{}); // estado inicial: nada valorado
    await pumpEventQueue();
  }

  TaskEventItem itemFor(ProviderContainer container, String id) {
    final items = container.read(historyViewModelProvider).items.value!;
    return items.firstWhere((it) => it.raw.id == id);
  }

  test(
      'rateEvent marca isRated en vivo aunque el stream de Firestore no emita',
      () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    await settle(container);

    // Cargar la página con el evento completado por "other".
    await container
        .read(historyNotifierProvider('home1').notifier)
        .loadMore(isPremium: true);
    await pumpEventQueue();

    // ANTES de valorar: botón "Valorar" disponible.
    final before = itemFor(container, 'evt1');
    expect(before.isRated, isFalse);
    expect(before.canRate, isTrue);

    // Enviar la valoración.
    await container.read(historyViewModelProvider).rateEvent('evt1', 8.0);
    await pumpEventQueue();

    // El stream de Firestore NO ha emitido 'evt1' (sigue en {}), pero la marca
    // optimista debe haber actualizado el item en vivo.
    final after = itemFor(container, 'evt1');
    expect(after.isRated, isTrue,
        reason: 'isRated debe pasar a true al instante tras submitReview');
    expect(after.canRate, isFalse,
        reason: 'un evento ya valorado no vuelve a ofrecer "Valorar"');

    // El stream sigue sin el id → confirma que el cambio vino de la marca
    // optimista y no de Firestore.
    expect(container.read(ratedEventIdsProvider(
            homeId: 'home1', currentUid: 'me'))
        .value, isNot(contains('evt1')));
  });

  test('la marca optimista se fusiona con los ids confirmados por Firestore',
      () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    await settle(container);

    // Firestore confirma OTRO evento ya valorado previamente.
    ratedController.add({'evt_previo'});
    await pumpEventQueue();

    container
        .read(optimisticRatedEventIdsProvider('home1').notifier)
        .markRated('evt1');
    await pumpEventQueue();

    await container
        .read(historyNotifierProvider('home1').notifier)
        .loadMore(isPremium: true);
    await pumpEventQueue();

    // 'evt1' (optimista) queda marcado; el set de Firestore conserva 'evt_previo'.
    expect(itemFor(container, 'evt1').isRated, isTrue);
  });
}
