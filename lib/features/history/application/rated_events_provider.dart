// lib/features/history/application/rated_events_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rated_events_provider.g.dart';

/// IDs de eventos que el usuario actual YA ha valorado, leídos en vivo desde
/// `homes/{homeId}/memberReviews/{currentUid}.ratedEventIds` (lo escribe la
/// Cloud Function `submitReview`).
@riverpod
Stream<Set<String>> ratedEventIds(
  RatedEventIdsRef ref, {
  required String homeId,
  required String currentUid,
}) {
  if (homeId.isEmpty || currentUid.isEmpty) {
    return Stream.value(<String>{});
  }
  return FirebaseFirestore.instance
      .collection('homes')
      .doc(homeId)
      .collection('memberReviews')
      .doc(currentUid)
      .snapshots()
      .map((snap) {
    if (!snap.exists) return <String>{};
    final ids = (snap.data()?['ratedEventIds'] as List?)?.cast<String>() ?? [];
    return ids.toSet();
  });
}

/// Conjunto optimista de eventos valorados durante esta sesión de Historial.
///
/// `submitReview` escribe `ratedEventIds` en Firestore, pero el `snapshots()`
/// de [ratedEventIds] puede tardar uno o varios segundos en propagar el cambio
/// al cliente (round-trip callable → commit de la transacción → listener). Para
/// que el botón "Valorar" pase a "valorado" en el acto, tras un envío exitoso
/// registramos aquí el `eventId` y lo fusionamos con el stream en
/// `historyViewModel`. Siempre es un subconjunto de lo que acabará llegando por
/// Firestore, así que no introduce incoherencias entre dispositivos.
@riverpod
class OptimisticRatedEventIds extends _$OptimisticRatedEventIds {
  @override
  Set<String> build(String homeId) => const <String>{};

  void markRated(String eventId) {
    if (state.contains(eventId)) return;
    state = {...state, eventId};
  }
}
