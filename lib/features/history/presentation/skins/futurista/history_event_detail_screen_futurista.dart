import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/utils/toka_dates.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../auth/application/auth_provider.dart';
import '../../../../members/application/members_provider.dart';
import '../../../../members/domain/member.dart';
import '../../../application/history_event_detail_provider.dart';
import '../../../domain/task_event.dart';

/// Variante futurista de la pantalla de detalle de evento de historial.
///
/// Consume los mismos providers que `HistoryEventDetailScreenV2` y mantiene la
/// misma lógica de visibilidad de la nota privada (BUG-20/BUG-21). El layout
/// presenta una hero card con gradiente, secciones tipográficas mono y cards
/// de valoración con fondo `surfaceContainerHighest`.
class HistoryEventDetailScreenFuturista extends ConsumerWidget {
  const HistoryEventDetailScreenFuturista({
    super.key,
    required this.homeId,
    required this.eventId,
  });

  final String homeId;
  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final muted = theme.colorScheme.onSurfaceVariant;

    final detailAsync = ref.watch(
      historyEventDetailProvider(homeId: homeId, eventId: eventId),
    );
    final membersAsync = ref.watch(homeMembersProvider(homeId));
    final currentUid =
        ref.watch(authProvider).whenOrNull(authenticated: (u) => u.uid) ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyEventDetailTitle)),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l10n.error_generic)),
        data: (detail) {
          final members = membersAsync.valueOrNull ?? const <Member>[];
          final byUid = {for (final m in members) m.uid: m};

          String name(String uid) => byUid[uid]?.nickname.isNotEmpty == true
              ? byUid[uid]!.nickname
              : l10n.historyEventUnknownMember;

          final event = detail.event;
          final (title, visual, createdAt) = switch (event) {
            CompletedEvent e => (
                e.taskTitleSnapshot,
                e.taskVisualSnapshot,
                e.createdAt,
              ),
            PassedEvent e => (
                e.taskTitleSnapshot,
                e.taskVisualSnapshot,
                e.createdAt,
              ),
            MissedEvent e => (
                e.taskTitleSnapshot,
                e.taskVisualSnapshot,
                e.createdAt,
              ),
          };

          final summary = switch (event) {
            CompletedEvent e => l10n.history_event_completed(name(e.actorUid)),
            PassedEvent e =>
              '${name(e.fromUid)} → ${name(e.toUid)} · ${l10n.history_event_pass_turn}',
            MissedEvent e => l10n.history_event_missed(name(e.actorUid)),
          };

          final summaryNameInitial = switch (event) {
            CompletedEvent e => name(e.actorUid),
            PassedEvent e => name(e.fromUid),
            MissedEvent e => name(e.actorUid),
          };

          return ListView(
            key: const Key('history_event_detail_list'),
            padding: const EdgeInsets.all(16),
            children: [
              // Hero card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primary.withValues(alpha: 0.14),
                      theme.colorScheme.surface.withValues(alpha: 0.7),
                    ],
                  ),
                  border: Border.all(
                    color: primary.withValues(alpha: 0.25),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border.all(
                          color: primary.withValues(alpha: 0.25),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: visual.kind == 'emoji'
                            ? Text(
                                visual.value,
                                style: const TextStyle(fontSize: 40),
                              )
                            : Icon(
                                Icons.task_outlined,
                                size: 40,
                                color: primary,
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _eventDate(context, createdAt),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.4,
                        color: muted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _EventTypePill(event: event),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Sección QUIÉN
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QUIÉN',
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                      color: muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      key: const Key('event_summary'),
                      children: [
                        CircleAvatar(
                          radius: 18,
                          child: Text(
                            summaryNameInitial.isNotEmpty
                                ? summaryNameInitial[0].toUpperCase()
                                : '?',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            summary,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Sección VALORACIONES
              if (detail.reviews.isNotEmpty) ...[
                Text(
                  'VALORACIONES',
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < detail.reviews.length; i++) ...[
                  _ReviewCardFuturista(
                    review: detail.reviews[i],
                    event: event,
                    currentUid: currentUid,
                    byUid: byUid,
                    l10n: l10n,
                  ),
                  if (i != detail.reviews.length - 1)
                    const SizedBox(height: 8),
                ],
              ] else
                Text(
                  l10n.noReviewsOnEvent,
                  key: const Key('no_reviews_message'),
                  style: TextStyle(fontSize: 13, color: muted),
                ),
            ],
          );
        },
      ),
    );
  }
}

String _eventDate(BuildContext context, DateTime dt) {
  final locale = Localizations.localeOf(context);
  return '${TokaDates.dateLongFull(dt, locale)} · '
      '${TokaDates.timeShort(dt, locale)}';
}

class _EventTypePill extends StatelessWidget {
  const _EventTypePill({required this.event});
  final TaskEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    late final Color bg;
    late final Color border;
    late final Color textColor;
    late final String label;
    switch (event) {
      case CompletedEvent _:
        bg = Colors.green.withValues(alpha: 0.14);
        border = Colors.green.withValues(alpha: 0.4);
        textColor = Colors.green.shade700;
        label = 'Completado';
      case PassedEvent _:
        const amber = Color(0xFFF5B544);
        bg = amber.withValues(alpha: 0.14);
        border = amber.withValues(alpha: 0.4);
        textColor = amber;
        label = 'Pase de turno';
      case MissedEvent _:
        bg = theme.colorScheme.errorContainer.withValues(alpha: 0.5);
        border = theme.colorScheme.error.withValues(alpha: 0.4);
        textColor = theme.colorScheme.error;
        label = 'Perdido';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: 1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ReviewCardFuturista extends StatelessWidget {
  const _ReviewCardFuturista({
    required this.review,
    required this.event,
    required this.currentUid,
    required this.byUid,
    required this.l10n,
  });

  final EventReview review;
  final TaskEvent event;
  final String currentUid;
  final Map<String, Member> byUid;
  final AppLocalizations l10n;

  String? get _performerUid => switch (event) {
        CompletedEvent e => e.performerUid,
        PassedEvent _ => null,
        MissedEvent _ => null,
      };

  bool get _canSeeNote =>
      currentUid.isNotEmpty &&
      (currentUid == review.reviewerUid || currentUid == _performerUid);

  String _name(String uid) => byUid[uid]?.nickname.isNotEmpty == true
      ? byUid[uid]!.nickname
      : l10n.historyEventUnknownMember;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final reviewer = byUid[review.reviewerUid];
    final performerName = _performerUid == null
        ? l10n.historyEventUnknownMember
        : _name(_performerUid!);

    return Container(
      key: Key('review_block_${review.reviewerUid}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: reviewer?.photoUrl != null
                    ? CachedNetworkImageProvider(reviewer!.photoUrl!)
                    : null,
                child: reviewer?.photoUrl == null
                    ? Text(_name(review.reviewerUid).isNotEmpty
                        ? _name(review.reviewerUid)[0].toUpperCase()
                        : '?')
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.reviewByLabel(_name(review.reviewerUid)),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _ScoreStars(score: review.score),
                    if (_canSeeNote &&
                        (review.note?.isNotEmpty ?? false)) ...[
                      const SizedBox(height: 12),
                      Container(
                        key: const Key('private_note_container'),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.reviewPrivateNoteLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'JetBrainsMono',
                                letterSpacing: 1.4,
                                color: muted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              review.note!,
                              key: const Key('private_note_text'),
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.reviewPrivateNoteHint(performerName),
                              style: TextStyle(fontSize: 11, color: muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Estrellas sobre escala 1-10. Réplica del helper de v2 (5 estrellas con
/// `score/2` + número exacto al lado para no perder precisión).
class _ScoreStars extends StatelessWidget {
  const _ScoreStars({required this.score});
  final double score;

  @override
  Widget build(BuildContext context) {
    final normalized = (score / 2).clamp(0.0, 5.0);
    final full = normalized.floor();
    final hasHalf = (normalized - full) >= 0.5;
    final empty = 5 - full - (hasHalf ? 1 : 0);

    return Row(
      key: const Key('review_stars'),
      children: [
        for (var i = 0; i < full; i++)
          const Icon(Icons.star, color: Colors.amber, size: 20),
        if (hasHalf)
          const Icon(Icons.star_half, color: Colors.amber, size: 20),
        for (var i = 0; i < empty; i++)
          const Icon(Icons.star_border, color: Colors.amber, size: 20),
        const SizedBox(width: 6),
        Text(
          score.toStringAsFixed(1),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
