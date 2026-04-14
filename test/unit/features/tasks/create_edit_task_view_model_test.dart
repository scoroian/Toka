// test/unit/features/tasks/create_edit_task_view_model_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/auth/domain/auth_user.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/features/i18n/application/locale_provider.dart';
import 'package:toka/features/tasks/application/create_edit_task_view_model.dart';
import 'package:toka/features/tasks/application/task_form_provider.dart';
import 'package:toka/features/tasks/application/tasks_provider.dart';
import 'package:toka/features/tasks/domain/recurrence_rule.dart';
import 'package:toka/features/tasks/domain/task.dart';
import 'package:toka/features/tasks/domain/task_status.dart';
import 'package:toka/features/tasks/domain/tasks_repository.dart';

class _MockTasksRepository extends Mock implements TasksRepository {}

class _FakeAuth extends Auth {
  _FakeAuth(this._state);
  final AuthState _state;

  @override
  AuthState build() => _state;
}

class _FakeCurrentHome extends CurrentHome {
  @override
  Future<Home?> build() async => Home(
        id: 'h1',
        name: 'Casa',
        ownerUid: 'uid1',
        currentPayerUid: null,
        lastPayerUid: null,
        premiumStatus: HomePremiumStatus.free,
        premiumPlan: null,
        premiumEndsAt: null,
        restoreUntil: null,
        autoRenewEnabled: false,
        limits: const HomeLimits(maxMembers: 5),
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

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

ProviderContainer _makeContainer({_MockTasksRepository? repo}) {
  return ProviderContainer(overrides: [
    authProvider.overrideWith(() => _FakeAuth(
          const AuthState.authenticated(
            AuthUser(
              uid: 'uid1',
              email: 'u@u.com',
              displayName: 'User',
              photoUrl: null,
              emailVerified: true,
              providers: [],
            ),
          ),
        )),
    authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
    currentHomeProvider.overrideWith(() => _FakeCurrentHome()),
    localeNotifierProvider.overrideWith(() => _FakeLocaleNotifier()),
    if (repo != null) tasksRepositoryProvider.overrideWithValue(repo),
  ]);
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const TaskInput(
        title: 'fallback',
        visualKind: 'emoji',
        visualValue: '🏠',
        recurrenceRule: RecurrenceRule.daily(
          every: 1,
          time: '09:00',
          timezone: 'Europe/Madrid',
        ),
        assignmentMode: 'basicRotation',
        assignmentOrder: [],
      ),
    );
  });

  group('CreateEditTaskViewModel — create mode', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(overrides: [
        authProvider.overrideWith(
            () => _FakeAuth(const AuthState.unauthenticated())),
        authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
        currentHomeProvider.overrideWith(() => _FakeCurrentHome()),
        localeNotifierProvider.overrideWith(() => _FakeLocaleNotifier()),
      ]);
    });

    tearDown(() => container.dispose());

    test('savedSuccessfully starts false', () {
      final vm = container.read(createEditTaskViewModelProvider(null));
      expect(vm.savedSuccessfully, isFalse);
    });

    test('loadedTitle is null in create mode', () {
      final vm = container.read(createEditTaskViewModelProvider(null));
      expect(vm.loadedTitle, isNull);
    });

    test('setTitle propagates to TaskFormNotifier', () {
      container
          .read(createEditTaskViewModelProvider(null))
          .setTitle('Limpiar baño');
      expect(container.read(taskFormNotifierProvider).title, 'Limpiar baño');
    });
  });

  group('CreateEditTaskViewModel — save', () {
    test('save con todos los campos válidos → savedSuccessfully = true',
        () async {
      final repo = _MockTasksRepository();
      when(() => repo.createTask(any(), any(), any()))
          .thenAnswer((_) async => 'task1');

      final container = _makeContainer(repo: repo);
      addTearDown(container.dispose);

      // Warm up the home provider so valueOrNull is non-null inside save()
      await container.read(currentHomeProvider.future);

      final vm = container.read(createEditTaskViewModelProvider(null));
      // Let initCreate microtask run
      await Future<void>.delayed(Duration.zero);

      vm.setTitle('Fregar platos');
      vm.setAssignmentOrder(['uid1']);
      vm.setRecurrenceRule(const RecurrenceRule.daily(
        every: 1,
        time: '09:00',
        timezone: 'Europe/Madrid',
      ));

      await vm.save();

      verify(() => repo.createTask('h1', any(), 'uid1')).called(1);
      // Read savedSuccessfully from the same vm instance to avoid
      // re-triggering the auto-dispose proxy provider with a fresh notifier.
      expect(vm.savedSuccessfully, isTrue);
    });

    test('save sin recurrence → savedSuccessfully = false, fieldErrors[recurrence] no null',
        () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final vm = container.read(createEditTaskViewModelProvider(null));
      await Future<void>.delayed(Duration.zero);
      await container.read(currentHomeProvider.future);

      vm.setTitle('Fregar platos');
      vm.setAssignmentOrder(['uid1']);
      // No se establece recurrenceRule

      await vm.save();

      final state = container.read(taskFormNotifierProvider);
      expect(state.fieldErrors['recurrence'], isNotNull);
      expect(
        container.read(createEditTaskViewModelProvider(null)).savedSuccessfully,
        isFalse,
      );
    });

    test('save sin assignees → savedSuccessfully = false, fieldErrors[assignees] no null',
        () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final vm = container.read(createEditTaskViewModelProvider(null));
      await Future<void>.delayed(Duration.zero);
      await container.read(currentHomeProvider.future);

      vm.setTitle('Fregar platos');
      vm.setRecurrenceRule(const RecurrenceRule.daily(
        every: 1,
        time: '09:00',
        timezone: 'Europe/Madrid',
      ));
      // No se establece assignmentOrder (queda vacío)

      await vm.save();

      final state = container.read(taskFormNotifierProvider);
      expect(state.fieldErrors['assignees'], isNotNull);
      expect(
        container.read(createEditTaskViewModelProvider(null)).savedSuccessfully,
        isFalse,
      );
    });

    test('save sin title → savedSuccessfully = false, fieldErrors[title] no null',
        () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final vm = container.read(createEditTaskViewModelProvider(null));
      await Future<void>.delayed(Duration.zero);
      await container.read(currentHomeProvider.future);

      // No se establece title (queda vacío)
      vm.setAssignmentOrder(['uid1']);
      vm.setRecurrenceRule(const RecurrenceRule.daily(
        every: 1,
        time: '09:00',
        timezone: 'Europe/Madrid',
      ));

      await vm.save();

      final state = container.read(taskFormNotifierProvider);
      expect(state.fieldErrors['title'], isNotNull);
      expect(
        container.read(createEditTaskViewModelProvider(null)).savedSuccessfully,
        isFalse,
      );
    });

    test('modo edición: initEdit pre-rellena título, asignados y recurrencia', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final formNotifier = container.read(taskFormNotifierProvider.notifier);
      formNotifier.initEdit(
        Task(
          id: 'task1',
          homeId: 'h1',
          title: 'Fregar',
          description: null,
          visualKind: 'emoji',
          visualValue: '🧹',
          status: TaskStatus.active,
          recurrenceRule: const RecurrenceRule.daily(
            every: 1,
            time: '09:00',
            timezone: 'Europe/Madrid',
          ),
          assignmentMode: 'basicRotation',
          assignmentOrder: const ['uid1', 'uid2'],
          currentAssigneeUid: null,
          nextDueAt: DateTime(2026, 4, 10),
          difficultyWeight: 1.5,
          completedCount90d: 0,
          createdByUid: 'uid1',
          createdAt: DateTime(2026, 4, 1),
          updatedAt: DateTime(2026, 4, 1),
        ),
      );

      final formState = container.read(taskFormNotifierProvider);
      expect(formState.title, 'Fregar');
      expect(formState.assignmentOrder, ['uid1', 'uid2']);
      expect(formState.recurrenceRule, isNotNull);
      expect(formState.difficultyWeight, 1.5);
    });
  });

  group('CreateEditTaskViewModel — showApplyToday', () {
    test('showApplyToday false cuando no hay hora fija', () {
      expect(
        CreateEditTaskViewModel.computeShowApplyToday(
          hasFixedTime: false,
          fixedTime: null,
          now: const TimeOfDay(hour: 9, minute: 0),
        ),
        isFalse,
      );
    });

    test('showApplyToday true cuando la hora fija es posterior a ahora', () {
      expect(
        CreateEditTaskViewModel.computeShowApplyToday(
          hasFixedTime: true,
          fixedTime: const TimeOfDay(hour: 10, minute: 0),
          now: const TimeOfDay(hour: 9, minute: 0),
        ),
        isTrue,
      );
    });

    test('showApplyToday false cuando la hora fija ya pasó', () {
      expect(
        CreateEditTaskViewModel.computeShowApplyToday(
          hasFixedTime: true,
          fixedTime: const TimeOfDay(hour: 10, minute: 0),
          now: const TimeOfDay(hour: 11, minute: 0),
        ),
        isFalse,
      );
    });
  });

  group('CreateEditTaskViewModel — canSave', () {
    test('canSave false cuando el nombre está vacío', () {
      expect(
        CreateEditTaskViewModel.computeCanSave(
          name: '',
          assignedMemberCount: 2,
        ),
        isFalse,
      );
    });

    test('canSave false cuando no hay miembros asignados', () {
      expect(
        CreateEditTaskViewModel.computeCanSave(
          name: 'Barrer',
          assignedMemberCount: 0,
        ),
        isFalse,
      );
    });

    test('canSave true cuando hay nombre y al menos 1 miembro', () {
      expect(
        CreateEditTaskViewModel.computeCanSave(
          name: 'Barrer',
          assignedMemberCount: 1,
        ),
        isTrue,
      );
    });
  });
}
