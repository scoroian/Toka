import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../features/auth/application/auth_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../application/members_provider.dart';
import '../domain/member.dart';
import '../../profile/application/member_radar_provider.dart';
import '../../profile/presentation/widgets/radar_chart_widget.dart';
import 'widgets/member_role_badge.dart';

part 'member_profile_screen.g.dart';

@riverpod
Future<Member> memberDetail(
    MemberDetailRef ref, String homeId, String uid) async {
  return ref.watch(membersRepositoryProvider).fetchMember(homeId, uid);
}

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
    final auth = ref.watch(authProvider);
    final currentUid = auth.whenOrNull(authenticated: (u) => u.uid) ?? '';
    final isSelf = currentUid == memberUid;

    final memberAsync = ref.watch(memberDetailProvider(homeId, memberUid));
    final radarAsync = ref.watch(memberRadarProvider(homeId: homeId, uid: memberUid));

    return Scaffold(
      appBar: AppBar(),
      body: memberAsync.when(
        loading: () => const LoadingWidget(),
        error: (_, __) => Center(child: Text(l10n.error_generic)),
        data: (member) {
          final visiblePhone = member.phoneForViewer(isSelf: isSelf);
          final compliancePct =
              (member.complianceRate * 100).toStringAsFixed(1);

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
              if (visiblePhone != null) ...[
                const SizedBox(height: 12),
                ListTile(
                  key: const Key('member_phone_tile'),
                  leading: const Icon(Icons.phone),
                  title: Text(visiblePhone),
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
                value: '$compliancePct%',
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
              radarAsync.when(
                data: (entries) => RadarChartWidget(entries: entries),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const RadarChartWidget(entries: []),
              ),
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
