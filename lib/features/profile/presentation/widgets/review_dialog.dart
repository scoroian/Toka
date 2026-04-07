// lib/features/profile/presentation/widgets/review_dialog.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class ReviewDialog extends StatefulWidget {
  const ReviewDialog({
    super.key,
    required this.homeId,
    required this.taskEventId,
    required this.taskTitle,
    required this.performerName,
    required this.isPremium,
    required this.currentUid,
    required this.performerUid,
    required this.onSubmitted,
  });

  final String homeId;
  final String taskEventId;
  final String taskTitle;
  final String performerName;
  final bool isPremium;
  final String currentUid;
  final String performerUid;
  final VoidCallback onSubmitted;

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  double _score = 5;
  final _noteController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  bool get _isSelf => widget.currentUid == widget.performerUid;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await FirebaseFunctions.instance.httpsCallable('submitReview').call({
        'homeId': widget.homeId,
        'taskEventId': widget.taskEventId,
        'score': _score.round(),
        if (_noteController.text.trim().isNotEmpty)
          'note': _noteController.text.trim(),
      });
      widget.onSubmitted();
      if (mounted) Navigator.of(context).pop();
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? l10n.review_submit_error)),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (!widget.isPremium) {
      return AlertDialog(
        title: Text(l10n.review_dialog_title),
        content: Container(
          key: const Key('premium_gate_overlay'),
          padding: const EdgeInsets.all(16),
          child: Text(l10n.review_premium_required),
        ),
      );
    }

    if (_isSelf) {
      return AlertDialog(
        title: Text(l10n.review_dialog_title),
        content: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.review_own_task,
            key: const Key('self_review_message'),
          ),
        ),
      );
    }

    return AlertDialog(
      title: Text(l10n.review_dialog_title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.review_score_label}: ${_score.round()}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              key: const Key('review_slider'),
              min: 1,
              max: 10,
              divisions: 9,
              value: _score,
              label: _score.round().toString(),
              onChanged: (v) => setState(() => _score = v),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLength: 300,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.review_note_label,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('btn_submit_review'),
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.review_submit),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
