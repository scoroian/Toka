// lib/features/history/presentation/widgets/rate_event_sheet.dart
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/skins/main_shell_v2.dart';

/// Bottom sheet para valorar un evento de tarea completada.
/// Muestra un Slider (1.0–10.0) y un campo de nota opcional.
class RateEventSheet extends StatefulWidget {
  const RateEventSheet({super.key, required this.onSubmit});

  final void Function(double rating, String? note) onSubmit;

  @override
  State<RateEventSheet> createState() => _RateEventSheetState();
}

class _RateEventSheetState extends State<RateEventSheet> {
  double _rating = 5.0;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mq = MediaQuery.of(context);
    const navBarExtra = MainShellV2.kNavBarHeight + MainShellV2.kNavBarBottom;
    final bottomPadding = mq.viewInsets.bottom + mq.viewPadding.bottom + navBarExtra;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: bottomPadding + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.history_rate_sheet_title,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Text(
            l10n.history_rate_score_label(_rating.toStringAsFixed(1)),
            key: const Key('rate_score_label'),
          ),
          Slider(
            key: const Key('rate_slider'),
            value: _rating,
            min: 1.0,
            max: 10.0,
            divisions: 18,
            label: _rating.toStringAsFixed(1),
            onChanged: (v) => setState(() => _rating = v),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('rate_note_field'),
            controller: _noteController,
            decoration: InputDecoration(
              hintText: l10n.history_rate_note_hint,
              border: const OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const Key('rate_submit_button'),
              onPressed: () {
                final note = _noteController.text.trim();
                widget.onSubmit(_rating, note.isEmpty ? null : note);
                Navigator.of(context).pop();
              },
              child: Text(l10n.history_rate_submit),
            ),
          ),
        ],
      ),
    );
  }
}
