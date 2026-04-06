// lib/features/homes/application/dashboard_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../tasks/domain/home_dashboard.dart';
import 'current_home_provider.dart';

part 'dashboard_provider.g.dart';

@riverpod
Stream<HomeDashboard?> dashboard(DashboardRef ref) {
  final homeId = ref.watch(currentHomeProvider).valueOrNull?.id;
  if (homeId == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('homes')
      .doc(homeId)
      .collection('views')
      .doc('dashboard')
      .snapshots()
      .map((snap) =>
          snap.exists ? HomeDashboard.fromFirestore(snap.data()!) : null);
}
