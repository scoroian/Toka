import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../profile/application/profile_provider.dart';
import '../../profile/presentation/widgets/radar_chart_widget.dart';
import '../../homes/domain/home_membership.dart';
import '../application/member_profile_view_model.dart';
import 'widgets/member_role_badge.dart';

class MemberProfileScreen extends ConsumerWidget {
  const MemberProfileScreen({
    super.key,
    required this.homeId,
    required this.memberUid,
  });

  final String homeId;
  final String memberUid;

  Future<void> _toggleAdminRole(
    BuildContext context,
    WidgetRef ref,
    MemberProfileViewModel vm,
    MemberProfileViewData data,
    AppLocalizations l10n,
  ) async {
    final member = data.member;
    final isAdmin = member.role == MemberRole.admin;
    final actionLabel = isAdmin
        ? l10n.member_profile_demote_admin
        : l10n.member_profile_promote_admin;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(actionLabel),
        content: Text(
          isAdmin
              ? l10n.member_profile_demote_admin_confirm(member.nickname)
              : l10n.member_profile_promote_admin_confirm(member.nickname),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      if (isAdmin) {
        await vm.demoteFromAdmin(homeId, memberUid);
      } else {
        await vm.promoteToAdmin(homeId, memberUid);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAdmin
                  ? l10n.member_profile_demoted_ok
                  : l10n.member_profile_promoted_ok,
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.error_generic)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final MemberProfileViewModel vm = ref.watch(
      memberProfileViewModelProvider(homeId: homeId, memberUid: memberUid),
    );

    return Scaffold(
      appBar: AppBar(),
      body: vm.viewData.when(
        loading: () => const LoadingWidget(),
        error: (_, __) => Center(child: Text(l10n.error_generic)),
        data: (data) {
          if (data == null) {
            return Center(child: Text(l10n.error_generic));
          }
          final member = data.member;

          // Fallback al perfil del usuario si el documento del miembro
          // no tiene nickname/photoUrl denormalizados.
          final profileFallback = (member.nickname.isEmpty || member.photoUrl == null)
              ? ref.watch(userProfileProvider(member.uid)).valueOrNull
              : null;
          final displayNickname = member.nickname.isNotEmpty
              ? member.nickname
              : profileFallback?.nickname ?? '?';
          final displayPhotoUrl =
              member.photoUrl ?? profileFallback?.photoUrl;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Avatar + nombre + bio
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundImage: displayPhotoUrl != null
                          ? CachedNetworkImageProvider(displayPhotoUrl)
                          : null,
                      child: displayPhotoUrl == null
                          ? Text(
                              displayNickname != '?'
                                  ? displayNickname[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(fontSize: 32),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      displayNickname,
                      key: const Key('member_nickname'),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    MemberRoleBadge(role: member.role),
                    if (member.bio != null && member.bio!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        member.bio!,
                        key: const Key('member_bio'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),

              // Teléfono (solo si visible)
              if (data.visiblePhone != null) ...[
                const SizedBox(height: 12),
                ListTile(
                  key: const Key('member_phone_tile'),
                  leading: const Icon(Icons.phone),
                  title: Text(data.visiblePhone!),
                ),
              ],

              const Divider(height: 32),

              // Estadísticas del hogar compartido
              Text(
                l10n.member_profile_home_stats,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _StatRow(
                key: const Key('stat_tasks_completed'),
                label: l10n.member_profile_tasks_completed,
                value: data.completedCount.toString(),
              ),
              _StatRow(
                key: const Key('stat_compliance'),
                label: l10n.member_profile_compliance,
                value: '${data.compliancePct}%',
              ),
              _StatRow(
                key: const Key('stat_streak'),
                label: l10n.member_profile_streak,
                value: data.streakCount.toString(),
              ),
              _StatRow(
                key: const Key('stat_avg_score'),
                label: l10n.member_profile_avg_score,
                value: '${data.averageScore.toStringAsFixed(1)}/10',
              ),
              if (data.showRadar) ...[
                const SizedBox(height: 24),
                RadarChartWidget(
                  key: const Key('radar_chart'),
                  entries: data.radarEntries,
                ),
              ],
              if (data.overflowEntries.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.member_profile_overflow_tasks_title,
                  key: const Key('overflow_tasks_title'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ...data.overflowEntries.map(
                  (e) => ListTile(
                    key: Key('overflow_task_${e.taskId}'),
                    dense: true,
                    leading: e.visualKind == 'emoji'
                        ? Text(e.visualValue, style: const TextStyle(fontSize: 20))
                        : const Icon(Icons.task_alt, size: 20),
                    title: Text(e.title),
                    trailing: Text(
                      e.averageScore.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
              // Gestión de rol (solo visible para el owner, sobre miembros ajenos)
              if (data.canManageRoles &&
                  member.role != MemberRole.owner) ...[
                const Divider(height: 32),
                OutlinedButton.icon(
                  key: const Key('btn_toggle_admin'),
                  onPressed: () => _toggleAdminRole(
                    context,
                    ref,
                    vm,
                    data,
                    l10n,
                  ),
                  icon: Icon(
                    member.role == MemberRole.admin
                        ? Icons.shield_outlined
                        : Icons.shield,
                  ),
                  label: Text(
                    member.role == MemberRole.admin
                        ? l10n.member_profile_demote_admin
                        : l10n.member_profile_promote_admin,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
