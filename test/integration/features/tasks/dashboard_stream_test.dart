// test/integration/features/tasks/dashboard_stream_test.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';

Future<void> _writeDashboard(
  FakeFirebaseFirestore firestore,
  String homeId, {
  List<Map<String, dynamic>> activeTasks = const [],
  List<Map<String, dynamic>> doneTasks = const [],
}) {
  return firestore
      .collection('homes')
      .doc(homeId)
      .collection('views')
      .doc('dashboard')
      .set({
    'activeTasksPreview': activeTasks,
    'doneTasksPreview': doneTasks,
    'counters': {
      'totalActiveTasks': activeTasks.length,
      'totalMembers': 2,
      'tasksDueToday': activeTasks.length,
      'tasksDoneToday': doneTasks.length,
    },
    'memberPreview': [],
    'premiumFlags': {
      'isPremium': false,
      'showAds': true,
      'canUseSmartDistribution': false,
      'canUseVacations': false,
      'canUseReviews': false,
    },
    'adFlags': {'showBanner': true, 'bannerUnit': 'test-unit'},
    'rescueFlags': {'isInRescue': false, 'daysLeft': null},
    'updatedAt': Timestamp.fromDate(DateTime(2026, 4, 6)),
  });
}

Stream<HomeDashboard?> _watchDashboard(
    FakeFirebaseFirestore firestore, String homeId) {
  return firestore
      .collection('homes')
      .doc(homeId)
      .collection('views')
      .doc('dashboard')
      .snapshots()
      .map((snap) =>
          snap.exists ? HomeDashboard.fromFirestore(snap.data()!) : null);
}

void main() {
  group('dashboard stream', () {
    late FakeFirebaseFirestore firestore;

    setUp(() {
      firestore = FakeFirebaseFirestore();
    });

    test('emite HomeDashboard cuando existe el documento', () async {
      await _writeDashboard(firestore, 'home1');

      final dashboard = await _watchDashboard(firestore, 'home1').first;

      expect(dashboard, isNotNull);
      expect(dashboard!.counters.totalMembers, 2);
    });

    test('emite null cuando el documento no existe', () async {
      final dashboard = await _watchDashboard(firestore, 'home-noexiste').first;
      expect(dashboard, isNull);
    });

    test('emite nuevo valor al actualizar el documento', () async {
      await _writeDashboard(firestore, 'home2',
          activeTasks: [
            {
              'taskId': 't1',
              'title': 'Barrer',
              'visualKind': 'emoji',
              'visualValue': '🧹',
              'recurrenceType': 'daily',
              'currentAssigneeUid': null,
              'currentAssigneeName': null,
              'currentAssigneePhoto': null,
              'nextDueAt': Timestamp.fromDate(DateTime(2026, 4, 6, 10)),
              'isOverdue': false,
              'status': 'active',
            }
          ]);

      // Collect the first two emissions: initial state then updated state.
      final collected = <HomeDashboard?>[];
      final completer = Completer<void>();

      final subscription =
          _watchDashboard(firestore, 'home2').listen((value) {
        collected.add(value);
        if (collected.length == 2) completer.complete();
      });

      // Verify initial emission has 1 task.
      await Future<void>.delayed(Duration.zero);
      expect(collected.first!.activeTasksPreview.length, 1);

      // Trigger update and wait for second emission.
      await _writeDashboard(firestore, 'home2', activeTasks: []);
      await completer.future;

      await subscription.cancel();
      expect(collected.last!.activeTasksPreview, isEmpty);
    });

    test('HomeDashboard.fromFirestore parsea activeTasksPreview correctamente',
        () async {
      final taskTime = DateTime(2026, 4, 6, 20, 0);
      await _writeDashboard(firestore, 'home3', activeTasks: [
        {
          'taskId': 'task-abc',
          'title': 'Fregar',
          'visualKind': 'emoji',
          'visualValue': '🍽️',
          'recurrenceType': 'weekly',
          'currentAssigneeUid': 'uid-x',
          'currentAssigneeName': 'Carlos',
          'currentAssigneePhoto': null,
          'nextDueAt': Timestamp.fromDate(taskTime),
          'isOverdue': false,
          'status': 'active',
        }
      ]);

      final dashboard = await _watchDashboard(firestore, 'home3').first;

      expect(dashboard!.activeTasksPreview.length, 1);
      final task = dashboard.activeTasksPreview.first;
      expect(task.taskId, 'task-abc');
      expect(task.title, 'Fregar');
      expect(task.recurrenceType, 'weekly');
      expect(task.currentAssigneeUid, 'uid-x');
      expect(task.nextDueAt, taskTime);
    });

    test('adFlags.showBanner es false cuando isPremium', () async {
      await firestore
          .collection('homes')
          .doc('home-premium')
          .collection('views')
          .doc('dashboard')
          .set({
        'activeTasksPreview': [],
        'doneTasksPreview': [],
        'counters': {
          'totalActiveTasks': 0,
          'totalMembers': 1,
          'tasksDueToday': 0,
          'tasksDoneToday': 0,
        },
        'memberPreview': [],
        'premiumFlags': {
          'isPremium': true,
          'showAds': false,
          'canUseSmartDistribution': true,
          'canUseVacations': true,
          'canUseReviews': true,
        },
        'adFlags': {'showBanner': false, 'bannerUnit': ''},
        'rescueFlags': {'isInRescue': false, 'daysLeft': null},
        'updatedAt': Timestamp.fromDate(DateTime(2026, 4, 6)),
      });

      final dashboard =
          await _watchDashboard(firestore, 'home-premium').first;

      expect(dashboard!.adFlags.showBanner, isFalse);
      expect(dashboard.premiumFlags.isPremium, isTrue);
    });
  });
}
