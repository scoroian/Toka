// lib/features/profile/application/member_radar_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../presentation/widgets/radar_chart_widget.dart';

part 'member_radar_provider.g.dart';

@riverpod
Future<List<RadarEntry>> memberRadar(
  MemberRadarRef ref, {
  required String homeId,
  required String uid,
}) async {
  final firestore = FirebaseFirestore.instance;

  // Read stats for this member
  final statsSnap = await firestore
      .collection('homes')
      .doc(homeId)
      .collection('memberTaskStats')
      .where('uid', isEqualTo: uid)
      .orderBy('avgScore', descending: true)
      .limit(20)
      .get();

  if (statsSnap.docs.isEmpty) return [];

  // Fetch task names in parallel
  final taskFutures = statsSnap.docs.map((stat) {
    final taskId = stat.data()['taskId'] as String;
    return firestore
        .collection('homes')
        .doc(homeId)
        .collection('tasks')
        .doc(taskId)
        .get();
  });
  final taskSnaps = await Future.wait(taskFutures);

  // Combine
  final entries = <RadarEntry>[];
  for (var i = 0; i < statsSnap.docs.length; i++) {
    final stat = statsSnap.docs[i].data();
    final taskData = taskSnaps[i].data();
    final taskName = taskData?['title'] as String? ?? '?';
    final avgScore = (stat['avgScore'] as num?)?.toDouble() ?? 0.0;
    if (avgScore > 0) {
      entries.add(RadarEntry(taskName: taskName, avgScore: avgScore));
    }
  }
  return entries;
}
