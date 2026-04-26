// lib/features/history/presentation/skins/futurista/history_screen_futurista.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/routes.dart';
import '../../../../../core/theme/futurista/futurista_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/widgets/ad_aware_bottom_padding.dart';
import '../../../../../shared/widgets/bottom_sheet_padding.dart';
import '../../../../../shared/widgets/futurista/premium_banner_futurista.dart';
import '../../../../../shared/widgets/futurista/tocka_avatar.dart';
import '../../../../../shared/widgets/futurista/tocka_btn.dart';
import '../../../../../shared/widgets/futurista/tocka_chip.dart';
import '../../../../../shared/widgets/futurista/tocka_pill.dart';
import '../../../../../shared/widgets/futurista/tocka_top_bar.dart';
import '../../../../homes/application/current_home_provider.dart';
import '../../../../homes/domain/home.dart';
import '../../../../members/application/members_provider.dart';
import '../../../../members/domain/member.dart';
import '../../../domain/task_event.dart';
import '../../../application/history_view_model.dart';
import '../../widgets/show_rate_sheet.dart';

/// Pantalla "Historial" en skin futurista. Consume el mismo
/// `historyViewModelProvider` que v2 y mantiene el filtrado por tipo de
/// evento vía `HistoryFilter.eventType`.
///
/// Layout:
///  1. `TockaTopBar` con nombre de hogar y avatars.
///  2. Título "Historial" + `TockaPill` "30 días" / "90 días" según isPremium.
///  3. Fila horizontal de `TockaChip`: Todo / Completadas / Pases / Vencidas.
///  4. Grupos por día con tiles compactos (check / switch / system slot).
class HistoryScreenFuturista extends ConsumerStatefulWidget {
  const HistoryScreenFuturista({super.key});

  @override
  ConsumerState<HistoryScreenFuturista> createState() =>
      _HistoryScreenFuturistaState();
}

class _HistoryScreenFuturistaState
    extends ConsumerState<HistoryScreenFuturista> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(historyViewModelProvider).loadMore();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      ref.read(historyViewModelProvider).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final HistoryViewModel vm = ref.watch(historyViewModelProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            const _TopBarFromState(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.history_title,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  TockaPill(
                    color: vm.isPremium
                        ? theme.colorScheme.primary
                        : null,
                    child: Text(vm.isPremium ? '90 días' : '30 días'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _FilterChipsRow(vm: vm),
            const SizedBox(height: 8),
            Expanded(
              child: vm.items.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Text(
                    l10n.error_generic,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.history_empty_title,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }
                  final groups = _groupByDay(items);
                  final showPremiumBanner = !vm.isPremium;
                  final extras = showPremiumBanner ? 1 : 0;
                  return ListView.builder(
                    key: const Key('history_list_futurista'),
                    controller: _scroll,
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 4,
                      bottom:
                          adAwareBottomPadding(context, ref, extra: 16),
                    ),
                    itemCount: groups.length + extras,
                    itemBuilder: (ctx, i) {
                      if (i >= groups.length) {
                        return const PremiumBannerFuturista();
                      }
                      final g = groups[i];
                      return _DayGroup(
                        label: g.label,
                        items: g.items,
                        isPremium: vm.isPremium,
                        onRate: (item) => showRateSheet(ctx, vm, item),
                        onUpgradeFromRate: () => _showUpgradeSheet(ctx),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Intencionalmente duplicado entre v2 y futurista: la skin futurista usa
  /// `TockaBtn` y la v2 usa `ElevatedButton` (Material). La spec 2F
  /// (§3 "decisiones tomadas") decide NO deduplicar este sheet por la
  /// divergencia visual establecida en el commit `4f90fef`.
  void _showUpgradeSheet(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);
    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + bottomSheetSafeBottom(sheetCtx, ref, hasNavBar: true),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.star, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.free_reviews_upgrade_title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Text(l10n.free_reviews_upgrade_body),
            const SizedBox(height: 20),
            TockaBtn(
              key: const Key('btn_upgrade_from_rate_fut'),
              variant: TockaBtnVariant.primary,
              size: TockaBtnSize.md,
              fullWidth: true,
              onPressed: () {
                Navigator.of(sheetCtx).pop();
                ctx.push(AppRoutes.paywall);
              },
              child: Text(l10n.free_go_premium_cta),
            ),
          ],
        ),
      ),
    );
  }

  List<_DayGroupData> _groupByDay(List<TaskEventItem> items) {
    final Map<String, List<TaskEventItem>> buckets = {};
    final List<String> order = [];
    for (final it in items) {
      final dt = _eventDate(it.raw).toLocal();
      final key = '${dt.year}-${dt.month}-${dt.day}';
      if (!buckets.containsKey(key)) {
        buckets[key] = [];
        order.add(key);
      }
      buckets[key]!.add(it);
    }
    return order.map((k) {
      final first = buckets[k]!.first;
      return _DayGroupData(
        label: _dayLabel(_eventDate(first.raw).toLocal()),
        items: buckets[k]!,
      );
    }).toList();
  }
}

DateTime _eventDate(TaskEvent e) => switch (e) {
      CompletedEvent c => c.completedAt,
      PassedEvent p => p.createdAt,
      MissedEvent m => m.missedAt,
    };

String _dayLabel(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final that = DateTime(dt.year, dt.month, dt.day);
  final diff = today.difference(that).inDays;
  final dd = dt.day.toString().padLeft(2, '0');
  final mm = _monthShort(dt.month);
  if (diff == 0) return 'HOY · $dd $mm';
  if (diff == 1) return 'AYER · $dd $mm';
  return '$dd $mm';
}

String _monthShort(int m) {
  const names = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];
  return names[(m - 1).clamp(0, 11)];
}

class _DayGroupData {
  const _DayGroupData({required this.label, required this.items});
  final String label;
  final List<TaskEventItem> items;
}

class _TopBarFromState extends ConsumerWidget {
  const _TopBarFromState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final AsyncValue<Home?> homeAsync = ref.watch(currentHomeProvider);
    final home = homeAsync.valueOrNull;
    final homeName = home?.name ?? l10n.history_no_home_title;

    List<MemberAvatar> members = const [];
    if (home != null) {
      final membersAsync = ref.watch(homeMembersProvider(home.id));
      final list = membersAsync.valueOrNull ?? const <Member>[];
      members = list
          .take(3)
          .map((m) => (name: m.nickname, color: _colorFor(m.uid)))
          .toList();
    }
    return TockaTopBar(homeName: homeName, members: members);
  }

  static Color _colorFor(String uid) {
    final palette = <Color>[
      FuturistaColors.primary,
      FuturistaColors.primaryAlt,
      FuturistaColors.success,
      FuturistaColors.warning,
      FuturistaColors.error,
    ];
    final idx =
        uid.codeUnits.fold<int>(0, (a, b) => a + b) % palette.length;
    return palette[idx];
  }
}

class _FilterChipsRow extends StatelessWidget {
  const _FilterChipsRow({required this.vm});

  final HistoryViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = vm.filter.eventType;
    final chips = <({String? type, String label})>[
      (type: null, label: l10n.history_filter_all),
      (type: 'completed', label: l10n.history_filter_completed),
      (type: 'passed', label: l10n.history_filter_passed),
      (type: 'missed', label: l10n.history_filter_missed),
    ];
    return SizedBox(
      height: 36,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            for (int i = 0; i < chips.length; i++) ...[
              TockaChip(
                key: Key('history_chip_${chips[i].type ?? 'all'}'),
                active: current == chips[i].type,
                onTap: () => vm.applyFilter(
                  vm.filter.copyWith(eventType: chips[i].type),
                ),
                child: Text(chips[i].label),
              ),
              if (i < chips.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _DayGroup extends StatelessWidget {
  const _DayGroup({
    required this.label,
    required this.items,
    required this.isPremium,
    required this.onRate,
    required this.onUpgradeFromRate,
  });

  final String label;
  final List<TaskEventItem> items;
  final bool isPremium;
  final void Function(TaskEventItem) onRate;
  final VoidCallback onUpgradeFromRate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Column(
          children: [
            for (final it in items) ...[
              _EventRow(
                item: it,
                isPremium: isPremium,
                onRate: () => onRate(it),
                onUpgradeFromRate: onUpgradeFromRate,
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ],
    );
  }
}

class _EventRow extends ConsumerWidget {
  const _EventRow({
    required this.item,
    required this.isPremium,
    required this.onRate,
    required this.onUpgradeFromRate,
  });

  final TaskEventItem item;
  final bool isPremium;
  final VoidCallback onRate;
  final VoidCallback onUpgradeFromRate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    final kind = _kindOf(item.raw);
    final (iconData, iconColor, bg, border) = switch (kind) {
      _EventKind.done => (
          Icons.check,
          FuturistaColors.success,
          FuturistaColors.success.withValues(alpha: 0.09),
          FuturistaColors.success.withValues(alpha: 0.25),
        ),
      _EventKind.pass => (
          Icons.switch_account,
          FuturistaColors.warning,
          FuturistaColors.warning.withValues(alpha: 0.09),
          FuturistaColors.warning.withValues(alpha: 0.25),
        ),
      _EventKind.sys => (
          Icons.settings,
          cs.onSurfaceVariant,
          cs.surfaceContainerHighest,
          theme.dividerColor,
        ),
    };

    final description = _descriptionFor(item, l10n);
    final timeLabel = _timeLabel(_eventDate(item.raw).toLocal());

    final trailing = _buildTrailing();

    final body = Container(
      key: Key('history_row_fut_${item.raw.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: border),
            ),
            child: Icon(iconData, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    TockaAvatar(
                      name: item.actorName,
                      color: _avatarColor(item),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeLabel,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10.5,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing,
          ],
        ],
      ),
    );

    final isDetailable = item.raw is CompletedEvent || item.raw is PassedEvent;
    final homeId = ref.read(currentHomeProvider).valueOrNull?.id;
    if (isDetailable && homeId != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('history_tile_tap_${item.raw.id}'),
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push(
            AppRoutes.historyEventDetail
                .replaceFirst(':homeId', homeId)
                .replaceFirst(':eventId', item.raw.id),
          ),
          child: body,
        ),
      );
    }
    return body;
  }

  Widget? _buildTrailing() {
    if (isPremium) {
      if (item.isRated) {
        return const Icon(Icons.star, color: Colors.amber, size: 18);
      }
      if (item.canRate) {
        return IconButton(
          key: Key('rate_button_fut_${item.raw.id}'),
          icon: const Icon(Icons.star_border),
          iconSize: 18,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: onRate,
        );
      }
      return null;
    }
    final isRateable = item.raw is CompletedEvent && !item.isOwnEvent;
    if (isRateable) {
      return IconButton(
        key: Key('rate_upgrade_fut_${item.raw.id}'),
        icon: Icon(Icons.star_border, color: Colors.grey.shade500),
        iconSize: 18,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        onPressed: onUpgradeFromRate,
      );
    }
    return null;
  }

  Color _avatarColor(TaskEventItem it) {
    final palette = <Color>[
      FuturistaColors.primary,
      FuturistaColors.primaryAlt,
      FuturistaColors.success,
      FuturistaColors.warning,
      FuturistaColors.error,
    ];
    final seed = it.actorName.codeUnits.fold<int>(0, (a, b) => a + b);
    return palette[seed % palette.length];
  }

  _EventKind _kindOf(TaskEvent e) => switch (e) {
        CompletedEvent _ => _EventKind.done,
        PassedEvent _ => _EventKind.pass,
        MissedEvent _ => _EventKind.sys,
      };

  String _descriptionFor(TaskEventItem it, AppLocalizations l10n) {
    final e = it.raw;
    return switch (e) {
      CompletedEvent c =>
        '${l10n.history_event_completed(it.actorName)} · ${c.taskTitleSnapshot}',
      PassedEvent p =>
        '${it.actorName} → ${it.toName ?? '?'} · ${p.taskTitleSnapshot}',
      MissedEvent m =>
        '${l10n.history_event_missed(it.actorName)} · ${m.taskTitleSnapshot}',
    };
  }

  String _timeLabel(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

enum _EventKind { done, pass, sys }
