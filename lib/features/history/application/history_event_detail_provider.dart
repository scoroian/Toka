// lib/features/history/application/history_event_detail_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/task_event.dart';

part 'history_event_detail_provider.g.dart';

/// Una valoración emitida por un miembro sobre un evento.
///
/// Refleja el documento `homes/{homeId}/taskEvents/{eventId}/reviews/{reviewerUid}`
/// escrito por la Cloud Function `submitReview`.
class EventReview {
  const EventReview({
    required this.reviewerUid,
    required this.performerUid,
    required this.score,
    required this.note,
    required this.createdAt,
  });

  final String reviewerUid;
  final String performerUid;
  final double score;
  final String? note;
  final DateTime? createdAt;

  factory EventReview.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return EventReview(
      reviewerUid: data['reviewerUid'] as String? ?? doc.id,
      performerUid: data['performerUid'] as String? ?? '',
      score: (data['score'] as num?)?.toDouble() ?? 0.0,
      note: data['note'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// Payload combinado del evento + sus reviews.
class HistoryEventDetail {
  const HistoryEventDetail({
    required this.event,
    required this.reviews,
  });

  final TaskEvent event;
  final List<EventReview> reviews;
}

/// Stream del evento con sus reviews asociadas.
///
/// Implementación: escuchamos el evento y refetcheamos reviews en cada cambio.
/// El volumen típico (≤ n_miembros del hogar) mantiene el coste bajo. Si subiera,
/// se puede introducir un snapshot concurrente de la subcolección.
@Riverpod(keepAlive: false)
Stream<HistoryEventDetail> historyEventDetail(
  HistoryEventDetailRef ref, {
  required String homeId,
  required String eventId,
}) async* {
  final eventRef =
      FirebaseFirestore.instance.doc('homes/$homeId/taskEvents/$eventId');
  final reviewsCol = eventRef.collection('reviews');

  await for (final eventSnap in eventRef.snapshots()) {
    if (!eventSnap.exists) continue;
    final event = TaskEvent.fromFirestore(eventSnap);
    final reviewsSnap = await reviewsCol.get();
    final reviews = reviewsSnap.docs
        .map((d) => EventReview.fromDoc(d))
        .toList(growable: false)
      ..sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    yield HistoryEventDetail(event: event, reviews: reviews);
  }
}
