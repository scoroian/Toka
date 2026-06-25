import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/routes.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/ad_aware_bottom_padding.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../homes/domain/home.dart';
import '../../../homes/domain/home_membership.dart';
import '../../../members/application/members_provider.dart';
import '../../application/home_tiers_provider.dart';
import '../../application/member_packs_enabled_provider.dart';
import '../../application/paywall_provider.dart';
import '../../application/subscription_management_view_model.dart';
import '../../domain/member_pack_catalog.dart';
import '../../domain/subscription_dashboard.dart';
import '../pack_display.dart';
import '../widgets/pack_cancel_dialog.dart';
import '../widgets/plan_summary_card.dart';

/// Pantalla *Ajustes → Gestionar suscripción*. Reemplaza la versión anterior
/// que leía un snapshot puntual: ahora consume el stream
/// `subscriptionDashboardProvider` para que el refresh sea automático tras
/// cualquier cambio de estado premium (BUG-12).
class SubscriptionManagementScreenV2 extends ConsumerWidget {
  const SubscriptionManagementScreenV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(subscriptionManagementViewModelProvider);
    final currentUid =
        ref.watch(authProvider).whenOrNull(authenticated: (u) => u.uid);

    // Nombre del miembro pagador, para mostrarlo cuando el pagador NO soy yo
    // (así se ve quién del hogar paga). Watch condicional: solo se leen los
    // miembros si hay un pagador distinto al usuario actual, evitando lecturas
    // en estados sin pagador (free/expired/restorable) o cuando pago yo.
    final payerUid = vm.dashboard.valueOrNull?.currentPayerUid;
    String? payerName;
    if (payerUid != null && payerUid != currentUid && vm.homeId.isNotEmpty) {
      final members = ref.watch(homeMembersProvider(vm.homeId)).valueOrNull;
      if (members != null) {
        for (final m in members) {
          if (m.uid == payerUid) {
            payerName = m.nickname;
            break;
          }
        }
      }
    }

    // Para el aviso de congelación al cancelar un pack necesitamos el nº de
    // miembros activos EN VIVO (no `planCounters`, que queda stale tras
    // expulsar/abandonar). Solo se lee cuando el eje de packs está activo.
    final packsEnabled = ref.watch(memberPacksEnabledProvider);
    int activeMembers = 0;
    if (packsEnabled && vm.homeId.isNotEmpty) {
      final members = ref.watch(homeMembersProvider(vm.homeId)).valueOrNull;
      if (members != null) {
        activeMembers =
            members.where((m) => m.status == MemberStatus.active).length;
      }
    }

    ref.listen<AsyncValue<dynamic>>(paywallProvider, (_, next) {
      next.whenOrNull(
        data: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.subscription_restore_success)),
          );
        },
        error: (err, _) {
          final msg = err.toString().contains('restore_window_expired')
              ? l10n.subscription_restore_expired_error
              : l10n.error_generic;
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.subscription_management_title)),
      body: vm.dashboard.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l10n.error_generic),
          ),
        ),
        data: (dashboard) => ListView(
          padding: EdgeInsets.only(
            top: 8,
            bottom: adAwareBottomPadding(context, ref, extra: 16),
          ),
          children: [
            PlanSummaryCard(
              data: dashboard,
              currentUserUid: currentUid,
              payerName: payerName,
              showPacks: packsEnabled,
            ),
            _ActionSection(
              data: dashboard,
              vm: vm,
              isLoading: vm.isLoading,
              isCurrentUserPayer: dashboard.currentPayerUid == currentUid,
              tiersEnabled: ref.watch(homeTiersEnabledProvider),
              packsEnabled: packsEnabled,
              activeMembers: activeMembers,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bloque de CTAs — primario + secundario — por estado. Extraído para poder
/// testear la tabla de acciones del spec de forma independiente del card.
class _ActionSection extends StatelessWidget {
  const _ActionSection({
    required this.data,
    required this.vm,
    required this.isLoading,
    required this.isCurrentUserPayer,
    required this.tiersEnabled,
    required this.packsEnabled,
    required this.activeMembers,
  });
  final SubscriptionDashboard data;
  final SubscriptionManagementViewModel vm;
  final bool isLoading;
  final bool isCurrentUserPayer;
  final bool tiersEnabled;
  final bool packsEnabled;
  final int activeMembers;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    switch (data.status) {
      case HomePremiumStatus.free:
      case HomePremiumStatus.purged:
        return _actions([
          FilledButton(
            key: const Key('btn_go_premium'),
            onPressed:
                isLoading ? null : () => context.push(AppRoutes.paywall),
            child: Text(l10n.premium_gate_upgrade),
          ),
        ]);
      case HomePremiumStatus.active:
        // "Gestionar facturación" y "Cancelar renovación" abren la tienda
        // (Google Play) y solo tienen sentido para el PAGADOR. A un admin
        // no-pagador no le mostramos estos CTAs (el PlanSummaryCard ya indica
        // quién paga); evita que aterrice en su propia gestión de Play vacía.
        if (!isCurrentUserPayer) return const SizedBox.shrink();
        return _actions([
          FilledButton(
            key: const Key('btn_manage_billing'),
            onPressed: isLoading ? null : () => _openPlayStoreSubscriptions(),
            child: Text(l10n.subscription_manage_billing),
          ),
          // Cambiar de tier (upsell/bajada): abre el paywall de tiers. El cambio
          // real lo procesa la store y el backend reconcilia/congela excedentes
          // (store-handoff). Solo con el flag de tiers ON.
          if (tiersEnabled)
            OutlinedButton(
              key: const Key('btn_change_plan_tier'),
              onPressed:
                  isLoading ? null : () => context.push(AppRoutes.paywall),
              child: Text(l10n.subscription_change_plan),
            ),
          OutlinedButton(
            key: const Key('btn_cancel_renewal'),
            onPressed: isLoading ? null : () => _openPlayStoreSubscriptions(),
            child: Text(l10n.subscription_cancel_renewal),
          ),
          // Packs de miembro: solo en Grupo con el flag ON. "Añadir pack" abre
          // el paywall (sección de packs); cada pack activo se puede cancelar,
          // mostrando antes el aviso de congelación de excedentes.
          if (packsEnabled && data.tier == 'grupo') ...[
            OutlinedButton(
              key: const Key('btn_add_pack'),
              onPressed: isLoading ? null : () => context.push(AppRoutes.paywall),
              child: Text(l10n.subscription_add_pack),
            ),
            for (final pack in _activePacks)
              OutlinedButton(
                key: Key('btn_cancel_pack_${pack.id}'),
                onPressed: isLoading ? null : () => _cancelPack(context, pack),
                child: Text(
                    l10n.subscription_cancel_pack(packDisplayName(l10n, pack))),
              ),
          ],
        ]);
      case HomePremiumStatus.cancelledPendingEnd:
        return _actions([
          FilledButton(
            key: const Key('btn_reactivate_renewal'),
            onPressed:
                isLoading ? null : () => context.push(AppRoutes.paywall),
            child: Text(l10n.subscription_reactivate_renewal),
          ),
          OutlinedButton(
            key: const Key('btn_change_plan'),
            onPressed:
                isLoading ? null : () => context.push(AppRoutes.paywall),
            child: Text(l10n.subscription_change_plan),
          ),
        ]);
      case HomePremiumStatus.rescue:
        return _actions([
          FilledButton(
            key: const Key('btn_renew'),
            onPressed:
                isLoading ? null : () => context.push(AppRoutes.rescueScreen),
            child: Text(l10n.rescue_banner_renew),
          ),
          OutlinedButton(
            key: const Key('btn_plan_downgrade'),
            onPressed: isLoading
                ? null
                : () => context.push(AppRoutes.downgradePlanner),
            child: Text(l10n.subscription_plan_downgrade),
          ),
        ]);
      case HomePremiumStatus.expiredFree:
        return _actions([
          FilledButton(
            key: const Key('btn_reactivate_premium'),
            onPressed:
                isLoading ? null : () => context.push(AppRoutes.paywall),
            child: Text(l10n.subscription_reactivate_premium),
          ),
        ]);
      case HomePremiumStatus.restorable:
        return _actions([
          FilledButton(
            key: const Key('btn_restore_premium'),
            onPressed: isLoading ? null : () => vm.restorePremium(),
            child: Text(l10n.subscription_restore_btn),
          ),
        ]);
    }
  }

  Widget _actions(List<Widget> buttons) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < buttons.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            buttons[i],
          ],
        ],
      ),
    );
  }

  /// Packs activos del hogar según el dashboard (`premiumFlags.memberPacks`).
  List<MemberPack> get _activePacks {
    final packs = data.memberPacks;
    return [
      if (packs?.plus5 ?? false) MemberPack.plus5,
      if (packs?.plus10 ?? false) MemberPack.plus10,
    ];
  }

  /// Cancela un pack: muestra el aviso de congelación (tope resultante +
  /// excedentes a congelar) y, si se confirma, abre la gestión de suscripciones
  /// de la store. El freeze real lo aplica el backend al reportar la store.
  Future<void> _cancelPack(BuildContext context, MemberPack pack) async {
    final newMax = (data.maxMembers ?? kAbsoluteMaxMembers) - pack.seats;
    final confirmed = await showPackCancelFreezeDialog(
      context,
      pack: pack,
      newMax: newMax,
      activeMembers: activeMembers,
      endsAt: data.endsAt,
    );
    if (confirmed && context.mounted) await _openPlayStoreSubscriptions();
  }

  Future<void> _openPlayStoreSubscriptions() async {
    final uri =
        Uri.parse('https://play.google.com/store/account/subscriptions');
    // Best-effort: si el lanzamiento falla (emulador sin Play Store) no
    // rompemos la navegación; el usuario se queda en la misma pantalla.
    await canLaunchUrl(uri).then((ok) {
      if (ok) launchUrl(uri, mode: LaunchMode.externalApplication);
    });
  }
}
