// lib/features/tasks/presentation/skins/today_screen_v2.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/ad_aware_bottom_padding.dart';
import '../../../subscription/presentation/widgets/premium_state_banner.dart';
import '../../application/pending_completions_provider.dart';
import '../../application/today_view_model.dart';
import '../../domain/failed_completion.dart';
import '../../domain/home_dashboard.dart';
import '../../../../features/homes/presentation/home_selector_widget.dart';
import '../widgets/pass_turn_dialog.dart';
import '../widgets/today_empty_state.dart';
import 'widgets/today_header_counters_v2.dart';
import 'widgets/today_skeleton_v2.dart';
import 'widgets/today_task_section_v2.dart';

class TodayScreenV2 extends ConsumerWidget {
  const TodayScreenV2({super.key});

  /// Completar SIN diálogo de confirmación (patrón Gmail). La animación+confetti
  /// de la tarjeta ya dio el feedback de éxito; aquí se programa el commit
  /// diferido (la tarea se oculta de "Por hacer") y se ofrece "Deshacer" durante
  /// [kUndoWindow]. Si no se deshace, el commit real al backend se confirma al
  /// expirar la ventana. Las acciones consecuentes (pasar turno, borrar, expulsar,
  /// abandonar) conservan su propia confirmación.
  void _onDone(
    BuildContext ctx,
    WidgetRef ref,
    AppLocalizations l10n,
    TaskPreview task,
    String homeId,
  ) {
    ref
        .read(pendingCompletionsProvider.notifier)
        .schedule(homeId: homeId, taskId: task.taskId, taskTitle: task.title);
    ScaffoldMessenger.of(ctx)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(l10n.today_task_completed_undoable),
        duration: kUndoWindow,
        behavior: SnackBarBehavior.floating,
        // persist por defecto es `action != null` (Flutter 3.44): un SnackBar
        // con acción NO se auto-cierra. Forzamos persist:false para que
        // desaparezca al expirar la ventana de Deshacer, en sync con el commit.
        persist: false,
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () => ref
              .read(pendingCompletionsProvider.notifier)
              .undo(task.taskId),
        ),
      ));
  }

  /// Reacciona a un commit de completación que FALLÓ (Hallazgo #02): nunca en
  /// silencio. Avisa al usuario con un SnackBar localizado.
  ///   - transient (red): ofrece **Reintentar** (reusa la clave de idempotencia);
  ///     la tarjeta ya muestra una marca persistente "No se guardó".
  ///   - conflict (carrera de turno): mensaje informativo sin Reintentar y se
  ///     descarta la marca (la lista en vivo refleja el estado real).
  void _onCompletionFailed(
    BuildContext ctx,
    WidgetRef ref,
    AppLocalizations l10n,
    FailedCompletion f,
  ) {
    final messenger = ScaffoldMessenger.of(ctx)..clearSnackBars();
    if (f.kind == CompletionFailureKind.conflict) {
      ref.read(pendingCompletionsProvider.notifier).dismiss(f.taskId);
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.today_task_completion_conflict(f.taskTitle)),
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        persist: false,
      ));
    } else {
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.today_task_completion_failed(f.taskTitle)),
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
        persist: false,
        action: SnackBarAction(
          label: l10n.retry,
          onPressed: () =>
              ref.read(pendingCompletionsProvider.notifier).retry(f.taskId),
        ),
      ));
    }
  }

  Future<void> _onPass(BuildContext ctx, TodayViewModel vm, TaskPreview task, String? uid) async {
    if (uid == null) return;
    final info = await vm.fetchPassInfo(task.taskId, uid);
    if (!ctx.mounted) return;
    String? reason;
    bool confirmed = false;
    await showDialog<void>(
      context: ctx,
      builder: (_) => PassTurnDialog(
        task: task,
        currentComplianceRate: info.complianceBefore,
        estimatedComplianceAfter: info.estimatedAfter,
        nextAssigneeName: info.nextAssigneeName,
        onConfirm: (r) { confirmed = true; reason = r; },
      ),
    );
    if (confirmed && ctx.mounted) await vm.passTurn(task.taskId, reason: reason);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final TodayViewModel vm = ref.watch(todayViewModelProvider);

    // Hallazgo #02: avisar de cualquier completación cuyo commit acabó fallando
    // (incluye los fallos del flush al volver de segundo plano). Solo reacciona
    // a los `taskId` recién añadidos a `failed` para no repetir el aviso.
    ref.listen<PendingCompletionsState>(pendingCompletionsProvider,
        (prev, next) {
      final prevFailed = prev?.failed ?? const <String, FailedCompletion>{};
      for (final f in next.failed.values) {
        if (!prevFailed.containsKey(f.taskId)) {
          _onCompletionFailed(context, ref, l10n, f);
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const HomeSelectorWidget(),
      ),
      body: vm.viewData.when(
        loading: () => const TodaySkeletonV2(),
        error: (_, __) => Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l10n.error_generic),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: vm.retry, child: Text(l10n.retry)),
          ],
        )),
        data: (data) {
          if (data == null && vm.homes.isEmpty) return _NoHomeEmptyState(widgetRef: ref);
          if (data == null) return const TodayEmptyState();
          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: PremiumStateBanner()),
              SliverToBoxAdapter(
                child: TodayHeaderCountersV2(counters: data.counters)),
              for (final recType in data.recurrenceOrder)
                if (data.grouped[recType] != null)
                  TodayTaskSectionV2(
                    recurrenceType: recType,
                    todos: data.grouped[recType]!.todos,
                    upcoming: data.grouped[recType]!.upcoming,
                    dones: data.grouped[recType]!.dones,
                    currentUid: data.currentUid,
                    onDone: data.homeId.isNotEmpty
                        ? (t) => _onDone(context, ref, l10n, t, data.homeId)
                        : null,
                    onPass: data.homeId.isNotEmpty
                        ? (t) => _onPass(context, vm, t, data.currentUid) : null,
                  ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: adAwareBottomPadding(context, ref, extra: 16),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NoHomeEmptyState extends StatelessWidget {
  const _NoHomeEmptyState({required this.widgetRef});

  final WidgetRef widgetRef;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              l10n.today_no_home_title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.today_no_home_body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              key: const Key('no_home_create_button'),
              onPressed: () => showCreateHomeSheet(context, widgetRef, 0),
              icon: const Icon(Icons.add),
              label: Text(l10n.onboarding_create_home_button),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('no_home_join_button'),
              onPressed: () => showJoinHomeSheet(context, widgetRef, 0),
              icon: const Icon(Icons.group_add_outlined),
              label: Text(l10n.onboarding_join_home),
            ),
          ],
        ),
      ),
    );
  }
}
