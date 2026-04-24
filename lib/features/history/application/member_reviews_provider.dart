// lib/features/history/application/member_reviews_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'history_event_detail_provider.dart';

part 'member_reviews_provider.g.dart';

/// Ítem de resumen para la sección "Últimas valoraciones" del perfil de miembro.
/// Lleva el `homeId` y `eventId` para poder navegar al detalle.
class MemberReviewSummary {
  const MemberReviewSummary({
    required this.homeId,
    required this.eventId,
    required this.review,
  });

  final String homeId;
  final String eventId;
  final EventReview review;
}

/// Devuelve hasta 5 reviews visibles para `viewerUid` sobre `memberUid`.
///
/// Política de visibilidad:
/// - Si `viewerUid == memberUid`: devuelve las últimas 5 reviews recibidas por
///   él (es performer) — rules permiten leerlas todas.
/// - Si no: devuelve las últimas 5 reviews que `viewerUid` ha escrito sobre
///   `memberUid`. Si no ha escrito ninguna, lista vacía.
///
/// Devuelve lista vacía si faltan parámetros (p.ej. viewer anónimo).
@Riverpod(keepAlive: false)
Future<List<MemberReviewSummary>> memberVisibleReviews(
  MemberVisibleReviewsRef ref, {
  required String memberUid,
  required String viewerUid,
}) async {
  if (memberUid.isEmpty || viewerUid.isEmpty) return const [];

  final firestore = FirebaseFirestore.instance;
  Query<Map<String, dynamic>> query = firestore.collectionGroup('reviews')
      .where('performerUid', isEqualTo: memberUid);

  if (viewerUid != memberUid) {
    query = query.where('reviewerUid', isEqualTo: viewerUid);
  }

  final snap = await query
      .orderBy('createdAt', descending: true)
      .limit(5)
      .get();

  return snap.docs.map((doc) {
    // Ruta típica: homes/{homeId}/taskEvents/{eventId}/reviews/{reviewerUid}
    final parts = doc.reference.path.split('/');
    final homeId = parts.length > 1 ? parts[1] : '';
    final eventId = parts.length > 3 ? parts[3] : '';
    return MemberReviewSummary(
      homeId: homeId,
      eventId: eventId,
      review: EventReview.fromDoc(doc),
    );
  }).toList(growable: false);
}
