// lib/features/homes/application/dashboard_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../tasks/domain/home_dashboard.dart';
import 'current_home_provider.dart';

part 'dashboard_provider.g.dart';

@riverpod
Stream<HomeDashboard?> dashboard(DashboardRef ref) {
  final homeId = ref.watch(currentHomeProvider).valueOrNull?.id;
  if (homeId == null) return Stream.value(null);

  final docRef = FirebaseFirestore.instance
      .collection('homes')
      .doc(homeId)
      .collection('views')
      .doc('dashboard');

  // Bootstrap: reconstruir dashboard al inicializar el provider.
  // Se ejecuta una vez por sesión por hogar. Garantiza datos frescos aunque
  // el documento exista con contadores obsoletos (p.ej. antes del fix del índice).
  Future(() async {
    try {
      await FirebaseFunctions.instance
          .httpsCallable('refreshDashboard')
          .call({'homeId': homeId});
    } catch (_) {}
  });

  return docRef
      .snapshots()
      .map((snap) =>
          snap.exists ? HomeDashboard.fromFirestore(snap.data()!) : null);
}
