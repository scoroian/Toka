// lib/features/members/presentation/skins/futurista/vacation_screen_futurista.dart
//
// Pantalla "Vacaciones / Ausencia" en skin Futurista. Consume el mismo
// `vacationViewModelNotifierProvider` que `VacationScreenV2` y reutiliza la
// lógica de pickers + guardado (los métodos `_pickDate` y `_save` son idénticos).
// Solo cambia la composición visual: hero icónico, tipografía mono para labels,
// tarjeta agrupando toggle + selectores y CTA `TockaBtn primary lg`.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/utils/toka_dates.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/widgets/futurista/tocka_btn.dart';
import '../../../application/vacation_view_model.dart';

class VacationScreenFuturista extends ConsumerStatefulWidget {
  const VacationScreenFuturista({
    super.key,
    required this.homeId,
    required this.uid,
  });

  final String homeId;
  final String uid;

  @override
  ConsumerState<VacationScreenFuturista> createState() =>
      _VacationScreenFuturistaState();
}

class _VacationScreenFuturistaState
    extends ConsumerState<VacationScreenFuturista> {
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final primary = cs.primary;
    final muted = cs.onSurface.withValues(alpha: 0.6);

    final notifier = ref.watch(
      vacationViewModelNotifierProvider(widget.homeId, widget.uid).notifier,
    );
    final vm = ref.watch(
      vacationViewModelNotifierProvider(widget.homeId, widget.uid),
    );

    // Initialize reasonController from loaded vacation (once) — paridad con v2.
    if (vm.isInitialized && _reasonController.text.isEmpty) {
      // No-op: misma semántica que v2 (la razón sólo se introduce manualmente).
    }

    const monoLabel = TextStyle(
      fontFamily: 'JetBrainsMono',
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.4,
    );

    Widget dateRow({
      required String label,
      required DateTime? value,
      required VoidCallback onTap,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: monoLabel.copyWith(color: muted),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today, size: 16, color: muted),
                  const SizedBox(width: 10),
                  Text(
                    value != null
                        ? TokaDates.dateShort(value, locale)
                        : '—',
                    style: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.vacation_title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        children: [
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primary.withValues(alpha: 0.19),
                    primary.withValues(alpha: 0.04),
                  ],
                ),
                border: Border.all(
                  color: primary.withValues(alpha: 0.33),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.55),
                    blurRadius: 60,
                    offset: const Offset(0, 30),
                    spreadRadius: -20,
                  ),
                ],
              ),
              child: Center(
                child: Icon(Icons.beach_access, size: 40, color: primary),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Modo vacaciones',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ) ??
                const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mientras estés en vacaciones, las tareas no te tocarán a ti.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: muted,
            ),
          ),
          const SizedBox(height: 28),
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.vacation_toggle_label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Switch(
                      key: const Key('vacation_toggle'),
                      value: vm.isActive,
                      onChanged: notifier.setActive,
                    ),
                  ],
                ),
                if (vm.isActive)
                  Column(
                    key: const Key('vacation_date_pickers'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Container(height: 1, color: theme.dividerColor),
                      const SizedBox(height: 16),
                      dateRow(
                        label: l10n.vacation_start_date,
                        value: vm.startDate,
                        onTap: () => _pickDate(notifier, true),
                      ),
                      const SizedBox(height: 12),
                      dateRow(
                        label: l10n.vacation_end_date,
                        value: vm.endDate,
                        onTap: () => _pickDate(notifier, false),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'MOTIVO',
                        style: monoLabel.copyWith(color: muted),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _reasonController,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText: l10n.vacation_reason,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TockaBtn(
            key: const Key('btn_save_vacation'),
            variant: TockaBtnVariant.primary,
            size: TockaBtnSize.lg,
            fullWidth: true,
            onPressed: () => _save(notifier),
            child: Text(l10n.vacation_save),
          ),
        ],
      ),
    );
  }
}
