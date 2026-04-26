// lib/features/profile/presentation/skins/futurista/profile_screen_futurista.dart
//
// Pantalla de perfil compartida (own + member) en skin Futurista. Se
// diferencia mediante el flag `isOwnProfile`:
//
//   - own:    consume `ownProfileViewModelProvider`. Header con icono
//             "ajustes" → AppRoutes.settings. CTA "Editar perfil" →
//             AppRoutes.editProfile.
//   - member: consume `memberProfileViewModelProvider(homeId, uid)`. Header
//             con back button + más-menú (acciones admin solo si el usuario
//             actual es owner del hogar).
//
// Layout (canvas `skin_futurista/screens-people.jsx` — PerfilScreen):
//   1. Header row.
//   2. Hero perfil centrado: avatar con anillo SweepGradient + badge premium
//      + display name + handle + pills (rol, premium, racha).
//   3. Row de KPIs (3 tiles iguales).
//   4. Card radar con ambient glow + footer "Brillas en …".
//   5. Sección "Últimas valoraciones" (si hay).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/routes.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/widgets/ad_aware_bottom_padding.dart';
import '../../../../../shared/widgets/futurista/radar_chart.dart';
import '../../../../../shared/widgets/futurista/tocka_avatar.dart';
import '../../../../../shared/widgets/futurista/tocka_btn.dart';
import '../../../../../shared/widgets/futurista/tocka_pill.dart';
import '../../../../auth/application/auth_provider.dart';
import '../../../../history/application/member_reviews_provider.dart';
import '../../../../homes/application/current_home_provider.dart';
import '../../../../homes/application/dashboard_provider.dart';
import '../../../../homes/domain/home_membership.dart';
import '../../../../members/application/member_actions_provider.dart';
import '../../../../members/application/member_profile_view_model.dart';
import '../../../../members/application/members_provider.dart';
import '../../../../members/domain/member.dart';
import '../../../application/own_profile_view_model.dart';
import '../../widgets/radar_chart_widget.dart';
import '../../widgets/review_dialog.dart';

class ProfileScreenFuturista extends ConsumerWidget {
  const ProfileScreenFuturista({
    super.key,
    required this.isOwnProfile,
    this.homeId,
    this.uid,
  });

  final bool isOwnProfile;
  final String? homeId;
  final String? uid;

  static const _mono = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 10.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.6,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: isOwnProfile
            ? _buildOwn(context, ref, l10n)
            : _buildMember(context, ref, l10n),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // OWN
  // ---------------------------------------------------------------------------
  Widget _buildOwn(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final vm = ref.watch(ownProfileViewModelProvider);
    return vm.viewData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(child: Text(l10n.error_generic)),
      data: (data) {
        if (data == null) {
          return Center(child: Text(l10n.error_generic));
        }
        final home = ref.watch(currentHomeProvider).valueOrNull;
        final dashboard = ref.watch(dashboardProvider).valueOrNull;
        final isPremium = dashboard?.premiumFlags.isPremium ?? false;
        final radarEntries = data.radarEntries.valueOrNull ?? const [];
        final viewerUid = data.profile.uid;

        return _ProfileBody(
          mono: _mono,
          header: _Header(
            key: const Key('fut_profile_header'),
            isOwn: true,
            onBack: null,
            onSettings: () => context.push(AppRoutes.settings),
            onMore: null,
          ),
          displayName: data.profile.nickname,
          handle: data.profile.uid,
          homeName: home?.name,
          isPremium: isPremium,
          role: null,
          streak: null,
          stats: const _Kpis(
            value1: '—',
            value2: '—',
            value3: '—',
            label1: 'TAREAS',
            label2: 'RACHA',
            label3: 'MEDIA',
          ),
          radarEntries: radarEntries,
          ctaButton: TockaBtn(
            key: const Key('fut_btn_edit_profile'),
            variant: TockaBtnVariant.glow,
            size: TockaBtnSize.md,
            fullWidth: true,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(AppRoutes.editProfile),
            child: Text(l10n.profile_edit),
          ),
          showReviews: true,
          memberUidForReviews: viewerUid,
          viewerUid: viewerUid,
          l10n: l10n,
          bottomPadding: adAwareBottomPadding(context, ref, extra: 16),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // MEMBER
  // ---------------------------------------------------------------------------
  Widget _buildMember(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final hId = homeId ?? '';
    final mUid = uid ?? '';
    if (hId.isEmpty || mUid.isEmpty) {
      return Center(child: Text(l10n.error_generic));
    }

    final vm = ref.watch(
        memberProfileViewModelProvider(homeId: hId, memberUid: mUid));
    return vm.viewData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(child: Text(l10n.error_generic)),
      data: (data) {
        if (data == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final m = data.member;
        final viewerUid = ref
                .watch(authProvider)
                .whenOrNull(authenticated: (u) => u.uid) ??
            '';
        final home = ref.watch(currentHomeProvider).valueOrNull;
        final dashboard = ref.watch(dashboardProvider).valueOrNull;
        final isPremium = dashboard?.premiumFlags.isPremium ?? false;

        return _ProfileBody(
          mono: _mono,
          header: _Header(
            key: const Key('fut_profile_header'),
            isOwn: false,
            onBack: () => context.pop(),
            onSettings: null,
            onMore: data.canManageRoles || data.canRemoveMember
                ? () => _showAdminSheet(context, ref, data, l10n)
                : null,
          ),
          displayName: m.nickname,
          handle: m.uid,
          homeName: home?.name,
          isPremium: isPremium,
          role: _roleLabel(l10n, m.role),
          streak: data.streakCount,
          stats: _Kpis(
            value1: '${data.completedCount}',
            value2: '${data.streakCount}',
            value3: data.averageScore.toStringAsFixed(1),
            label1: l10n.member_profile_tasks_completed.toUpperCase(),
            label2: l10n.member_profile_streak.toUpperCase(),
            label3: l10n.member_profile_avg_score.toUpperCase(),
          ),
          radarEntries: data.radarEntries,
          ctaButton: null,
          showReviews: true,
          memberUidForReviews: m.uid,
          viewerUid: viewerUid,
          l10n: l10n,
          bottomPadding: adAwareBottomPadding(context, ref, extra: 16),
        );
      },
    );
  }

  String? _roleLabel(AppLocalizations l10n, MemberRole role) =>
      switch (role) {
        MemberRole.owner => 'OWNER',
        MemberRole.admin => 'ADMIN',
        MemberRole.member => 'MEMBER',
        MemberRole.frozen => 'FROZEN',
      };

  Future<void> _showAdminSheet(
    BuildContext context,
    WidgetRef ref,
    MemberProfileViewData data,
    AppLocalizations l10n,
  ) async {
    final theme = Theme.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              key: const Key('fut_action_review'),
              leading: const Icon(Icons.star_border),
              title: Text(l10n.review_dialog_title),
              onTap: () {
                Navigator.pop(sheetCtx);
                _onReview(context, ref, data, l10n);
              },
            ),
            if (data.canRemoveMember)
              ListTile(
                key: const Key('fut_action_remove'),
                leading: Icon(Icons.person_remove_alt_1,
                    color: theme.colorScheme.error),
                title: Text(
                  l10n.member_profile_remove_member,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  await _onRemove(context, ref, data, l10n);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _onReview(
    BuildContext context,
    WidgetRef ref,
    MemberProfileViewData data,
    AppLocalizations l10n,
  ) async {
    final viewerUid = ref
            .read(authProvider)
            .whenOrNull(authenticated: (u) => u.uid) ??
        '';
    final dashboard = ref.read(dashboardProvider).valueOrNull;
    final isPremium = dashboard?.premiumFlags.isPremium ?? false;
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => ReviewDialog(
        homeId: homeId ?? '',
        taskEventId: '',
        taskTitle: '',
        performerName: data.member.nickname,
        isPremium: isPremium,
        currentUid: viewerUid,
        performerUid: data.member.uid,
        onSubmitted: () {},
      ),
    );
  }

  Future<void> _onRemove(
    BuildContext context,
    WidgetRef ref,
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
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.member_profile_remove_member),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(memberActionsProvider.notifier)
          .removeMember(homeId ?? '', data.member.uid);
      if (context.mounted) Navigator.of(context).pop();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.error_generic)),
        );
      }
    }
  }
}

// -----------------------------------------------------------------------------
// Body común
// -----------------------------------------------------------------------------
class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.mono,
    required this.header,
    required this.displayName,
    required this.handle,
    required this.homeName,
    required this.isPremium,
    required this.role,
    required this.streak,
    required this.stats,
    required this.radarEntries,
    required this.ctaButton,
    required this.showReviews,
    required this.memberUidForReviews,
    required this.viewerUid,
    required this.l10n,
    required this.bottomPadding,
  });

  final TextStyle mono;
  final Widget header;
  final String displayName;
  final String handle;
  final String? homeName;
  final bool isPremium;
  final String? role;
  final int? streak;
  final _Kpis stats;
  final List<RadarEntry> radarEntries;
  final Widget? ctaButton;
  final bool showReviews;
  final String memberUidForReviews;
  final String viewerUid;
  final AppLocalizations l10n;
  /// Bottom padding calculado por el padre con `adAwareBottomPadding`. Se
  /// inyecta como parámetro porque `_ProfileBody` es `StatelessWidget` sin
  /// acceso a `WidgetRef` — convertirlo a `ConsumerWidget` solo por esto sería
  /// excesivo.
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListView(
      padding: EdgeInsets.fromLTRB(0, 10, 0, bottomPadding),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: header,
        ),
        const SizedBox(height: 12),
        // Hero perfil
        Center(
          child: _HeroAvatar(
            name: displayName,
            color: cs.primary,
            isPremium: isPremium,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            displayName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: cs.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            '@${_shortHandle(handle)}',
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 11.5,
              letterSpacing: 0.2,
              color: cs.onSurface.withValues(alpha: 0.52),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Pills
        Center(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              if (role != null)
                TockaPill(
                  color: cs.primary,
                  child: Text(role!),
                ),
              if (isPremium)
                const TockaPill(
                  color: Color(0xFFF5B544),
                  glow: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium, size: 12),
                      SizedBox(width: 4),
                      Text('PREMIUM'),
                    ],
                  ),
                ),
              if (streak != null && streak! > 0)
                TockaPill(
                  color: const Color(0xFFFB7185),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department, size: 12),
                      const SizedBox(width: 4),
                      Text('Racha $streak'),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // KPIs
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: stats,
        ),
        const SizedBox(height: 18),
        // Radar card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _RadarCard(
            entries: radarEntries,
            homeName: homeName ?? '',
            mono: mono,
          ),
        ),
        if (ctaButton != null) ...[
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ctaButton!,
          ),
        ],
        if (showReviews && viewerUid.isNotEmpty) ...[
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _LastReviewsSection(
              memberUid: memberUidForReviews,
              viewerUid: viewerUid,
              mono: mono,
              l10n: l10n,
            ),
          ),
        ],
      ],
    );
  }

  String _shortHandle(String uid) {
    if (uid.isEmpty) return 'usuario';
    final s = uid.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    if (s.length <= 8) return s.toLowerCase();
    return s.substring(0, 8).toLowerCase();
  }
}

// -----------------------------------------------------------------------------
// Header
// -----------------------------------------------------------------------------
class _Header extends StatelessWidget {
  const _Header({
    super.key,
    required this.isOwn,
    required this.onBack,
    required this.onSettings,
    required this.onMore,
  });

  final bool isOwn;
  final VoidCallback? onBack;
  final VoidCallback? onSettings;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (!isOwn)
          _IconSlot(
            key: const Key('fut_btn_back'),
            icon: Icons.chevron_left,
            onTap: onBack,
          ),
        const Spacer(),
        if (isOwn)
          _IconSlot(
            key: const Key('fut_btn_settings'),
            icon: Icons.settings_outlined,
            onTap: onSettings,
          )
        else
          _IconSlot(
            key: const Key('fut_btn_more'),
            icon: Icons.more_vert,
            onTap: onMore,
          ),
      ],
    );
  }
}

class _IconSlot extends StatelessWidget {
  const _IconSlot({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Icon(icon, size: 20, color: theme.colorScheme.onSurface),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Hero avatar (sweep gradient ring + premium badge)
// -----------------------------------------------------------------------------
class _HeroAvatar extends StatelessWidget {
  const _HeroAvatar({
    required this.name,
    required this.color,
    required this.isPremium,
  });

  final String name;
  final Color color;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SizedBox(
      width: 102,
      height: 102,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 102,
            height: 102,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [cs.primary, cs.secondary, cs.primary],
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.scaffoldBackgroundColor,
              ),
              child: TockaAvatar(name: name, color: color, size: 84),
            ),
          ),
          if (isPremium)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF5B544), Color(0xFFD97706)],
                  ),
                  border: Border.all(
                    color: theme.scaffoldBackgroundColor,
                    width: 2.5,
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.workspace_premium,
                  size: 14,
                  color: Color(0xFF1A1000),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// KPIs row
// -----------------------------------------------------------------------------
class _Kpis extends StatelessWidget {
  const _Kpis({
    required this.value1,
    required this.value2,
    required this.value3,
    required this.label1,
    required this.label2,
    required this.label3,
  });

  final String value1, value2, value3;
  final String label1, label2, label3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final muted = cs.onSurface.withValues(alpha: 0.52);

    Widget tile(String value, String label, Color color) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
        );

    return Row(
      children: [
        tile(value1, label1, const Color(0xFF34D399)),
        const SizedBox(width: 8),
        tile(value2, label2, cs.onSurface),
        const SizedBox(width: 8),
        tile(value3, label3, const Color(0xFFF5B544)),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Radar card
// -----------------------------------------------------------------------------
class _RadarCard extends StatelessWidget {
  const _RadarCard({
    required this.entries,
    required this.homeName,
    required this.mono,
  });

  final List<RadarEntry> entries;
  final String homeName;
  final TextStyle mono;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final muted = cs.onSurface.withValues(alpha: 0.42);

    final sorted = [...entries]..sort((a, b) => b.avgScore.compareTo(a.avgScore));
    final top = sorted.take(2).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1,
                    colors: [
                      cs.primary.withValues(alpha: 0.10),
                      cs.primary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.radar, size: 16, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      homeName.isEmpty
                          ? 'PUNTOS FUERTES'
                          : 'PUNTOS FUERTES · ${homeName.toUpperCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: mono.copyWith(color: muted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (entries.length < 3)
                _EmptyRadar(message: _emptyMessage(entries.length))
              else
                Center(
                  child: RadarChart(
                    values: entries
                        .take(8)
                        .map((e) => (e.avgScore / 10).clamp(0.0, 1.0))
                        .toList(),
                    labels: entries
                        .take(8)
                        .map((e) => _shortLabel(e.taskName))
                        .toList(),
                    size: 220,
                  ),
                ),
              if (top.length >= 2) ...[
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 12, color: muted),
                    children: [
                      const TextSpan(text: 'Brillas en '),
                      TextSpan(
                        text: top[0].taskName,
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const TextSpan(text: ' y '),
                      TextSpan(
                        text: top[1].taskName,
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _shortLabel(String s) => s.length > 8 ? s.substring(0, 8) : s;

  String _emptyMessage(int n) => n == 0
      ? 'Sin datos suficientes'
      : 'Necesitas al menos 3 tareas valoradas';
}

class _EmptyRadar extends StatelessWidget {
  const _EmptyRadar({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 220,
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurface.withValues(alpha: 0.42),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Last reviews
// -----------------------------------------------------------------------------
class _LastReviewsSection extends ConsumerWidget {
  const _LastReviewsSection({
    required this.memberUid,
    required this.viewerUid,
    required this.mono,
    required this.l10n,
  });

  final String memberUid;
  final String viewerUid;
  final TextStyle mono;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final muted = cs.onSurface.withValues(alpha: 0.42);
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
          key: const Key('fut_last_reviews_section'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.memberProfileLastReviews.toUpperCase(),
              style: mono.copyWith(color: muted),
            ),
            const SizedBox(height: 8),
            ...reviews.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ReviewRow(summary: r),
                )),
          ],
        );
      },
    );
  }
}

class _ReviewRow extends ConsumerWidget {
  const _ReviewRow({required this.summary});

  final MemberReviewSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final muted = cs.onSurface.withValues(alpha: 0.52);
    final r = summary.review;
    final reviewerUid = r.reviewerUid;

    final reviewerName = ref
            .watch(homeMembersProvider(summary.homeId))
            .valueOrNull
            ?.cast<Member?>()
            .firstWhere(
              (m) => m?.uid == reviewerUid,
              orElse: () => null,
            )
            ?.nickname ??
        '—';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TockaAvatar(name: reviewerName, color: cs.primary, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reviewerName,
                  style: TextStyle(
                    fontSize: 12,
                    color: muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if ((r.note ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    r.note!,
                    style: TextStyle(fontSize: 13, color: cs.onSurface),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          TockaPill(
            color: const Color(0xFF34D399),
            child: Text('★ ${r.score.toStringAsFixed(0)}'),
          ),
        ],
      ),
    );
  }
}
