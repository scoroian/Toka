// lib/features/tasks/presentation/skins/all_tasks_screen_v2.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/routes.dart';
import '../../../../core/theme/app_colors_v2.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/no_home_empty_state.dart';
import '../../../../shared/widgets/skins/main_shell_v2.dart';
import '../../application/all_tasks_view_model.dart';
import '../../domain/task_status.dart';
import '../widgets/task_card.dart';

class AllTasksScreenV2 extends ConsumerStatefulWidget {
  const AllTasksScreenV2({super.key});
  @override
  ConsumerState<AllTasksScreenV2> createState() => _AllTasksScreenV2State();
}

class _AllTasksScreenV2State extends ConsumerState<AllTasksScreenV2>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fabCtrl;

  @override
  void initState() {
    super.initState();
    _fabCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _fabCtrl.forward();
  }

  @override
  void dispose() {
    _fabCtrl.dispose();
    super.dispose();
  }

  Future<bool> _confirmBulkDelete(AppLocalizations l10n, int count) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.tasks_bulk_delete_confirm_title(count)),
          content: Text(l10n.tasks_bulk_delete_confirm_body),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n.cancel)),
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l10n.delete)),
          ],
        ),
      ) ??
      false;

  Future<bool> _confirmDelete(AppLocalizations l10n) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.tasks_delete_confirm_title),
          content: Text(l10n.tasks_delete_confirm_body),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n.cancel)),
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l10n.delete)),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final AllTasksViewModel vm = ref.watch(allTasksViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return vm.viewData.when(
      loading: () => Scaffold(
        appBar: _buildAppBar(l10n, vm, isDark),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        appBar: _buildAppBar(l10n, vm, isDark),
        body: Center(child: Text(l10n.error_generic)),
      ),
      data: (data) {
        if (data == null) {
          return Scaffold(
            appBar: _buildAppBar(l10n, vm, isDark),
            body: NoHomeEmptyState(
              title: l10n.tasks_no_home_title,
              body: l10n.tasks_no_home_body,
            ),
          );
        }

        return Scaffold(
          appBar: _buildAppBar(l10n, vm, isDark),
          body: data.tasks.isEmpty
              ? Center(
                  key: const Key('tasks_empty_state'),
                  child: Text(l10n.tasks_empty_title))
              : ListView.builder(
                  key: const Key('tasks_list'),
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: data.tasks.length,
                  itemBuilder: (_, i) {
                    final task = data.tasks[i];
                    if (vm.isSelectionMode) {
                      return CheckboxListTile(
                        key: Key('selectable_task_${task.id}'),
                        value: vm.selectedIds.contains(task.id),
                        onChanged: (_) => vm.toggleSelection(task.id),
                        title: Text(
                          task.title,
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700),
                        ),
                        secondary: task.visualKind == 'emoji'
                            ? Text(task.visualValue,
                                style: const TextStyle(fontSize: 24))
                            : const Icon(Icons.task_alt),
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    }
                    return Dismissible(
                      key: Key('dismissible_${task.id}'),
                      background:
                          _FreezeBackground(l10n: l10n, isDark: isDark),
                      secondaryBackground:
                          _DeleteBackground(l10n: l10n, isDark: isDark),
                      confirmDismiss: (dir) async {
                        if (dir == DismissDirection.startToEnd) {
                          await vm.toggleFreeze(task);
                          return false;
                        }
                        return _confirmDelete(l10n);
                      },
                      onDismissed: (dir) async {
                        if (dir == DismissDirection.endToStart) {
                          await vm.deleteTask(task);
                        }
                      },
                      child: TaskCard(
                        task: task,
                        onTap: () => context.push('/tasks/${task.id}'),
                        onLongPress: () => vm.toggleSelection(task.id),
                      ),
                    );
                  },
                ),
          floatingActionButton: (!vm.isSelectionMode && data.canManage)
              ? Padding(
                  padding: const EdgeInsets.only(
                    bottom: MainShellV2.kNavBarHeight + MainShellV2.kNavBarBottom,
                  ),
                  child: ScaleTransition(
                    scale: CurvedAnimation(
                        parent: _fabCtrl, curve: Curves.elasticOut),
                    child: FloatingActionButton(
                      key: const Key('create_task_fab'),
                      backgroundColor: AppColorsV2.primary,
                      foregroundColor: AppColorsV2.onPrimary,
                      onPressed: () => context.push(AppRoutes.createTask),
                      child: const Icon(Icons.add),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  AppBar _buildAppBar(
      AppLocalizations l10n, AllTasksViewModel vm, bool isDark) {
    if (vm.isSelectionMode) {
      return AppBar(
        leading: IconButton(
          key: const Key('exit_selection_button'),
          icon: const Icon(Icons.close),
          onPressed: vm.clearSelection,
        ),
        title: Text(
          key: const Key('selection_count_text'),
          l10n.tasks_selection_count(vm.selectedIds.length),
        ),
        actions: [
          IconButton(
            key: const Key('bulk_freeze_button'),
            icon: const Icon(Icons.pause_circle_outline),
            onPressed: () async => vm.bulkFreeze(),
          ),
          IconButton(
            key: const Key('bulk_delete_button'),
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok =
                  await _confirmBulkDelete(l10n, vm.selectedIds.length);
              if (ok && mounted) await vm.bulkDelete();
            },
          ),
        ],
      );
    }
    return AppBar(
      title: Text(l10n.tasks_title),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(44),
        child: _FilterBarV2(
          current: vm.viewData.valueOrNull?.filter.status ?? TaskStatus.active,
          onChanged: vm.setStatusFilter,
          isDark: isDark,
        ),
      ),
    );
  }
}

class _FilterBarV2 extends StatelessWidget {
  const _FilterBarV2(
      {required this.current,
      required this.onChanged,
      required this.isDark});
  final TaskStatus current;
  final void Function(TaskStatus) onChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _chip(l10n.tasks_section_active, TaskStatus.active),
        const SizedBox(width: 8),
        _chip(l10n.tasks_section_frozen, TaskStatus.frozen),
      ]),
    );
  }

  Widget _chip(String label, TaskStatus status) => ChoiceChip(
        key: Key('filter_${status.name}'),
        label: Text(label,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        selected: current == status,
        onSelected: (_) => onChanged(status),
        selectedColor: AppColorsV2.primary,
      );
}

class _FreezeBackground extends StatelessWidget {
  const _FreezeBackground({required this.l10n, required this.isDark});
  final AppLocalizations l10n;
  final bool isDark;

  @override
  Widget build(BuildContext context) => Container(
        color: isDark ? const Color(0xFF1E3A5F) : Colors.blue.shade50,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        child: Row(children: [
          const Icon(Icons.pause_circle_outline),
          const SizedBox(width: 8),
          Text(l10n.tasks_action_freeze),
        ]),
      );
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground({required this.l10n, required this.isDark});
  final AppLocalizations l10n;
  final bool isDark;

  @override
  Widget build(BuildContext context) => Container(
        color: isDark ? const Color(0xFF3A1E1E) : Colors.red.shade50,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Row(children: [
          const Spacer(),
          const Icon(Icons.delete_outline),
          const SizedBox(width: 8),
          Text(l10n.delete),
        ]),
      );
}
