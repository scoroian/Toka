// lib/features/history/presentation/history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../application/history_view_model.dart';
import '../domain/task_event.dart';
import 'widgets/history_empty_state.dart';
import 'widgets/history_event_tile.dart';
import 'widgets/history_filter_bar.dart';
import 'widgets/rate_event_sheet.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _loadInitial());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadInitial() {
    ref.read(historyViewModelProvider).loadMore();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(historyViewModelProvider).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final HistoryViewModel vm = ref.watch(historyViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.history_title)),
      body: Column(
        children: [
          HistoryFilterBar(
            current: vm.filter,
            onChanged: (f) => vm.applyFilter(f),
          ),
          Expanded(
            child: vm.items.when(
              loading: () => const LoadingWidget(),
              error: (_, __) => Center(child: Text(l10n.error_generic)),
              data: (items) {
                if (items.isEmpty) {
                  return const HistoryEmptyState();
                }
                final isPremium = vm.isPremium;
                final showBanner = !isPremium;
                final showLoadMore = vm.hasMore;
                final extraItems =
                    (showBanner ? 1 : 0) + (showLoadMore ? 1 : 0);

                return ListView.builder(
                  key: const Key('history_list'),
                  controller: _scrollController,
                  itemCount: items.length + extraItems,
                  itemBuilder: (context, index) {
                    if (index < items.length) {
                      return _buildEventTile(items[index]);
                    }
                    final extra = index - items.length;
                    if (showBanner && extra == 0) {
                      return _PremiumBanner(l10n: l10n);
                    }
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: TextButton(
                          key: const Key('btn_load_more'),
                          onPressed: () =>
                              ref.read(historyViewModelProvider).loadMore(),
                          child: Text(l10n.history_load_more),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventTile(TaskEventItem item) {
    final toName = switch (item.raw) {
      PassedEvent p => p.toUid,
      _ => null,
    };
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
              onPressed: () => _showRateSheet(item),
            )
          : null,
    );
  }

  void _showRateSheet(TaskEventItem item) {
    final HistoryViewModel vm = ref.read(historyViewModelProvider);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => RateEventSheet(
        onSubmit: (rating, note) =>
            vm.rateEvent(item.raw.id, rating, note: note),
      ),
    );
  }
}

class _PremiumBanner extends StatelessWidget {
  const _PremiumBanner({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('premium_banner'),
      margin: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock_outline),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.history_premium_banner_title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(l10n.history_premium_banner_body),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('btn_upgrade_premium'),
                onPressed: () {},
                child: Text(l10n.history_premium_banner_cta),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
