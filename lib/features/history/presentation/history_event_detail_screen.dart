// lib/features/history/presentation/history_event_detail_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/toka_dates.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/auth_provider.dart';
import '../../members/application/members_provider.dart';
import '../../members/domain/member.dart';
import '../application/history_event_detail_provider.dart';
import '../domain/task_event.dart';

class HistoryEventDetailScreen extends ConsumerWidget {
  const HistoryEventDetailScreen({
    super.key,
    required this.homeId,
    required this.eventId,
  });

  final String homeId;
  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
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

          return ListView(
            key: const Key('history_event_detail_list'),
            padding: const EdgeInsets.all(16),
            children: [
              _EventHeader(event: detail.event, l10n: l10n),
              const SizedBox(height: 20),
              _EventSummary(event: detail.event, byUid: byUid, l10n: l10n),
              const SizedBox(height: 24),
              if (detail.reviews.isEmpty)
                Text(
                  l10n.noReviewsOnEvent,
                  key: const Key('no_reviews_message'),
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                ...detail.reviews.map((r) => _ReviewBlock(
                      review: r,
                      event: detail.event,
                      currentUid: currentUid,
                      byUid: byUid,
                      l10n: l10n,
                    )),
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

class _EventHeader extends StatelessWidget {
  const _EventHeader({required this.event, required this.l10n});
  final TaskEvent event;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final (title, visual, createdAt) = switch (event) {
      CompletedEvent e => (e.taskTitleSnapshot, e.taskVisualSnapshot, e.createdAt),
      PassedEvent e    => (e.taskTitleSnapshot, e.taskVisualSnapshot, e.createdAt),
      MissedEvent e    => (e.taskTitleSnapshot, e.taskVisualSnapshot, e.createdAt),
    };
    final label = visual.kind == 'emoji' ? '${visual.value} $title' : title;
    return Column(
      key: const Key('event_header'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                )),
        const SizedBox(height: 4),
        Text(_eventDate(context, createdAt),
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _EventSummary extends StatelessWidget {
  const _EventSummary({
    required this.event,
    required this.byUid,
    required this.l10n,
  });
  final TaskEvent event;
  final Map<String, Member> byUid;
  final AppLocalizations l10n;

  String _name(String uid) => byUid[uid]?.nickname.isNotEmpty == true
      ? byUid[uid]!.nickname
      : l10n.historyEventUnknownMember;

  @override
  Widget build(BuildContext context) {
    final text = switch (event) {
      CompletedEvent e => l10n.history_event_completed(_name(e.actorUid)),
      PassedEvent e =>
        '${_name(e.fromUid)} → ${_name(e.toUid)} · ${l10n.history_event_pass_turn}',
      MissedEvent e => l10n.history_event_missed(_name(e.actorUid)),
    };
    return Text(text,
        key: const Key('event_summary'),
        style: Theme.of(context).textTheme.bodyLarge);
  }
}

class _ReviewBlock extends StatelessWidget {
  const _ReviewBlock({
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
    final reviewer = byUid[review.reviewerUid];
    final performerName = _performerUid == null
        ? l10n.historyEventUnknownMember
        : _name(_performerUid!);

    return Container(
      key: Key('review_block_${review.reviewerUid}'),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
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
              child: Text(
                l10n.reviewByLabel(_name(review.reviewerUid)),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          _ScoreStars(score: review.score),
          if (_canSeeNote && (review.note?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 12),
            Container(
              key: const Key('private_note_container'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.reviewPrivateNoteLabel,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(review.note!,
                      key: const Key('private_note_text')),
                  const SizedBox(height: 6),
                  Text(
                    l10n.reviewPrivateNoteHint(performerName),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Estrellas sobre escala 1–10. Se muestran 5 estrellas (score/2) junto al
/// número exacto para no perder precisión.
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
        Text(score.toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
