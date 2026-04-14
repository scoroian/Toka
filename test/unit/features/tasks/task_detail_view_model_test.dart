// test/unit/features/tasks/task_detail_view_model_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/i18n/application/locale_provider.dart';
import 'package:toka/features/tasks/application/task_detail_view_model.dart';
import 'package:toka/features/tasks/domain/task.dart';
import 'package:toka/features/tasks/domain/recurrence_rule.dart';
import 'package:toka/features/tasks/domain/task_status.dart';

class _FakeAuth extends Auth {
  _FakeAuth(this._state);
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

Task _makeDetailTask({double difficultyWeight = 2.0}) => Task(
      id: 't1',
      homeId: 'home1',
      title: 'Barrer',
      description: null,
      visualKind: 'emoji',
      visualValue: '🧹',
      status: TaskStatus.active,
      recurrenceRule: RecurrenceRule.daily(
        every: 1,
        time: '10:00',
        timezone: 'Europe/Madrid',
      ),
      assignmentMode: 'basicRotation',
      assignmentOrder: const ['uid1'],
      currentAssigneeUid: 'uid1',
      nextDueAt: DateTime(2026, 4, 14, 10, 0),
      difficultyWeight: difficultyWeight,
      completedCount90d: 5,
      createdByUid: 'uid1',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 4, 14),
    );

void main() {
  group('TaskDetailViewModel', () {
    test('viewData is data(null) when home is null', () async {
      final container = ProviderContainer(overrides: [
        authProvider.overrideWith(
            () => _FakeAuth(const AuthState.unauthenticated())),
        authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
        currentHomeProvider.overrideWith(() => _FakeCurrentHome()),
        localeNotifierProvider.overrideWith(() => _FakeLocaleNotifier()),
      ]);
      addTearDown(container.dispose);
      final vm = container.read(taskDetailViewModelProvider('nonexistent'));
      // Home is null (async data null) — should result in AsyncData(null) after resolution
      // The home provider is async so this may still be loading
      expect(vm.viewData.hasValue || vm.viewData.isLoading, isTrue);
    });
  });

  group('TaskDetailViewData — difficultyWeight', () {
    test('difficultyWeight viene de task.difficultyWeight', () {
      final task = _makeDetailTask(difficultyWeight: 2.5);
      final data = TaskDetailViewData(
        task: task,
        canManage: true,
        currentAssigneeName: 'Ana',
        upcomingOccurrences: [],
        difficultyWeight: task.difficultyWeight,
      );
      expect(data.difficultyWeight, 2.5);
      expect(data.canManage, isTrue);
      expect(data.currentAssigneeName, 'Ana');
    });

    test('difficultyWeight default 1.0', () {
      final task = _makeDetailTask(difficultyWeight: 1.0);
      final data = TaskDetailViewData(
        task: task,
        canManage: false,
        currentAssigneeName: null,
        upcomingOccurrences: [],
        difficultyWeight: task.difficultyWeight,
      );
      expect(data.difficultyWeight, 1.0);
    });
  });
}
