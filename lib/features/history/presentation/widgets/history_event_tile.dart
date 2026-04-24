// lib/features/history/presentation/widgets/history_event_tile.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/toka_dates.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/task_event.dart';
import '../../../profile/presentation/widgets/review_dialog.dart';

/// Envuelve el trailing en una caja fija para que los iconos (estrella, check,
/// flechas de pasar turno, reloj de vencida) queden a la misma altura visual
/// independientemente de si el hijo es un `Icon` plano o un `IconButton`.
Widget _wrapTrailing(Widget child) => SizedBox(
      width: 48,
      height: 48,
      child: Center(child: child),
    );

String _formatRelativeTime(AppLocalizations l10n, DateTime dt, Locale locale) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return l10n.history_time_now;
  if (diff.inHours < 1) return l10n.history_time_minutes_ago(diff.inMinutes);
  if (diff.inHours < 24) return l10n.history_time_hours_ago(diff.inHours);
  if (diff.inDays < 7) return l10n.history_time_days_ago(diff.inDays);
  return '${TokaDates.dateMediumWithWeekday(dt, locale)}, '
      '${TokaDates.timeShort(dt, locale)}';
}

class HistoryEventTile extends StatelessWidget {
  const HistoryEventTile({
    super.key,
    required this.event,
    required this.actorName,
    required this.actorPhotoUrl,
    this.toName,
    this.homeId,
    this.currentUid,
    this.isPremium = false,
    this.trailing,
  });

  final TaskEvent event;
  final String actorName;
  final String? actorPhotoUrl;
  final String? toName;
  final String? homeId;
  final String? currentUid;
  final bool isPremium;
  /// Widget opcional para el trailing del tile. Cuando se proporciona,
  /// sobreescribe el trailing interno de cada sub-tile.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    return event.map(
      completed: (e) => _CompletedTile(
        event: e,
        actorName: actorName,
        actorPhotoUrl: actorPhotoUrl,
        timestamp: _formatRelativeTime(l10n, e.createdAt, locale),
        l10n: l10n,
        homeId: homeId,
        currentUid: currentUid,
        isPremium: isPremium,
        trailingOverride: trailing,
      ),
      passed: (e) => _PassedTile(
        event: e,
        actorName: actorName,
        actorPhotoUrl: actorPhotoUrl,
        toName: toName ?? '?',
        timestamp: _formatRelativeTime(l10n, e.createdAt, locale),
        l10n: l10n,
        trailingOverride: trailing,
      ),
      missed: (e) => _MissedTile(
        event: e,
        actorName: actorName,
        actorPhotoUrl: actorPhotoUrl,
        timestamp: _formatRelativeTime(l10n, e.missedAt, locale),
        l10n: l10n,
        trailingOverride: trailing,
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl, required this.name});
  final String? photoUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: CachedNetworkImageProvider(photoUrl!),
      );
    }
    return CircleAvatar(
      radius: 20,
      child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
    );
  }
}

class _CompletedTile extends StatelessWidget {
  const _CompletedTile({
    required this.event,
    required this.actorName,
    required this.actorPhotoUrl,
    required this.timestamp,
    required this.l10n,
    this.homeId,
    this.currentUid,
    this.isPremium = false,
    this.trailingOverride,
  });
  final CompletedEvent event;
  final String actorName;
  final String? actorPhotoUrl;
  final String timestamp;
  final AppLocalizations l10n;
  final String? homeId;
  final String? currentUid;
  final bool isPremium;
  final Widget? trailingOverride;

  bool get _canReview =>
      isPremium &&
      homeId != null &&
      currentUid != null &&
      currentUid != event.performerUid;

  @override
  Widget build(BuildContext context) {
    final visual = event.taskVisualSnapshot;
    final taskLabel = visual.kind == 'emoji'
        ? '${visual.value} ${event.taskTitleSnapshot}'
        : event.taskTitleSnapshot;

    Widget? effectiveTrailing = trailingOverride;
    if (effectiveTrailing == null) {
      effectiveTrailing = _canReview
          ? TextButton(
              key: const Key('btn_review'),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => ReviewDialog(
                  homeId: homeId!,
                  taskEventId: event.id,
                  taskTitle: event.taskTitleSnapshot,
                  performerName: actorName,
                  isPremium: isPremium,
                  currentUid: currentUid!,
                  performerUid: event.performerUid,
                  onSubmitted: () {},
                ),
              ),
              child: Text(l10n.review_dialog_title),
            )
          : const Icon(Icons.check_circle_outline, color: Colors.green);
    }
    return ListTile(
      key: Key('history_tile_${event.id}'),
      leading: _Avatar(photoUrl: actorPhotoUrl, name: actorName),
      title: Text(l10n.history_event_completed(actorName)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(taskLabel, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(timestamp,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
      trailing: _wrapTrailing(effectiveTrailing),
      isThreeLine: true,
    );
  }
}

class _PassedTile extends StatelessWidget {
  const _PassedTile({
    required this.event,
    required this.actorName,
    required this.actorPhotoUrl,
    required this.toName,
    required this.timestamp,
    required this.l10n,
    this.trailingOverride,
  });
  final PassedEvent event;
  final String actorName;
  final String? actorPhotoUrl;
  final String toName;
  final String timestamp;
  final AppLocalizations l10n;
  final Widget? trailingOverride;

  @override
  Widget build(BuildContext context) {
    final visual = event.taskVisualSnapshot;
    final taskLabel = visual.kind == 'emoji'
        ? '${visual.value} ${event.taskTitleSnapshot}'
        : event.taskTitleSnapshot;

    return ListTile(
      key: Key('history_tile_${event.id}'),
      leading: _Avatar(photoUrl: actorPhotoUrl, name: actorName),
      title: Row(
        children: [
          Flexible(child: Text(actorName, overflow: TextOverflow.ellipsis)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.arrow_forward, size: 14),
          ),
          Flexible(child: Text(toName, overflow: TextOverflow.ellipsis)),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$taskLabel — ${l10n.history_event_pass_turn}',
              style: const TextStyle(fontWeight: FontWeight.w500)),
          if (event.reason != null && event.reason!.isNotEmpty)
            Text(
              l10n.history_event_reason(event.reason!),
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          Text(timestamp,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
      trailing: _wrapTrailing(
        trailingOverride ?? const Icon(Icons.swap_horiz, color: Colors.orange),
      ),
      isThreeLine: true,
    );
  }
}

class _MissedTile extends StatelessWidget {
  const _MissedTile({
    required this.event,
    required this.actorName,
    required this.actorPhotoUrl,
    required this.timestamp,
    required this.l10n,
    this.trailingOverride,
  });
  final MissedEvent event;
  final String actorName;
  final String? actorPhotoUrl;
  final String timestamp;
  final AppLocalizations l10n;
  final Widget? trailingOverride;

  @override
  Widget build(BuildContext context) {
    final visual = event.taskVisualSnapshot;
    final taskLabel = visual.kind == 'emoji'
        ? '${visual.value} ${event.taskTitleSnapshot}'
        : event.taskTitleSnapshot;

    return ListTile(
      key: Key('history_tile_${event.id}'),
      leading: _Avatar(photoUrl: actorPhotoUrl, name: actorName),
      title: Text(l10n.history_event_missed(actorName)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(taskLabel, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(timestamp,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
      trailing: _wrapTrailing(
        trailingOverride ?? const Icon(Icons.timer_off_outlined, color: Colors.orange),
      ),
      isThreeLine: true,
    );
  }
}
