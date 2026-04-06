import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../application/vacation_provider.dart';
import '../domain/vacation.dart';

class VacationScreen extends ConsumerStatefulWidget {
  const VacationScreen({super.key, required this.homeId, required this.uid});

  final String homeId;
  final String uid;

  @override
  ConsumerState<VacationScreen> createState() => _VacationScreenState();
}

class _VacationScreenState extends ConsumerState<VacationScreen> {
  bool _isActive = false;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _initialized = false;
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _initFromVacation(Vacation? v) {
    if (_initialized || v == null) return;
    _initialized = true;
    setState(() {
      _isActive = v.isActive;
      _startDate = v.startDate;
      _endDate = v.endDate;
      _reasonController.text = v.reason ?? '';
    });
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _save() async {
    final vacation = Vacation(
      uid: widget.uid,
      homeId: widget.homeId,
      isActive: _isActive,
      startDate: _startDate,
      endDate: _endDate,
      reason: _reasonController.text.trim().isEmpty
          ? null
          : _reasonController.text.trim(),
      createdAt: DateTime.now(),
    );
    await ref
        .read(vacationNotifierProvider.notifier)
        .save(widget.homeId, widget.uid, vacation);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = DateFormat.yMd();

    ref
        .watch(memberVacationProvider(homeId: widget.homeId, uid: widget.uid))
        .whenData(_initFromVacation);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.vacation_title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            key: const Key('vacation_toggle'),
            title: Text(l10n.vacation_toggle_label),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
          ),
          if (_isActive)
            Column(
              key: const Key('vacation_date_pickers'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(l10n.vacation_start_date),
                  subtitle: Text(_startDate != null ? fmt.format(_startDate!) : '—'),
                  onTap: () => _pickDate(true),
                ),
                ListTile(
                  leading: const Icon(Icons.event_available),
                  title: Text(l10n.vacation_end_date),
                  subtitle: Text(_endDate != null ? fmt.format(_endDate!) : '—'),
                  onTap: () => _pickDate(false),
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
            onPressed: _save,
            child: Text(l10n.vacation_save),
          ),
        ],
      ),
    );
  }
}
