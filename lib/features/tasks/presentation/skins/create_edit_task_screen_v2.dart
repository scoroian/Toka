// lib/features/tasks/presentation/skins/create_edit_task_screen_v2.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors_v2.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/create_edit_task_view_model.dart';

/// Skin V2 de la pantalla crear/editar tarea.
/// Delega toda la lógica al ViewModel abstracto; solo cambia la presentación.
class CreateEditTaskScreenV2 extends ConsumerWidget {
  const CreateEditTaskScreenV2({super.key, this.editTaskId});
  final String? editTaskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CreateEditTaskViewModel vm =
        ref.watch(createEditTaskViewModelProvider(editTaskId));
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg =
        isDark ? AppColorsV2.backgroundDark : AppColorsV2.backgroundLight;

    // The CreateEditTaskViewModel exposes formState and other sync fields
    // (no AsyncValue wrapper) — it uses a Notifier that returns synchronously.
    final titleCtrl =
        TextEditingController(text: vm.formState.title);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text(
          vm.isEditing ? l10n.tasks_edit_title : l10n.tasks_create_title,
          style:
              GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900),
        ),
        actions: [
          TextButton(
            onPressed: () async => vm.save(),
            child: Text(
              l10n.save,
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  color: AppColorsV2.primary),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          TextField(
            key: const Key('task_title_field'),
            controller: titleCtrl,
            onChanged: vm.setTitle,
            style:
                GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              labelText: l10n.tasks_field_title,
              hintText: l10n.tasks_field_title_hint,
              labelStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          _SectionLabel(label: l10n.tasks_field_recurrence, isDark: isDark),
          _FormPlaceholderNote(
            text: 'RecurrenceForm, AssignmentForm, TaskVisualPicker\n'
                '— reutilizar los widgets de la skin material.\n'
                'Heredan automáticamente AppThemeV2 vía Theme.of(context).',
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.isDark});
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 6),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.15,
              color: isDark
                  ? AppColorsV2.textSecondaryDark
                  : AppColorsV2.textSecondaryLight),
        ),
      );
}

class _FormPlaceholderNote extends StatelessWidget {
  const _FormPlaceholderNote({required this.text, required this.isDark});
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColorsV2.surfaceDark : AppColorsV2.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark ? AppColorsV2.borderDark : AppColorsV2.borderLight),
        ),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: isDark
                  ? AppColorsV2.textSecondaryDark
                  : AppColorsV2.textSecondaryLight),
        ),
      );
}
