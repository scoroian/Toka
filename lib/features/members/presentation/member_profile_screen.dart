import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../profile/presentation/widgets/radar_chart_widget.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(
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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Avatar + nombre + bio
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundImage: member.photoUrl != null
                          ? NetworkImage(member.photoUrl!)
                          : null,
                      child: member.photoUrl == null
                          ? Text(
                              member.nickname.isNotEmpty
                                  ? member.nickname[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(fontSize: 32),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      member.nickname,
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
                value: member.tasksCompleted.toString(),
              ),
              _StatRow(
                key: const Key('stat_compliance'),
                label: l10n.member_profile_compliance,
                value: '${data.compliancePct}%',
              ),
              _StatRow(
                key: const Key('stat_streak'),
                label: l10n.member_profile_streak,
                value: member.currentStreak.toString(),
              ),
              _StatRow(
                key: const Key('stat_avg_score'),
                label: l10n.member_profile_avg_score,
                value: '${member.averageScore.toStringAsFixed(1)}/10',
              ),
              const SizedBox(height: 24),
              RadarChartWidget(entries: data.radarEntries),
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
