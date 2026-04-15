// lib/features/history/presentation/skins/history_screen_v2.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors_v2.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/history_view_model.dart';
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
                padding: const EdgeInsets.only(bottom: 96),
                itemCount: items.length + extras,
                itemBuilder: (ctx, i) {
                  if (i < items.length) return _buildTile(items[i], vm);
                  final extra = i - items.length;
                  if (!vm.isPremium && extra == 0) return _PremiumBannerV2(l10n: l10n, isDark: isDark);
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
    return HistoryEventTile(
      event: item.raw,
      actorName: item.actorName,
      actorPhotoUrl: item.actorPhotoUrl,
      toName: toName,
      trailing: item.canRate
          ? IconButton(
              key: Key('rate_button_${item.raw.id}'),
              icon: const Icon(Icons.star_border),
              tooltip: AppLocalizations.of(context).history_rate_button,
              onPressed: () => _showRateSheet(item, vm),
            )
          : null,
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
}

class _PremiumBannerV2 extends StatelessWidget {
  const _PremiumBannerV2({required this.l10n, required this.isDark});
  final AppLocalizations l10n;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColorsV2.surfaceDark : AppColorsV2.surfaceLight;
    final bd = isDark ? AppColorsV2.borderDark  : AppColorsV2.borderLight;
    return Container(
      key: const Key('premium_banner'),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bd),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l10n.history_premium_banner_title,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(l10n.history_premium_banner_body,
            style: GoogleFonts.plusJakartaSans(
                color: isDark ? AppColorsV2.textSecondaryDark : AppColorsV2.textSecondaryLight)),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            key: const Key('btn_upgrade_premium'),
            onPressed: () {},
            child: Text(l10n.history_premium_banner_cta),
          ),
        ),
      ]),
    );
  }
}
