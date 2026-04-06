// test/unit/features/tasks/home_dashboard_test.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';

void main() {
  group('TaskPreview.fromMap', () {
    test('happy path: parsea todos los campos', () {
      final now = DateTime(2026, 4, 6, 20, 0);
      final map = {
        'taskId': 't1',
        'title': 'Barrer',
        'visualKind': 'emoji',
        'visualValue': '🧹',
        'recurrenceType': 'daily',
        'currentAssigneeUid': 'uid1',
        'currentAssigneeName': 'Ana',
        'currentAssigneePhoto': null,
        'nextDueAt': Timestamp.fromDate(now),
        'isOverdue': false,
        'status': 'active',
      };
      final task = TaskPreview.fromMap(map);
      expect(task.taskId, 't1');
      expect(task.title, 'Barrer');
      expect(task.recurrenceType, 'daily');
      expect(task.nextDueAt, now);
      expect(task.isOverdue, isFalse);
    });

    test('usa defaults cuando faltan campos opcionales', () {
      final map = {
        'taskId': 't2',
        'title': 'Fregar',
        'recurrenceType': 'weekly',
        'nextDueAt': Timestamp.fromDate(DateTime(2026, 4, 6)),
      };
      final task = TaskPreview.fromMap(map);
      expect(task.visualKind, 'emoji');
      expect(task.visualValue, '');
      expect(task.currentAssigneeUid, isNull);
      expect(task.isOverdue, isFalse);
      expect(task.status, 'active');
    });

    test('usa DateTime.now() como fallback cuando nextDueAt es null', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final map = {
        'taskId': 't3',
        'title': 'Test',
        'recurrenceType': 'daily',
        'nextDueAt': null,
      };
      final task = TaskPreview.fromMap(map);
      expect(task.nextDueAt.isAfter(before), isTrue);
    });
  });

  group('DoneTaskPreview.fromMap', () {
    test('happy path: parsea todos los campos', () {
      final completedAt = DateTime(2026, 4, 6, 9, 30);
      final map = {
        'taskId': 'd1',
        'title': 'Fregar',
        'visualKind': 'emoji',
        'visualValue': '🍽️',
        'recurrenceType': 'daily',
        'completedByUid': 'uid1',
        'completedByName': 'Ana',
        'completedByPhoto': null,
        'completedAt': Timestamp.fromDate(completedAt),
      };
      final done = DoneTaskPreview.fromMap(map);
      expect(done.taskId, 'd1');
      expect(done.completedByName, 'Ana');
      expect(done.completedAt, completedAt);
    });

    test('usa DateTime.now() como fallback cuando completedAt es null', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final map = {
        'taskId': 'd2',
        'title': 'Test',
        'recurrenceType': 'weekly',
        'completedByUid': 'uid2',
        'completedByName': 'Carlos',
        'completedAt': null,
      };
      final done = DoneTaskPreview.fromMap(map);
      expect(done.completedAt.isAfter(before), isTrue);
    });
  });

  group('DashboardCounters', () {
    test('fromMap con mapa vacío usa valores por defecto 0', () {
      final counters = DashboardCounters.fromMap({});
      expect(counters.totalActiveTasks, 0);
      expect(counters.totalMembers, 0);
      expect(counters.tasksDueToday, 0);
      expect(counters.tasksDoneToday, 0);
    });

    test('empty() constructor retorna todos ceros', () {
      expect(DashboardCounters.empty(), DashboardCounters.fromMap({}));
    });
  });

  group('PremiumFlags', () {
    test('free() tiene showAds true e isPremium false', () {
      final flags = PremiumFlags.free();
      expect(flags.isPremium, isFalse);
      expect(flags.showAds, isTrue);
      expect(flags.canUseSmartDistribution, isFalse);
    });
  });

  group('HomeDashboard.fromFirestore', () {
    test('parsea listas vacías sin error', () {
      final data = {
        'activeTasksPreview': [],
        'doneTasksPreview': [],
        'counters': {},
        'memberPreview': [],
        'premiumFlags': {},
        'adFlags': {},
        'rescueFlags': {},
        'updatedAt': Timestamp.fromDate(DateTime(2026, 4, 6)),
      };
      final dashboard = HomeDashboard.fromFirestore(data);
      expect(dashboard.activeTasksPreview, isEmpty);
      expect(dashboard.doneTasksPreview, isEmpty);
      expect(dashboard.counters.totalActiveTasks, 0);
    });

    test('parsea activeTasksPreview correctamente', () {
      final data = {
        'activeTasksPreview': [
          {
            'taskId': 't1',
            'title': 'Barrer',
            'recurrenceType': 'daily',
            'nextDueAt': Timestamp.fromDate(DateTime(2026, 4, 6, 20)),
          }
        ],
        'doneTasksPreview': [],
        'counters': {},
        'memberPreview': [],
        'premiumFlags': {},
        'adFlags': {},
        'rescueFlags': {},
      };
      final dashboard = HomeDashboard.fromFirestore(data);
      expect(dashboard.activeTasksPreview.length, 1);
      expect(dashboard.activeTasksPreview.first.taskId, 't1');
    });

    test('usa updatedAt fallback cuando falta el campo', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final data = {
        'activeTasksPreview': [],
        'doneTasksPreview': [],
        'counters': {},
        'memberPreview': [],
        'premiumFlags': {},
        'adFlags': {},
        'rescueFlags': {},
        // no updatedAt
      };
      final dashboard = HomeDashboard.fromFirestore(data);
      expect(dashboard.updatedAt.isAfter(before), isTrue);
    });
  });
}
