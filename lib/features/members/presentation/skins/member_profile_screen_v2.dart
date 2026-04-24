// lib/features/members/presentation/skins/member_profile_screen_v2.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:go_router/go_router.dart';

import '../../../../core/constants/routes.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/theme/app_colors_v2.dart';
import '../../../../core/utils/toka_dates.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/ad_aware_scaffold.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../history/application/member_reviews_provider.dart';
import '../../../homes/domain/home_membership.dart';
import '../../application/member_profile_view_model.dart';
import '../widgets/member_role_badge.dart';
import '../../../profile/presentation/widgets/radar_chart_widget.dart';

class MemberProfileScreenV2 extends ConsumerStatefulWidget {
  const MemberProfileScreenV2({
    super.key,
    required this.homeId,
    required this.memberUid,
  });
  final String homeId, memberUid;

  @override
  ConsumerState<MemberProfileScreenV2> createState() =>
      _MemberProfileScreenV2State();
}

class _MemberProfileScreenV2State extends ConsumerState<MemberProfileScreenV2> {
  bool _isLoading = false;

  Future<void> _confirmRemoveMember(
    BuildContext context,
    MemberProfileViewModel vm,
    MemberProfileViewData data,
    AppLocalizations l10n,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.member_profile_remove_member),
        content: Text(
            l10n.member_profile_remove_member_confirm(data.member.nickname)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.member_profile_remove_member),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    setState(() => _isLoading = true);
    try {
      await vm.removeMember(widget.homeId, widget.memberUid);
      if (context.mounted) Navigator.of(context).pop();
    } on CannotRemoveOwnerException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.error_cannot_remove_owner)));
      }
    } on PayerLockedException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.members_error_payer_locked)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.error_generic)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAdminRole(
    BuildContext context,
    MemberProfileViewModel vm,
    MemberProfileViewData data,
    AppLocalizations l10n,
  ) async {
    final isAdmin = data.member.role == MemberRole.admin;
    final action = isAdmin
        ? l10n.member_profile_demote_admin
        : l10n.member_profile_promote_admin;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(action),
        content: Text(isAdmin
            ? l10n.member_profile_demote_admin_confirm(data.member.nickname)
            : l10n.member_profile_promote_admin_confirm(data.member.nickname)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action)),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    setState(() => _isLoading = true);
    try {
      if (isAdmin) {
        await vm.demoteFromAdmin(widget.homeId, widget.memberUid);
      } else {
        await vm.promoteToAdmin(widget.homeId, widget.memberUid);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.error_generic)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final MemberProfileViewModel vm = ref.watch(
        memberProfileViewModelProvider(
            homeId: widget.homeId, memberUid: widget.memberUid));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColorsV2.backgroundDark : AppColorsV2.backgroundLight;

    return AdAwareScaffold(
      backgroundColor: bg,
      appBar: AppBar(backgroundColor: bg),
      body: vm.viewData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l10n.error_generic)),
        data: (data) {
          if (data == null) return const Center(child: CircularProgressIndicator());
          final member = data.member;
          final surf = isDark ? AppColorsV2.surfaceDark : AppColorsV2.surfaceLight;
          final bd = isDark ? AppColorsV2.borderDark : AppColorsV2.borderLight;

          return ListView(
            padding: EdgeInsets.fromLTRB(
              16, 8, 16,
              AdAwareScaffold.bottomPaddingOf(context, ref),
            ),
            children: [
              // Avatar + nombre
              Center(
                child: Column(children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundImage: member.photoUrl != null
                        ? CachedNetworkImageProvider(member.photoUrl!)
                        : null,
                    backgroundColor: AppColorsV2.primary,
                    child: member.photoUrl == null
                        ? Text(
                            member.nickname.isNotEmpty
                                ? member.nickname[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                fontSize: 28,
                                color: Colors.white,
                                fontWeight: FontWeight.w900))
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Text(member.nickname,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? AppColorsV2.textPrimaryDark
                              : AppColorsV2.textPrimaryLight)),
                  const SizedBox(height: 4),
                  MemberRoleBadge(role: member.role),
                ]),
              ),
              const SizedBox(height: 20),
              // Stats
              Row(children: [
                _StatCard(
                    key: const Key('stat_completed'),
                    value: '${data.completedCount}',
                    label: l10n.member_profile_tasks_completed,
                    bg: surf,
                    bd: bd,
                    isDark: isDark),
                const SizedBox(width: 8),
                _StatCard(
                    key: const Key('stat_streak'),
                    value: '${data.streakCount}',
                    label: l10n.member_profile_streak,
                    bg: surf,
                    bd: bd,
                    isDark: isDark),
                const SizedBox(width: 8),
                _StatCard(
                    key: const Key('stat_score'),
                    value: data.averageScore.toStringAsFixed(1),
                    label: l10n.member_profile_avg_score,
                    bg: surf,
                    bd: bd,
                    isDark: isDark),
              ]),
              const SizedBox(height: 20),
              RadarChartWidget(entries: data.radarEntries),
              if (data.canManageRoles && !data.isSelf) ...[
                const SizedBox(height: 20),
                if (data.canPromoteToAdmin)
                  ElevatedButton(
                    key: const Key('toggle_admin_button'),
                    onPressed: _isLoading
                        ? null
                        : () => _toggleAdminRole(context, vm, data, l10n),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(member.role == MemberRole.admin
                            ? l10n.member_profile_demote_admin
                            : l10n.member_profile_promote_admin),
                  )
                else if (data.adminsLockedToOwner &&
                    member.role != MemberRole.admin)
                  Container(
                    key: const Key('admins_locked_info'),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock_outline,
                            color: Theme.of(context)
                                .colorScheme
                                .onErrorContainer),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.free_admins_locked_to_owner,
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              if (data.canRemoveMember) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    key: const Key('remove_member_button'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    onPressed: _isLoading
                        ? null
                        : () =>
                            _confirmRemoveMember(context, vm, data, l10n),
                    child: Text(l10n.member_profile_remove_member),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _LastReviewsSection(
                homeId: widget.homeId,
                memberUid: widget.memberUid,
                l10n: l10n,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LastReviewsSection extends ConsumerWidget {
  const _LastReviewsSection({
    required this.homeId,
    required this.memberUid,
    required this.l10n,
  });

  final String homeId;
  final String memberUid;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewerUid =
        ref.watch(authProvider).whenOrNull(authenticated: (u) => u.uid) ?? '';
    if (viewerUid.isEmpty) return const SizedBox.shrink();

    final reviewsAsync = ref.watch(memberVisibleReviewsProvider(
      memberUid: memberUid,
      viewerUid: viewerUid,
    ));

    return reviewsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (reviews) {
        if (reviews.isEmpty) return const SizedBox.shrink();
        return Column(
          key: const Key('last_reviews_section'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.memberProfileLastReviews,
                style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ...reviews.map((r) => _LastReviewTile(
                  summary: r,
                  onTap: () => context.push(
                    AppRoutes.historyEventDetail
                        .replaceFirst(':homeId', r.homeId)
                        .replaceFirst(':eventId', r.eventId),
                  ),
                )),
          ],
        );
      },
    );
  }
}

class _LastReviewTile extends StatelessWidget {
  const _LastReviewTile({required this.summary, required this.onTap});

  final MemberReviewSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = summary.review;
    final dateStr = r.createdAt == null
        ? ''
        : TokaDates.dateLongFull(r.createdAt!, Localizations.localeOf(context));
    return ListTile(
      key: Key('last_review_${summary.eventId}'),
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.star, color: Colors.amber),
      title: Text(r.score.toStringAsFixed(1)),
      subtitle: Text(
        r.note != null && r.note!.isNotEmpty
            ? '${r.note}${dateStr.isNotEmpty ? ' · $dateStr' : ''}'
            : dateStr,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {super.key,
      required this.value,
      required this.label,
      required this.bg,
      required this.bd,
      required this.isDark});
  final String value, label;
  final Color bg, bd;
  final bool isDark;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: bd)),
          child: Column(children: [
            Text(value,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isDark
                        ? AppColorsV2.textPrimaryDark
                        : AppColorsV2.textPrimaryLight)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                    color: isDark
                        ? AppColorsV2.textSecondaryDark
                        : AppColorsV2.textSecondaryLight)),
          ]),
        ),
      );
}
