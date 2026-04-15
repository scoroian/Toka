// lib/features/members/presentation/skins/member_profile_screen_v2.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors_v2.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../homes/domain/home_membership.dart';
import '../../application/member_profile_view_model.dart';
import '../widgets/member_role_badge.dart';
import '../../../profile/presentation/widgets/radar_chart_widget.dart';

class MemberProfileScreenV2 extends ConsumerWidget {
  const MemberProfileScreenV2({
    super.key, required this.homeId, required this.memberUid,
  });
  final String homeId, memberUid;

  Future<void> _toggleAdminRole(
    BuildContext context, WidgetRef ref,
    MemberProfileViewModel vm, MemberProfileViewData data,
    AppLocalizations l10n,
  ) async {
    final isAdmin = data.member.role == MemberRole.admin;
    final action  = isAdmin ? l10n.member_profile_demote_admin : l10n.member_profile_promote_admin;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(action),
        content: Text(isAdmin
            ? l10n.member_profile_demote_admin_confirm(data.member.nickname)
            : l10n.member_profile_promote_admin_confirm(data.member.nickname)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true),  child: Text(action)),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      if (isAdmin) {
        await vm.demoteFromAdmin(homeId, memberUid);
      } else {
        await vm.promoteToAdmin(homeId, memberUid);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.error_generic)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n  = AppLocalizations.of(context);
    final MemberProfileViewModel vm =
        ref.watch(memberProfileViewModelProvider(homeId: homeId, memberUid: memberUid));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg    = isDark ? AppColorsV2.backgroundDark : AppColorsV2.backgroundLight;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(backgroundColor: bg),
      body: vm.viewData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l10n.error_generic)),
        data: (data) {
          if (data == null) return const Center(child: CircularProgressIndicator());
          final member = data.member;
          final surf   = isDark ? AppColorsV2.surfaceDark : AppColorsV2.surfaceLight;
          final bd     = isDark ? AppColorsV2.borderDark  : AppColorsV2.borderLight;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              // Avatar + nombre
              Center(child: Column(children: [
                CircleAvatar(
                  radius: 44,
                  backgroundImage: member.photoUrl != null
                      ? CachedNetworkImageProvider(member.photoUrl!) : null,
                  backgroundColor: AppColorsV2.primary,
                  child: member.photoUrl == null
                      ? Text(member.nickname.isNotEmpty ? member.nickname[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w900))
                      : null,
                ),
                const SizedBox(height: 10),
                Text(member.nickname,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 20, fontWeight: FontWeight.w900,
                        color: isDark ? AppColorsV2.textPrimaryDark : AppColorsV2.textPrimaryLight)),
                const SizedBox(height: 4),
                MemberRoleBadge(role: member.role),
              ])),
              const SizedBox(height: 20),
              // Stats
              Row(children: [
                _StatCard(key: const Key('stat_completed'), value: '${data.completedCount}',
                    label: l10n.member_profile_tasks_completed, bg: surf, bd: bd, isDark: isDark),
                const SizedBox(width: 8),
                _StatCard(key: const Key('stat_streak'), value: '${data.streakCount}',
                    label: l10n.member_profile_streak,    bg: surf, bd: bd, isDark: isDark),
                const SizedBox(width: 8),
                _StatCard(key: const Key('stat_score'),
                    value: data.averageScore.toStringAsFixed(1),
                    label: l10n.member_profile_avg_score, bg: surf, bd: bd, isDark: isDark),
              ]),
              if (data.showRadar) ...[
                const SizedBox(height: 20),
                RadarChartWidget(entries: data.radarEntries),
              ],
              if (data.canManageRoles && !data.isSelf) ...[
                const SizedBox(height: 20),
                ElevatedButton(
                  key: const Key('toggle_admin_button'),
                  onPressed: () => _toggleAdminRole(context, ref, vm, data, l10n),
                  child: Text(member.role == MemberRole.admin
                      ? l10n.member_profile_demote_admin
                      : l10n.member_profile_promote_admin),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({super.key, required this.value, required this.label,
      required this.bg, required this.bd, required this.isDark});
  final String value, label;
  final Color bg, bd;
  final bool isDark;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: bd)),
      child: Column(children: [
        Text(value,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 22, fontWeight: FontWeight.w900,
                color: isDark ? AppColorsV2.textPrimaryDark : AppColorsV2.textPrimaryLight)),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.1,
                color: isDark ? AppColorsV2.textSecondaryDark : AppColorsV2.textSecondaryLight)),
      ]),
    ),
  );
}
