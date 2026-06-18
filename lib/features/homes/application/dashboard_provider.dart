// lib/features/homes/application/dashboard_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../tasks/domain/home_dashboard.dart';
import 'current_home_provider.dart';

part 'dashboard_provider.g.dart';

@riverpod
Stream<HomeDashboard?> dashboard(DashboardRef ref) {
  // Observar SOLO el id: ahora `currentHomeProvider` re-emite ante cualquier
  // cambio del documento del hogar (foto, premium, nombre…). Sin el `.select`,
  // este provider se reconstruiría en cada uno de esos cambios, re-suscribiendo
  // el snapshot del dashboard y re-invocando la Cloud Function `refreshDashboard`
  // innecesariamente. Solo nos interesa reaccionar al cambio de hogar.
  final homeId =
      ref.watch(currentHomeProvider.select((h) => h.valueOrNull?.id));
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
