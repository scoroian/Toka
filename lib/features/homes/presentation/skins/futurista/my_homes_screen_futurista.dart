// lib/features/homes/presentation/skins/futurista/my_homes_screen_futurista.dart
//
// Pantalla "Mis hogares" en skin Futurista (modal/route push). Consume el
// mismo `myHomesViewModelProvider` que `MyHomesScreenV2`. Layout adaptado del
// canvas `skin_futurista/screens-meta.jsx > SelectorHogarScreen`:
//
//   1. Header row: botón X close + título centrado "Mis hogares".
//   2. Lista de hogares (cards) — la card del hogar activo se destaca con
//      gradient + glow de primary.
//   3. CTA "Crear o unirme a otro hogar" → AppRoutes.onboarding.
//
// CONCERNS
//   - El VM `myHomesViewModelProvider` no expone plazas (slots usados/totales);
//     la card "PLAZAS DE HOGAR" del canvas se omite intencionalmente. Si se
//     añade un selector de slots al VM, replicar la card antes del listado.
//   - El borde "dashed" del CTA del canvas se simula con un Border.all sólido a
//     baja opacidad; Flutter no tiene dashed border nativo y no se ha añadido
//     dependencia para no inflar el árbol.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/routes.dart';
import '../../../../../core/theme/futurista/futurista_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../application/my_homes_view_model.dart';
import '../../../domain/home_membership.dart';

class MyHomesScreenFuturista extends ConsumerWidget {
  const MyHomesScreenFuturista({super.key});

  String _roleLabel(MemberRole role, AppLocalizations l10n) {
    switch (role) {
      case MemberRole.owner:
        return l10n.homes_role_owner;
      case MemberRole.admin:
        return l10n.homes_role_admin;
      case MemberRole.member:
      case MemberRole.frozen:
        return l10n.homes_role_member;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final vm = ref.watch(myHomesViewModelProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _Header(title: l10n.homes_my_homes),
            Expanded(
              child: vm.memberships.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(child: Text(l10n.error_generic)),
                data: (memberships) {
                  if (memberships.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Spacer(),
                          _CreateOrJoinCta(
                            onTap: () => context.push(AppRoutes.onboarding),
                          ),
                          const Spacer(flex: 2),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    key: const Key('my_homes_list'),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: memberships.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index == memberships.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: _CreateOrJoinCta(
                            onTap: () => context.push(AppRoutes.onboarding),
                          ),
                        );
                      }
                      final m = memberships[index];
                      final isActive = m.homeId == vm.currentHomeId;
                      return _HomeCard(
                        membership: m,
                        isActive: isActive,
                        roleLabel: _roleLabel(m.role, l10n),
                        primary: cs.primary,
                        onTap: () {
                          if (!isActive) {
                            vm.switchHome(m.homeId);
                            if (context.mounted) context.pop();
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Header con botón close
// -----------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          _CloseButton(),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: cs.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 38),
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: const Key('my_homes_close'),
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            Navigator.of(context).maybePop();
          }
        },
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Icon(Icons.close, size: 18, color: cs.onSurfaceVariant),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Card de hogar
// -----------------------------------------------------------------------------

class _HomeCard extends StatelessWidget {
  const _HomeCard({
    required this.membership,
    required this.isActive,
    required this.roleLabel,
    required this.primary,
    required this.onTap,
  });

  final HomeMembership membership;
  final bool isActive;
  final String roleLabel;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final slotColor = _colorForHomeId(membership.homeId);
    final initial = _initialFor(membership.homeNameSnapshot);

    final decoration = isActive
        ? BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primary.withValues(alpha: 0.14),
                cs.surface,
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: primary.withValues(alpha: 0.31)),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.35),
                blurRadius: 50,
                offset: const Offset(0, 20),
                spreadRadius: -20,
              ),
            ],
          )
        : BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.dividerColor),
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('home_list_tile_${membership.homeId}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: decoration,
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      slotColor,
                      slotColor.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      membership.homeNameSnapshot,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      roleLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.check,
                  size: 18,
                  color: primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _initialFor(String name) {
    final n = name.trim();
    if (n.isEmpty) return '?';
    return n.characters.first.toUpperCase();
  }

  Color _colorForHomeId(String homeId) {
    if (homeId.isEmpty) return FuturistaColors.primary;
    const palette = <Color>[
      FuturistaColors.primary,
      FuturistaColors.primaryAlt,
      FuturistaColors.success,
      FuturistaColors.warning,
      FuturistaColors.error,
    ];
    final idx = homeId.codeUnits.fold<int>(0, (a, b) => a + b) % palette.length;
    return palette[idx];
  }
}

// -----------------------------------------------------------------------------
// CTA crear / unirme
// -----------------------------------------------------------------------------

class _CreateOrJoinCta extends StatelessWidget {
  const _CreateOrJoinCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('my_homes_create_or_join'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: cs.onSurface.withValues(alpha: 0.18),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                size: 16,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                'Crear o unirme a otro hogar',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
