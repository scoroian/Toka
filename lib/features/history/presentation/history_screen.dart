// lib/features/history/presentation/history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/homes/application/current_home_provider.dart';
import '../../../features/homes/application/dashboard_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../application/history_provider.dart';
import '../domain/task_event.dart';
import 'widgets/history_empty_state.dart';
import 'widgets/history_event_tile.dart';
import 'widgets/history_filter_bar.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _scrollController = ScrollController();
  HistoryFilter _filter = const HistoryFilter();

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

  bool get _isPremium {
    final dashboard = ref.read(dashboardProvider).valueOrNull;
    return dashboard?.premiumFlags.isPremium ?? false;
  }

  String? get _homeId =>
      ref.read(currentHomeProvider).valueOrNull?.id;

  void _loadInitial() {
    final homeId = _homeId;
    if (homeId == null) return;
    ref
        .read(historyNotifierProvider(homeId).notifier)
        .loadMore(isPremium: _isPremium);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    final homeId = _homeId;
    if (homeId == null) return;
    ref
        .read(historyNotifierProvider(homeId).notifier)
        .loadMore(isPremium: _isPremium);
  }

  void _applyFilter(HistoryFilter filter) {
    final homeId = _homeId;
    if (homeId == null) return;
    setState(() => _filter = filter);
    ref
        .read(historyNotifierProvider(homeId).notifier)
        .applyFilter(filter);
    WidgetsBinding.instance.addPostFrameCallback((_) => ref
        .read(historyNotifierProvider(homeId).notifier)
        .loadMore(isPremium: _isPremium));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final homeAsync = ref.watch(currentHomeProvider);

    return homeAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.history_title)),
        body: const LoadingWidget(),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: Text(l10n.history_title)),
        body: Center(child: Text(l10n.error_generic)),
      ),
      data: (home) {
        if (home == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.history_title)),
            body: Center(child: Text(l10n.error_generic)),
          );
        }

        final historyAsync =
            ref.watch(historyNotifierProvider(home.id));
        final notifier =
            ref.read(historyNotifierProvider(home.id).notifier);
        final isPremium = _isPremium;

        return Scaffold(
          appBar: AppBar(title: Text(l10n.history_title)),
          body: Column(
            children: [
              HistoryFilterBar(
                current: _filter,
                onChanged: _applyFilter,
              ),
              Expanded(
                child: historyAsync.when(
                  loading: () => const LoadingWidget(),
                  error: (_, __) =>
                      Center(child: Text(l10n.error_generic)),
                  data: (events) {
                    if (events.isEmpty) {
                      return const HistoryEmptyState();
                    }
                    final showBanner = !isPremium;
                    final showLoadMore = notifier.hasMore;
                    final extraItems =
                        (showBanner ? 1 : 0) + (showLoadMore ? 1 : 0);

                    return ListView.builder(
                      key: const Key('history_list'),
                      controller: _scrollController,
                      itemCount: events.length + extraItems,
                      itemBuilder: (context, index) {
                        if (index < events.length) {
                          return _buildEventTile(events[index]);
                        }
                        final extra = index - events.length;
                        if (showBanner && extra == 0) {
                          return _PremiumBanner(l10n: l10n);
                        }
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: TextButton(
                              key: const Key('btn_load_more'),
                              onPressed: _loadMore,
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
      },
    );
  }

  Widget _buildEventTile(TaskEvent event) {
    String? toName;
    if (event is PassedEvent) toName = event.toUid;
    return HistoryEventTile(
      event: event,
      actorName: event.actorUid,
      actorPhotoUrl: null,
      toName: toName,
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
