import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/ad_aware_bottom_padding.dart';
import '../../auth/application/auth_provider.dart';
import '../../homes/domain/home.dart';
import '../application/paywall_provider.dart';
import '../application/subscription_management_view_model.dart';
import '../domain/subscription_dashboard.dart';
import 'widgets/plan_summary_card.dart';

/// Pantalla *Ajustes → Gestionar suscripción*. Reemplaza la versión anterior
/// que leía un snapshot puntual: ahora consume el stream
/// `subscriptionDashboardProvider` para que el refresh sea automático tras
/// cualquier cambio de estado premium (BUG-12).
class SubscriptionManagementScreen extends ConsumerWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(subscriptionManagementViewModelProvider);
    final currentUid =
        ref.watch(authProvider).whenOrNull(authenticated: (u) => u.uid);

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
            ),
            _ActionSection(
              data: dashboard,
              vm: vm,
              isLoading: vm.isLoading,
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
  });
  final SubscriptionDashboard data;
  final SubscriptionManagementViewModel vm;
  final bool isLoading;

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
        return _actions([
          FilledButton(
            key: const Key('btn_manage_billing'),
            onPressed: isLoading ? null : () => _openPlayStoreSubscriptions(),
            child: Text(l10n.subscription_manage_billing),
          ),
          OutlinedButton(
            key: const Key('btn_cancel_renewal'),
            onPressed: isLoading ? null : () => _openPlayStoreSubscriptions(),
            child: Text(l10n.subscription_cancel_renewal),
          ),
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
