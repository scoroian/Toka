import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/routes.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../application/own_profile_view_model.dart';
import '../widgets/access_management_section.dart';
import '../widgets/radar_chart_widget.dart';
import '../widgets/stats_section.dart';

class OwnProfileScreenV2 extends ConsumerWidget {
  const OwnProfileScreenV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(ownProfileViewModelProvider);

    return vm.viewData.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.profile_title)),
        body: const LoadingWidget(),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: Text(l10n.profile_title)),
        body: Center(child: Text(l10n.error_generic)),
      ),
      data: (viewData) {
        if (viewData == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.profile_title)),
            body: Center(child: Text(l10n.error_generic)),
          );
        }

        final profile = viewData.profile;
        final hasEmailPassword = viewData.hasEmailPassword;
        final radarAsync = viewData.radarEntries;

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.profile_title),
            actions: [
              TextButton(
                key: const Key('edit_profile_btn'),
                onPressed: () => context.push(AppRoutes.editProfile),
                child: Text(l10n.profile_edit),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Avatar + nombre + bio
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      key: const Key('own_avatar'),
                      radius: 48,
                      backgroundImage: profile.photoUrl != null
                          ? CachedNetworkImageProvider(profile.photoUrl!)
                          : null,
                      child: profile.photoUrl == null
                          ? Text(
                              profile.nickname.isNotEmpty
                                  ? profile.nickname[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(fontSize: 32),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profile.nickname,
                      key: const Key('own_nickname'),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (profile.bio != null && profile.bio!.isNotEmpty)
                      Text(
                        profile.bio!,
                        key: const Key('own_bio'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                  ],
                ),
              ),

              const Divider(height: 32),

              // Estadísticas globales
              Text(
                l10n.profile_global_stats,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              StatsSection(
                key: const Key('global_stats'),
                profile: profile,
                totalCompleted: 0,
                globalCompliance: 0.0,
              ),

              const SizedBox(height: 24),
              radarAsync.when(
                data: (entries) => RadarChartWidget(entries: entries),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const RadarChartWidget(entries: []),
              ),

              const Divider(height: 32),

              // Gestionar acceso
              Text(
                l10n.profile_access_management,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              AccessManagementSection(
                key: const Key('access_management'),
                hasEmailPassword: hasEmailPassword,
                onChangePassword: () {
                  // TODO: navegar a change password
                },
                onLogout: () async {
                  await vm.signOut();
                  if (context.mounted) context.go(AppRoutes.login);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
