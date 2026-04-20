// lib/features/tasks/presentation/skins/widgets/today_task_card_todo_v2.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors_v2.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/home_dashboard.dart';
import '../../../presentation/utils/task_visual_utils.dart';
import '../../../../profile/application/profile_provider.dart';

class TodayTaskCardTodoV2 extends ConsumerStatefulWidget {
  const TodayTaskCardTodoV2({
    super.key,
    required this.task,
    required this.currentUid,
    this.onDone,
    this.onPass,
    this.now,
  });

  final TaskPreview task;
  final String? currentUid;
  final VoidCallback? onDone;
  final VoidCallback? onPass;
  final DateTime? now;

  @override
  ConsumerState<TodayTaskCardTodoV2> createState() => _TodayTaskCardTodoV2State();
}

class _TodayTaskCardTodoV2State extends ConsumerState<TodayTaskCardTodoV2>
    with SingleTickerProviderStateMixin {
  late final AnimationController _checkCtrl;
  late final Animation<double> _checkAnim;
  late final ConfettiController _confettiCtrl;
  bool _animating = false;

  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _checkAnim = CurvedAnimation(parent: _checkCtrl, curve: Curves.easeOutBack);
    _confettiCtrl =
        ConfettiController(duration: const Duration(milliseconds: 800));
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  /// Determina si la tarea puede completarse ahora según su tipo de recurrencia.
  /// - hourly: vence en la hora actual
  /// - daily: vence hoy
  /// - weekly: vence esta semana
  /// - monthly: vence este mes
  /// - yearly: vence este año
  bool _isActionable() {
    final now = widget.now ?? DateTime.now();
    final due = widget.task.nextDueAt;

    // Tareas vencidas siempre son accionables
    if (due.isBefore(now)) return true;

    switch (widget.task.recurrenceType) {
      case 'hourly':
        final hourEnd = DateTime(now.year, now.month, now.day, now.hour + 1);
        return due.isBefore(hourEnd);
      case 'daily':
        final dayEnd = DateTime(now.year, now.month, now.day + 1);
        return due.isBefore(dayEnd);
      case 'weekly':
        final daysFromMonday = now.weekday - 1;
        final weekStart = DateTime(now.year, now.month, now.day - daysFromMonday);
        final weekEnd = weekStart.add(const Duration(days: 7));
        return due.isBefore(weekEnd);
      case 'monthly':
        final monthEnd = DateTime(now.year, now.month + 1, 1);
        return due.isBefore(monthEnd);
      case 'yearly':
        final yearEnd = DateTime(now.year + 1, 1, 1);
        return due.isBefore(yearEnd);
      default:
        final dayEnd = DateTime(now.year, now.month, now.day + 1);
        return due.isBefore(dayEnd);
    }
  }

  /// Formatea la fecha de vencimiento para el mensaje informativo según el tipo de recurrencia.
  String _formatDueForMessage(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final due = widget.task.nextDueAt.toLocal();
    switch (widget.task.recurrenceType) {
      case 'hourly':
        return DateFormat('HH:mm', locale).format(due);
      case 'daily':
        return DateFormat('EEE d MMM · HH:mm', locale).format(due);
      case 'weekly':
        return DateFormat('EEE d MMM', locale).format(due);
      case 'monthly':
        return DateFormat('d MMMM', locale).format(due);
      case 'yearly':
        return DateFormat('MMMM yyyy', locale).format(due);
      default:
        return DateFormat('EEE d MMM · HH:mm', locale).format(due);
    }
  }

  Future<void> _handleDone() async {
    if (_animating) return;
    setState(() => _animating = true);
    _confettiCtrl.play();
    await _checkCtrl.forward();
    widget.onDone?.call();
    if (mounted) setState(() => _animating = false);
    _checkCtrl.reset();
  }

  void _handleDoneNotReady(BuildContext context, AppLocalizations l10n) {
    final dateStr = _formatDueForMessage(context);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(l10n.today_hecho_not_yet(dateStr)),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ));
  }

  String _dueDateLabel(BuildContext context, AppLocalizations l10n) {
    if (widget.task.isOverdue) return l10n.today_overdue;
    final now      = widget.now ?? DateTime.now();
    final due      = widget.task.nextDueAt.toLocal();
    final timeStr  = DateFormat('HH:mm').format(due);
    final isToday  = due.year == now.year && due.month == now.month && due.day == now.day;
    if (isToday) return l10n.today_due_today(timeStr);
    final weekday = DateFormat('EEE', Localizations.localeOf(context).toString()).format(due);
    return l10n.today_due_weekday(weekday, timeStr);
  }

  @override
  Widget build(BuildContext context) {
    final l10n      = AppLocalizations.of(context);
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final isOwn     = widget.task.currentAssigneeUid == widget.currentUid;
    final isOverdue = widget.task.isOverdue;
    final actionable = _isActionable();

    // resolve name/photo
    String? name  = widget.task.currentAssigneeName;
    String? photo = widget.task.currentAssigneePhoto;
    final uid = widget.task.currentAssigneeUid;
    if (uid != null && (name == null || name.isEmpty || photo == null)) {
      final profile = ref.watch(userProfileProvider(uid)).valueOrNull;
      if (profile != null) {
        if (name == null || name.isEmpty) name = profile.nickname;
        photo ??= profile.photoUrl;
      }
    }

    final bg = isDark ? AppColorsV2.surfaceDark    : AppColorsV2.surfaceLight;
    final bd = isDark ? AppColorsV2.borderDark      : AppColorsV2.borderLight;
    final leftBorderColor = isOwn ? AppColorsV2.primary : bd;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border(left: BorderSide(color: leftBorderColor, width: 3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                blurRadius: isDark ? 12 : 6,
                offset: const Offset(0, 1),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                _AvatarV2(name: name, photoUrl: photo, isOwn: isOwn),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    taskVisualWidget(widget.task.visualKind,
                        widget.task.visualValue,
                        size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(widget.task.title,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: isDark ? AppColorsV2.textPrimaryDark : AppColorsV2.textPrimaryLight),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                  if (name != null && name.isNotEmpty)
                    Text(name,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 10, fontWeight: FontWeight.w600,
                          color: isDark ? AppColorsV2.textSecondaryDark : AppColorsV2.textSecondaryLight),
                    ),
                ])),
                const SizedBox(width: 8),
                _DueChipV2(label: _dueDateLabel(context, l10n), isOverdue: isOverdue, isDark: isDark),
              ]),
              if (isOwn) ...[
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _DoneButtonV2(
                    key: const Key('btn_done'),
                    animating: _animating,
                    checkAnim: _checkAnim,
                    label: l10n.today_btn_done,
                    isDark: isDark,
                    isActive: actionable,
                    onTap: actionable
                        ? _handleDone
                        : () => _handleDoneNotReady(context, l10n),
                  )),
                  const SizedBox(width: 6),
                  Expanded(child: _PassButtonV2(
                    key: const Key('btn_pass'),
                    label: l10n.today_btn_pass,
                    isDark: isDark,
                    onTap: widget.onPass,
                  )),
                ]),
              ],
            ]),
          ),
        ),
        Positioned(
          top: 0, left: 0, right: 0,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiCtrl,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 20,
              maxBlastForce: 12,
              minBlastForce: 5,
              gravity: 0.3,
              colors: const [
                AppColorsV2.primary,
                Color(0xFF81C99C),
                Colors.white,
              ],
              shouldLoop: false,
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarV2 extends StatelessWidget {
  const _AvatarV2({this.name, this.photoUrl, required this.isOwn});
  final String? name, photoUrl;
  final bool isOwn;

  String get _initials {
    if (name == null || name!.isEmpty) return '?';
    final parts = name!.trim().split(' ');
    return parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name![0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bg = isOwn ? AppColorsV2.primary : const Color(0xFFE8E8E4);
    final fg = isOwn ? Colors.white : Colors.grey;
    if (photoUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: photoUrl!,
          width: 30, height: 30, fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: 30, height: 30,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Center(child: Text(_initials,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: fg))),
    );
  }
}

class _DueChipV2 extends StatelessWidget {
  const _DueChipV2({required this.label, required this.isOverdue, required this.isDark});
  final String label;
  final bool isOverdue, isDark;

  @override
  Widget build(BuildContext context) {
    final bg = isOverdue
        ? (isDark ? const Color(0x26EF4444) : const Color(0x1AEF4444))
        : (isDark ? AppColorsV2.surfaceVariantDark : AppColorsV2.surfaceVariantLight);
    final fg = isOverdue
        ? (isDark ? AppColorsV2.errorDark : AppColorsV2.errorLight)
        : (isDark ? AppColorsV2.textSecondaryDark : AppColorsV2.textSecondaryLight);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class _DoneButtonV2 extends StatelessWidget {
  const _DoneButtonV2({
    super.key,
    required this.animating,
    required this.checkAnim,
    required this.label,
    required this.isDark,
    required this.isActive,
    required this.onTap,
  });
  final bool animating;
  final Animation<double> checkAnim;
  final String label;
  final bool isDark;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Activo: fondo oscuro (negro/blanco). Inactivo: gris muted.
    final bg = isActive
        ? (isDark ? AppColorsV2.textPrimaryDark : AppColorsV2.textPrimaryLight)
        : (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0));
    final fg = isActive
        ? (isDark ? AppColorsV2.backgroundDark : AppColorsV2.onPrimary)
        : (isDark ? const Color(0xFF777777) : const Color(0xFFAAAAAA));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Center(
          child: animating && isActive
              ? ScaleTransition(
                  scale: checkAnim,
                  child: Icon(Icons.check_circle, color: fg, size: 18),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isActive)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(Icons.lock_clock, size: 12, color: fg),
                      ),
                    Text('✓ $label',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, fontWeight: FontWeight.w800, color: fg)),
                  ],
                ),
        ),
      ),
    );
  }
}

class _PassButtonV2 extends StatelessWidget {
  const _PassButtonV2({super.key, required this.label, required this.isDark,
      required this.onTap});
  final String label;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bd    = isDark ? AppColorsV2.borderDark  : AppColorsV2.borderLight;
    final color = isDark ? AppColorsV2.textSecondaryDark : AppColorsV2.textSecondaryLight;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: bd, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text('↻ $label',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ),
      ),
    );
  }
}
