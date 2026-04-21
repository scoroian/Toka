// lib/features/history/presentation/skins/history_screen_v2.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/routes.dart';
import '../../../../core/theme/app_colors_v2.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/history_view_model.dart';
import '../../../../shared/widgets/bottom_sheet_padding.dart';
import '../../../../shared/widgets/no_home_empty_state.dart';
import '../../../../shared/widgets/premium_upgrade_banner.dart';
import '../widgets/history_empty_state.dart';
import '../widgets/history_event_tile.dart';
import '../widgets/history_filter_bar.dart';
import '../widgets/rate_event_sheet.dart';
import '../../domain/task_event.dart';

class HistoryScreenV2 extends ConsumerStatefulWidget {
  const HistoryScreenV2({super.key});
  @override
  ConsumerState<HistoryScreenV2> createState() => _HistoryScreenV2State();
}

class _HistoryScreenV2State extends ConsumerState<HistoryScreenV2> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        ref.read(historyViewModelProvider).loadMore());
  }

  @override
  void dispose() { _scroll.dispose(); super.dispose(); }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      ref.read(historyViewModelProvider).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n  = AppLocalizations.of(context);
    final HistoryViewModel vm = ref.watch(historyViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg    = isDark ? AppColorsV2.backgroundDark : AppColorsV2.backgroundLight;

    if (!vm.hasHome) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          title: Text(l10n.history_title,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900)),
        ),
        body: NoHomeEmptyState(
          title: l10n.history_no_home_title,
          body: l10n.history_no_home_body,
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text(l10n.history_title,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900)),
      ),
      body: Column(children: [
        HistoryFilterBar(current: vm.filter, onChanged: vm.applyFilter),
        Expanded(
          child: vm.items.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(child: Text(l10n.error_generic)),
            data: (items) {
              if (items.isEmpty) return const HistoryEmptyState();
              final extras = (!vm.isPremium ? 1 : 0) + (vm.hasMore ? 1 : 0);
              return ListView.builder(
                key: const Key('history_list'),
                controller: _scroll,
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: items.length + extras,
                itemBuilder: (ctx, i) {
                  if (i < items.length) return _buildTile(items[i], vm);
                  final extra = i - items.length;
                  if (!vm.isPremium && extra == 0) {
                    return Padding(
                      key: const Key('premium_banner'),
                      padding: const EdgeInsets.all(16),
                      child: PremiumUpgradeBanner(
                        title: l10n.history_premium_banner_title,
                        message: l10n.history_premium_banner_body,
                        cta: l10n.history_premium_banner_cta,
                        ctaKey: const Key('btn_upgrade_premium'),
                        onCta: () => context.push(AppRoutes.paywall),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(child: TextButton(
                      key: const Key('btn_load_more'),
                      onPressed: () => ref.read(historyViewModelProvider).loadMore(),
                      child: Text(l10n.history_load_more),
                    )),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _buildTile(TaskEventItem item, HistoryViewModel vm) {
    final toName = item.raw is PassedEvent ? (item.raw as PassedEvent).toUid : null;
    final l10n = AppLocalizations.of(context);
    Widget? trailing;
    if (vm.isPremium) {
      if (item.isRated) {
        trailing = const Icon(Icons.star, color: Colors.amber, size: 22);
      } else if (item.canRate) {
        trailing = IconButton(
          key: Key('rate_button_${item.raw.id}'),
          icon: const Icon(Icons.star_border),
          tooltip: l10n.history_rate_button,
          onPressed: () => _showRateSheet(item, vm),
        );
      }
    } else {
      final isRateable = item.raw is CompletedEvent && !item.isOwnEvent;
      if (isRateable) {
        trailing = IconButton(
          key: Key('rate_upgrade_${item.raw.id}'),
          icon: Icon(Icons.star_border, color: Colors.grey.shade500),
          tooltip: l10n.free_reviews_upgrade_title,
          onPressed: _showUpgradeSheet,
        );
      }
    }
    return HistoryEventTile(
      event: item.raw,
      actorName: item.actorName,
      actorPhotoUrl: item.actorPhotoUrl,
      toName: toName,
      trailing: trailing,
    );
  }

  void _showRateSheet(TaskEventItem item, HistoryViewModel vm) {
    showModalBottomSheet<void>(
      context: context, isScrollControlled: true,
      builder: (_) => RateEventSheet(
        onSubmit: (rating, note) => vm.rateEvent(item.raw.id, rating, note: note),
      ),
    );
  }

  void _showUpgradeSheet() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
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
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Text(l10n.free_reviews_upgrade_body),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('btn_upgrade_from_rate'),
                onPressed: () {
                  Navigator.of(sheetCtx).pop();
                  context.push(AppRoutes.paywall);
                },
                child: Text(l10n.free_go_premium_cta),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

