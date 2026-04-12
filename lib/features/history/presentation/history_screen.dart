// lib/features/history/presentation/history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/application/auth_provider.dart';
import '../../homes/application/current_home_provider.dart';
import '../../members/application/members_provider.dart';
import '../../members/domain/member.dart';
import '../application/history_provider.dart';
import '../application/history_view_model.dart';
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
    final vm = ref.watch(historyViewModelProvider);

    final homeId = ref.watch(currentHomeProvider).valueOrNull?.id;
    final currentUid =
        ref.watch(authProvider).whenOrNull(authenticated: (u) => u.uid);

    final members = homeId != null
        ? ref.watch(homeMembersProvider(homeId)).valueOrNull ?? <Member>[]
        : <Member>[];
    final membersByUid = {for (final m in members) m.uid: m};

    return Scaffold(
      appBar: AppBar(title: Text(l10n.history_title)),
      body: Column(
        children: [
          HistoryFilterBar(
            current: vm.filter,
            onChanged: (f) => vm.applyFilter(f),
          ),
          Expanded(
            child: vm.events.when(
              loading: () => const LoadingWidget(),
              error: (_, __) => Center(child: Text(l10n.error_generic)),
              data: (events) {
                if (events.isEmpty) {
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
                  itemCount: events.length + extraItems,
                  itemBuilder: (context, index) {
                    if (index < events.length) {
                      return _buildEventTile(
                        events[index],
                        membersByUid,
                        currentUid,
                        homeId,
                        isPremium,
                      );
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

  Widget _buildEventTile(
    TaskEvent event,
    Map<String, Member> membersByUid,
    String? currentUid,
    String? homeId,
    bool isPremium,
  ) {
    final actor = membersByUid[event.actorUid];
    final actorName =
        (actor?.nickname.isNotEmpty == true) ? actor!.nickname : '?';
    final actorPhotoUrl = actor?.photoUrl;

    String? toName;
    if (event is PassedEvent) {
      final toMember = membersByUid[event.toUid];
      toName =
          (toMember?.nickname.isNotEmpty == true) ? toMember!.nickname : '?';
    }

    return HistoryEventTile(
      event: event,
      actorName: actorName,
      actorPhotoUrl: actorPhotoUrl,
      toName: toName,
      homeId: homeId,
      currentUid: currentUid,
      isPremium: isPremium,
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
