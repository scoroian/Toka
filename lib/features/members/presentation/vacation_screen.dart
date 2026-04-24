import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/toka_dates.dart';
import '../../../l10n/app_localizations.dart';
import '../application/vacation_view_model.dart';

class VacationScreen extends ConsumerStatefulWidget {
  const VacationScreen({super.key, required this.homeId, required this.uid});

  final String homeId;
  final String uid;

  @override
  ConsumerState<VacationScreen> createState() => _VacationScreenState();
}

class _VacationScreenState extends ConsumerState<VacationScreen> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(
      VacationViewModelNotifier notifier, bool isStart) async {
    final now = DateTime.now();
    final current = isStart ? notifier.startDate : notifier.endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    if (isStart) {
      notifier.setStartDate(picked);
    } else {
      notifier.setEndDate(picked);
    }
  }

  Future<void> _save(VacationViewModelNotifier notifier) async {
    final reason = _reasonController.text.trim().isEmpty
        ? null
        : _reasonController.text.trim();
    await notifier.save(reason: reason);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);

    final notifier = ref.watch(
      vacationViewModelNotifierProvider(widget.homeId, widget.uid).notifier,
    );
    // Watch state so widget rebuilds on changes
    final vm = ref.watch(
      vacationViewModelNotifierProvider(widget.homeId, widget.uid),
    );

    // Initialize reasonController from loaded vacation (once)
    if (vm.isInitialized && _reasonController.text.isEmpty) {
      // No-op — reason is only user-entered, existing reason not shown
      // (Screen re-create reads fresh state anyway)
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.vacation_title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            key: const Key('vacation_toggle'),
            title: Text(l10n.vacation_toggle_label),
            value: vm.isActive,
            onChanged: notifier.setActive,
          ),
          if (vm.isActive)
            Column(
              key: const Key('vacation_date_pickers'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(l10n.vacation_start_date),
                  subtitle: Text(
                    vm.startDate != null
                        ? TokaDates.dateShort(vm.startDate!, locale)
                        : '—',
                  ),
                  onTap: () => _pickDate(notifier, true),
                ),
                ListTile(
                  leading: const Icon(Icons.event_available),
                  title: Text(l10n.vacation_end_date),
                  subtitle: Text(
                    vm.endDate != null
                        ? TokaDates.dateShort(vm.endDate!, locale)
                        : '—',
                  ),
                  onTap: () => _pickDate(notifier, false),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    labelText: l10n.vacation_reason,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('btn_save_vacation'),
            onPressed: () => _save(notifier),
            child: Text(l10n.vacation_save),
          ),
        ],
      ),
    );
  }
}
