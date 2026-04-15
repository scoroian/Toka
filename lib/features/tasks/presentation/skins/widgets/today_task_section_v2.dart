// lib/features/tasks/presentation/skins/widgets/today_task_section_v2.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors_v2.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/home_dashboard.dart';
import '../../../domain/recurrence_order.dart';
import '../../widgets/today_task_card_done.dart';
import 'today_task_card_todo_v2.dart';

class TodayTaskSectionV2 extends StatelessWidget {
  const TodayTaskSectionV2({
    super.key,
    required this.recurrenceType,
    required this.todos,
    required this.dones,
    required this.currentUid,
    this.onDone,
    this.onPass,
  });

  final String recurrenceType;
  final List<TaskPreview> todos;
  final List<DoneTaskPreview> dones;
  final String? currentUid;
  final void Function(TaskPreview)? onDone;
  final void Function(TaskPreview)? onPass;

  @override
  Widget build(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final titleColor  = isDark ? AppColorsV2.textSecondaryDark : const Color(0xFF999999);
    final divColor    = isDark ? AppColorsV2.borderDark : AppColorsV2.borderLight;
    final title       = RecurrenceOrder.localizedTitle(context, recurrenceType);
    final l10n        = AppLocalizations.of(context);

    return SliverMainAxisGroup(slivers: [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: Row(children: [
            Text(title,
              key: Key('section_title_$recurrenceType'),
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 10, fontWeight: FontWeight.w800,
                  letterSpacing: 0.15, color: titleColor),
            ),
            const SizedBox(width: 8),
            Expanded(child: Divider(color: divColor, height: 1)),
          ]),
        ),
      ),
      if (todos.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(l10n.today_section_todo,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 10, fontWeight: FontWeight.w600, color: titleColor)),
          ),
        ),
        SliverList.builder(
          itemCount: todos.length,
          itemBuilder: (ctx, i) => TodayTaskCardTodoV2(
            task: todos[i],
            currentUid: currentUid,
            onDone: onDone != null ? () => onDone!(todos[i]) : null,
            onPass: onPass != null ? () => onPass!(todos[i]) : null,
          ),
        ),
      ],
      if (dones.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(l10n.today_section_done,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 10, fontWeight: FontWeight.w600, color: titleColor)),
          ),
        ),
        SliverList.builder(
          itemCount: dones.length,
          itemBuilder: (ctx, i) => TodayTaskCardDone(task: dones[i]),
        ),
      ],
    ]);
  }
}
