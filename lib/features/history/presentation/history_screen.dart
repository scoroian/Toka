// lib/features/history/presentation/history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/application/auth_provider.dart';
import '../../homes/application/current_home_provider.dart';
import '../../members/application/members_provider.dart';
import '../../members/domain/member.dart';
import '../../profile/application/profile_provider.dart';
import '../../profile/domain/user_profile.dart';
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
    final isPremium = vm.isPremium;

    final homeId = ref.watch(currentHomeProvider).valueOrNull?.id;
    final currentUid =
        ref.watch(authProvider).whenOrNull(authenticated: (u) => u.uid);

    // Members from the home's subcollection (may lack nickname/photoUrl
    // if Cloud Functions didn't denormalise them from users/{uid}).
    final members = homeId != null
        ? ref.watch(homeMembersProvider(homeId)).valueOrNull ?? <Member>[]
        : <Member>[];
    final membersByUid = {for (final m in members) m.uid: m};

    // Collect every actor/recipient UID present in the loaded events so we
    // can watch their user profile as a fallback when the member doc is
    // incomplete (empty nickname / no photoUrl).
    final loadedEvents = vm.events.valueOrNull ?? <TaskEvent>[];
    final allEventUids = <String>{};
    for (final e in loadedEvents) {
      allEventUids.add(e.actorUid);
      if (e is PassedEvent) allEventUids.add(e.toUid);
    }

    // Build a fallback map: uid → UserProfile, only for UIDs whose member
    // document has an empty nickname (or is missing entirely).
    final profileFallback = <String, UserProfile>{};
    for (final uid in allEventUids) {
      final member = membersByUid[uid];
      if (member == null || member.nickname.isEmpty || member.photoUrl == null) {
        final profile = ref.watch(userProfileProvider(uid)).valueOrNull;
        if (profile != null) profileFallback[uid] = profile;
      }
    }

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
                        profileFallback,
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
    Map<String, UserProfile> profileFallback,
    String? currentUid,
    String? homeId,
    bool isPremium,
  ) {
    final member = membersByUid[event.actorUid];
    final fallback = profileFallback[event.actorUid];

    final actorName = (member?.nickname.isNotEmpty == true)
        ? member!.nickname
        : (fallback?.nickname.isNotEmpty == true)
            ? fallback!.nickname
            : '?';
    final actorPhotoUrl = member?.photoUrl ?? fallback?.photoUrl;

    String? toName;
    if (event is PassedEvent) {
      final toMember = membersByUid[event.toUid];
      final toFallback = profileFallback[event.toUid];
      toName = (toMember?.nickname.isNotEmpty == true)
          ? toMember!.nickname
          : (toFallback?.nickname.isNotEmpty == true)
              ? toFallback!.nickname
              : '?';
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
