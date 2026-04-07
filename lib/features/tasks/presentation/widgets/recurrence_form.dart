import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../application/recurrence_provider.dart';
import '../../application/task_form_provider.dart';
import '../../domain/recurrence_rule.dart';

class RecurrenceForm extends ConsumerStatefulWidget {
  const RecurrenceForm({super.key});

  @override
  ConsumerState<RecurrenceForm> createState() => _RecurrenceFormState();
}

class _RecurrenceFormState extends ConsumerState<RecurrenceForm> {
  String _selectedType = 'daily';
  int _every = 1;
  String _time = '09:00';
  String _startTime = '08:00';
  String? _endTime;
  List<String> _weekdays = ['MON'];
  int _dayOfMonth = 1;
  int _weekOfMonth = 1;
  String _weekday = 'MON';
  int _month = 1;
  String _timezone = 'Europe/Madrid';

  static const _types = [
    'hourly', 'daily', 'weekly',
    'monthlyFixed', 'monthlyNth',
    'yearlyFixed', 'yearlyNth',
  ];

  static const _commonTimezones = [
    'Europe/Madrid', 'Europe/Bucharest', 'Europe/London',
    'America/New_York', 'America/Chicago', 'America/Los_Angeles',
    'Asia/Tokyo', 'Asia/Shanghai', 'Australia/Sydney', 'UTC',
  ];

  @override
  void initState() {
    super.initState();
    final existing = ref.read(taskFormNotifierProvider).recurrenceRule;
    if (existing != null) _loadFromRule(existing);
  }

  void _loadFromRule(RecurrenceRule rule) {
    switch (rule) {
      case HourlyRule r:
        _selectedType = 'hourly';
        _every = r.every;
        _startTime = r.startTime;
        _endTime = r.endTime;
        _timezone = r.timezone;
      case DailyRule r:
        _selectedType = 'daily';
        _every = r.every;
        _time = r.time;
        _timezone = r.timezone;
      case WeeklyRule r:
        _selectedType = 'weekly';
        _weekdays = List.from(r.weekdays);
        _time = r.time;
        _timezone = r.timezone;
      case MonthlyFixedRule r:
        _selectedType = 'monthlyFixed';
        _dayOfMonth = r.day;
        _time = r.time;
        _timezone = r.timezone;
      case MonthlyNthRule r:
        _selectedType = 'monthlyNth';
        _weekOfMonth = r.weekOfMonth;
        _weekday = r.weekday;
        _time = r.time;
        _timezone = r.timezone;
      case YearlyFixedRule r:
        _selectedType = 'yearlyFixed';
        _month = r.month;
        _dayOfMonth = r.day;
        _time = r.time;
        _timezone = r.timezone;
      case YearlyNthRule r:
        _selectedType = 'yearlyNth';
        _month = r.month;
        _weekOfMonth = r.weekOfMonth;
        _weekday = r.weekday;
        _time = r.time;
        _timezone = r.timezone;
    }
  }

  RecurrenceRule _buildRule() {
    return switch (_selectedType) {
      'hourly' => RecurrenceRule.hourly(
          every: _every,
          startTime: _startTime,
          endTime: _endTime,
          timezone: _timezone),
      'weekly' => RecurrenceRule.weekly(
          weekdays: _weekdays, time: _time, timezone: _timezone),
      'monthlyFixed' => RecurrenceRule.monthlyFixed(
          day: _dayOfMonth, time: _time, timezone: _timezone),
      'monthlyNth' => RecurrenceRule.monthlyNth(
          weekOfMonth: _weekOfMonth,
          weekday: _weekday,
          time: _time,
          timezone: _timezone),
      'yearlyFixed' => RecurrenceRule.yearlyFixed(
          month: _month,
          day: _dayOfMonth,
          time: _time,
          timezone: _timezone),
      'yearlyNth' => RecurrenceRule.yearlyNth(
          month: _month,
          weekOfMonth: _weekOfMonth,
          weekday: _weekday,
          time: _time,
          timezone: _timezone),
      _ => RecurrenceRule.daily(
          every: _every, time: _time, timezone: _timezone),
    };
  }

  void _notifyChange() {
    ref.read(taskFormNotifierProvider.notifier).setRecurrenceRule(_buildRule());
  }

  String _typeLabel(String type, AppLocalizations l10n) => switch (type) {
        'hourly' => l10n.tasks_recurrence_hourly_label,
        'daily' => l10n.tasks_recurrence_daily_label,
        'weekly' => l10n.tasks_recurrence_weekly_label,
        'monthlyFixed' => l10n.tasks_recurrence_monthly_fixed_label,
        'monthlyNth' => l10n.tasks_recurrence_monthly_nth_label,
        'yearlyFixed' => l10n.tasks_recurrence_yearly_fixed_label,
        'yearlyNth' => l10n.tasks_recurrence_yearly_nth_label,
        _ => type,
      };

  String _weekdayLabel(String key, AppLocalizations l10n) => switch (key) {
        'MON' => l10n.weekday_mon,
        'TUE' => l10n.weekday_tue,
        'WED' => l10n.weekday_wed,
        'THU' => l10n.weekday_thu,
        'FRI' => l10n.weekday_fri,
        'SAT' => l10n.weekday_sat,
        'SUN' => l10n.weekday_sun,
        _ => key,
      };

  String _weekLabel(int n, AppLocalizations l10n) => switch (n) {
        1 => l10n.tasks_week_1st,
        2 => l10n.tasks_week_2nd,
        3 => l10n.tasks_week_3rd,
        _ => l10n.tasks_week_4th,
      };

  String _monthLabel(int m, AppLocalizations l10n) => switch (m) {
        1 => l10n.month_jan,
        2 => l10n.month_feb,
        3 => l10n.month_mar,
        4 => l10n.month_apr,
        5 => l10n.month_may,
        6 => l10n.month_jun,
        7 => l10n.month_jul,
        8 => l10n.month_aug,
        9 => l10n.month_sep,
        10 => l10n.month_oct,
        11 => l10n.month_nov,
        _ => l10n.month_dec,
      };

  Future<void> _pickTime(BuildContext context, String current,
      void Function(String) onPick) async {
    final parts = current.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
    );
    if (picked != null) {
      onPick(
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final upcoming = ref.watch(upcomingOccurrencesProvider(_buildRule()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedType,
          decoration:
              InputDecoration(label: Text(l10n.tasks_field_recurrence)),
          items: _types
              .map((t) => DropdownMenuItem(
                  value: t, child: Text(_typeLabel(t, l10n))))
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() => _selectedType = v);
            _notifyChange();
          },
        ),
        const SizedBox(height: 12),
        _buildSubForm(context, l10n),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _commonTimezones.contains(_timezone) ? _timezone : 'UTC',
          decoration:
              InputDecoration(label: Text(l10n.tasks_recurrence_timezone)),
          items: _commonTimezones
              .map((tz) => DropdownMenuItem(value: tz, child: Text(tz)))
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() => _timezone = v);
            _notifyChange();
          },
        ),
        if (upcoming.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(l10n.tasks_recurrence_upcoming,
              style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          ...upcoming.map((d) => Text(
                DateFormat.yMMMd(Localizations.localeOf(context).toString())
                    .add_Hm()
                    .format(d),
                style: Theme.of(context).textTheme.bodySmall,
              )),
        ],
      ],
    );
  }

  Widget _buildSubForm(BuildContext context, AppLocalizations l10n) {
    return switch (_selectedType) {
      'hourly' => _HourlySubForm(
          every: _every,
          startTime: _startTime,
          endTime: _endTime,
          onEveryChanged: (v) {
            setState(() => _every = v);
            _notifyChange();
          },
          onStartTimeChanged: (v) {
            setState(() => _startTime = v);
            _notifyChange();
          },
          onEndTimeChanged: (v) {
            setState(() => _endTime = v);
            _notifyChange();
          },
          l10n: l10n,
        ),
      'daily' => _DailySubForm(
          every: _every,
          time: _time,
          onEveryChanged: (v) {
            setState(() => _every = v);
            _notifyChange();
          },
          onTimeTap: () => _pickTime(context, _time, (v) {
                setState(() => _time = v);
                _notifyChange();
              }),
          l10n: l10n,
        ),
      'weekly' => _WeeklySubForm(
          weekdays: _weekdays,
          time: _time,
          weekdayLabel: (k) => _weekdayLabel(k, l10n),
          onWeekdaysChanged: (v) {
            setState(() => _weekdays = v);
            _notifyChange();
          },
          onTimeTap: () => _pickTime(context, _time, (v) {
                setState(() => _time = v);
                _notifyChange();
              }),
          l10n: l10n,
        ),
      'monthlyFixed' => _MonthlyFixedSubForm(
          day: _dayOfMonth,
          time: _time,
          onDayChanged: (v) {
            setState(() => _dayOfMonth = v);
            _notifyChange();
          },
          onTimeTap: () => _pickTime(context, _time, (v) {
                setState(() => _time = v);
                _notifyChange();
              }),
          l10n: l10n,
        ),
      'monthlyNth' => _MonthlyNthSubForm(
          weekOfMonth: _weekOfMonth,
          weekday: _weekday,
          time: _time,
          weekLabel: (n) => _weekLabel(n, l10n),
          weekdayLabel: (k) => _weekdayLabel(k, l10n),
          onWeekOfMonthChanged: (v) {
            setState(() => _weekOfMonth = v);
            _notifyChange();
          },
          onWeekdayChanged: (v) {
            setState(() => _weekday = v);
            _notifyChange();
          },
          onTimeTap: () => _pickTime(context, _time, (v) {
                setState(() => _time = v);
                _notifyChange();
              }),
          l10n: l10n,
        ),
      'yearlyFixed' => _YearlyFixedSubForm(
          month: _month,
          day: _dayOfMonth,
          time: _time,
          monthLabel: (m) => _monthLabel(m, l10n),
          onMonthChanged: (v) {
            setState(() => _month = v);
            _notifyChange();
          },
          onDayChanged: (v) {
            setState(() => _dayOfMonth = v);
            _notifyChange();
          },
          onTimeTap: () => _pickTime(context, _time, (v) {
                setState(() => _time = v);
                _notifyChange();
              }),
          l10n: l10n,
        ),
      'yearlyNth' => _YearlyNthSubForm(
          month: _month,
          weekOfMonth: _weekOfMonth,
          weekday: _weekday,
          time: _time,
          monthLabel: (m) => _monthLabel(m, l10n),
          weekLabel: (n) => _weekLabel(n, l10n),
          weekdayLabel: (k) => _weekdayLabel(k, l10n),
          onMonthChanged: (v) {
            setState(() => _month = v);
            _notifyChange();
          },
          onWeekOfMonthChanged: (v) {
            setState(() => _weekOfMonth = v);
            _notifyChange();
          },
          onWeekdayChanged: (v) {
            setState(() => _weekday = v);
            _notifyChange();
          },
          onTimeTap: () => _pickTime(context, _time, (v) {
                setState(() => _time = v);
                _notifyChange();
              }),
          l10n: l10n,
        ),
      _ => const SizedBox.shrink(),
    };
  }
}

// ── Sub-formularios ─────────────────────────────────────────────────────────

class _HourlySubForm extends StatelessWidget {
  const _HourlySubForm({
    required this.every,
    required this.startTime,
    required this.endTime,
    required this.onEveryChanged,
    required this.onStartTimeChanged,
    required this.onEndTimeChanged,
    required this.l10n,
  });
  final int every;
  final String startTime;
  final String? endTime;
  final void Function(int) onEveryChanged;
  final void Function(String) onStartTimeChanged;
  final void Function(String?) onEndTimeChanged;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        Text(l10n.tasks_recurrence_every),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: TextFormField(
            initialValue: every.toString(),
            keyboardType: TextInputType.number,
            onChanged: (v) => onEveryChanged(int.tryParse(v) ?? 1),
          ),
        ),
        const SizedBox(width: 8),
        Text(l10n.tasks_recurrence_hours),
      ]),
      const SizedBox(height: 8),
      ListTile(
        dense: true,
        leading: const Icon(Icons.access_time),
        title: Text(l10n.tasks_recurrence_start_time),
        trailing: Text(startTime),
        onTap: () async {
          final parts = startTime.split(':');
          final t = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(
                  hour: int.parse(parts[0]), minute: int.parse(parts[1])));
          if (t != null) {
            onStartTimeChanged(
                '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
          }
        },
      ),
      ListTile(
        dense: true,
        leading: const Icon(Icons.access_time_outlined),
        title: Text(l10n.tasks_recurrence_end_time),
        trailing: Text(endTime ?? '—'),
        onTap: () async {
          final current = endTime ?? '20:00';
          final parts = current.split(':');
          final t = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(
                  hour: int.parse(parts[0]), minute: int.parse(parts[1])));
          if (t != null) {
            onEndTimeChanged(
                '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
          }
        },
      ),
    ]);
  }
}

class _DailySubForm extends StatelessWidget {
  const _DailySubForm({
    required this.every,
    required this.time,
    required this.onEveryChanged,
    required this.onTimeTap,
    required this.l10n,
  });
  final int every;
  final String time;
  final void Function(int) onEveryChanged;
  final VoidCallback onTimeTap;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Column(children: [
        Row(children: [
          Text(l10n.tasks_recurrence_every),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: TextFormField(
              initialValue: every.toString(),
              keyboardType: TextInputType.number,
              onChanged: (v) => onEveryChanged(int.tryParse(v) ?? 1),
            ),
          ),
          const SizedBox(width: 8),
          Text(l10n.tasks_recurrence_days),
        ]),
        ListTile(
          dense: true,
          leading: const Icon(Icons.access_time),
          title: Text(l10n.tasks_recurrence_time),
          trailing: Text(time),
          onTap: onTimeTap,
        ),
      ]);
}

class _WeeklySubForm extends StatelessWidget {
  const _WeeklySubForm({
    required this.weekdays,
    required this.time,
    required this.weekdayLabel,
    required this.onWeekdaysChanged,
    required this.onTimeTap,
    required this.l10n,
  });
  final List<String> weekdays;
  final String time;
  final String Function(String) weekdayLabel;
  final void Function(List<String>) onWeekdaysChanged;
  final VoidCallback onTimeTap;
  final AppLocalizations l10n;

  static const _keys = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  @override
  Widget build(BuildContext context) => Column(children: [
        Wrap(
            spacing: 4,
            children: _keys.map((k) {
              final selected = weekdays.contains(k);
              return FilterChip(
                label: Text(weekdayLabel(k).substring(0, 2)),
                selected: selected,
                onSelected: (v) {
                  final updated = List<String>.from(weekdays);
                  if (v) {
                    updated.add(k);
                  } else {
                    updated.remove(k);
                  }
                  if (updated.isNotEmpty) onWeekdaysChanged(updated);
                },
              );
            }).toList()),
        ListTile(
          dense: true,
          leading: const Icon(Icons.access_time),
          title: Text(l10n.tasks_recurrence_time),
          trailing: Text(time),
          onTap: onTimeTap,
        ),
      ]);
}

class _MonthlyFixedSubForm extends StatelessWidget {
  const _MonthlyFixedSubForm({
    required this.day,
    required this.time,
    required this.onDayChanged,
    required this.onTimeTap,
    required this.l10n,
  });
  final int day;
  final String time;
  final void Function(int) onDayChanged;
  final VoidCallback onTimeTap;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Column(children: [
        DropdownButtonFormField<int>(
          value: day,
          decoration: InputDecoration(
              label: Text(l10n.tasks_recurrence_day_of_month)),
          items: List.generate(31,
              (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}'))),
          onChanged: (v) => onDayChanged(v ?? 1),
        ),
        ListTile(
          dense: true,
          leading: const Icon(Icons.access_time),
          title: Text(l10n.tasks_recurrence_time),
          trailing: Text(time),
          onTap: onTimeTap,
        ),
      ]);
}

class _MonthlyNthSubForm extends StatelessWidget {
  const _MonthlyNthSubForm({
    required this.weekOfMonth,
    required this.weekday,
    required this.time,
    required this.weekLabel,
    required this.weekdayLabel,
    required this.onWeekOfMonthChanged,
    required this.onWeekdayChanged,
    required this.onTimeTap,
    required this.l10n,
  });
  final int weekOfMonth;
  final String weekday;
  final String time;
  final String Function(int) weekLabel;
  final String Function(String) weekdayLabel;
  final void Function(int) onWeekOfMonthChanged;
  final void Function(String) onWeekdayChanged;
  final VoidCallback onTimeTap;
  final AppLocalizations l10n;

  static const _dayKeys = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  @override
  Widget build(BuildContext context) => Column(children: [
        DropdownButtonFormField<int>(
          value: weekOfMonth,
          decoration: InputDecoration(
              label: Text(l10n.tasks_recurrence_week_of_month)),
          items: [1, 2, 3, 4]
              .map((n) =>
                  DropdownMenuItem(value: n, child: Text(weekLabel(n))))
              .toList(),
          onChanged: (v) => onWeekOfMonthChanged(v ?? 1),
        ),
        DropdownButtonFormField<String>(
          value: weekday,
          decoration:
              InputDecoration(label: Text(l10n.tasks_recurrence_weekday)),
          items: _dayKeys
              .map((k) =>
                  DropdownMenuItem(value: k, child: Text(weekdayLabel(k))))
              .toList(),
          onChanged: (v) => onWeekdayChanged(v ?? 'MON'),
        ),
        ListTile(
          dense: true,
          leading: const Icon(Icons.access_time),
          title: Text(l10n.tasks_recurrence_time),
          trailing: Text(time),
          onTap: onTimeTap,
        ),
      ]);
}

class _YearlyFixedSubForm extends StatelessWidget {
  const _YearlyFixedSubForm({
    required this.month,
    required this.day,
    required this.time,
    required this.monthLabel,
    required this.onMonthChanged,
    required this.onDayChanged,
    required this.onTimeTap,
    required this.l10n,
  });
  final int month;
  final int day;
  final String time;
  final String Function(int) monthLabel;
  final void Function(int) onMonthChanged;
  final void Function(int) onDayChanged;
  final VoidCallback onTimeTap;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Column(children: [
        DropdownButtonFormField<int>(
          value: month,
          decoration:
              InputDecoration(label: Text(l10n.tasks_recurrence_month)),
          items: List.generate(
              12,
              (i) => DropdownMenuItem(
                  value: i + 1, child: Text(monthLabel(i + 1)))),
          onChanged: (v) => onMonthChanged(v ?? 1),
        ),
        DropdownButtonFormField<int>(
          value: day,
          decoration: InputDecoration(
              label: Text(l10n.tasks_recurrence_day_of_month)),
          items: List.generate(31,
              (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}'))),
          onChanged: (v) => onDayChanged(v ?? 1),
        ),
        ListTile(
          dense: true,
          leading: const Icon(Icons.access_time),
          title: Text(l10n.tasks_recurrence_time),
          trailing: Text(time),
          onTap: onTimeTap,
        ),
      ]);
}

class _YearlyNthSubForm extends StatelessWidget {
  const _YearlyNthSubForm({
    required this.month,
    required this.weekOfMonth,
    required this.weekday,
    required this.time,
    required this.monthLabel,
    required this.weekLabel,
    required this.weekdayLabel,
    required this.onMonthChanged,
    required this.onWeekOfMonthChanged,
    required this.onWeekdayChanged,
    required this.onTimeTap,
    required this.l10n,
  });
  final int month;
  final int weekOfMonth;
  final String weekday;
  final String time;
  final String Function(int) monthLabel;
  final String Function(int) weekLabel;
  final String Function(String) weekdayLabel;
  final void Function(int) onMonthChanged;
  final void Function(int) onWeekOfMonthChanged;
  final void Function(String) onWeekdayChanged;
  final VoidCallback onTimeTap;
  final AppLocalizations l10n;

  static const _dayKeys = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  @override
  Widget build(BuildContext context) => Column(children: [
        DropdownButtonFormField<int>(
          value: month,
          decoration:
              InputDecoration(label: Text(l10n.tasks_recurrence_month)),
          items: List.generate(
              12,
              (i) => DropdownMenuItem(
                  value: i + 1, child: Text(monthLabel(i + 1)))),
          onChanged: (v) => onMonthChanged(v ?? 1),
        ),
        DropdownButtonFormField<int>(
          value: weekOfMonth,
          decoration: InputDecoration(
              label: Text(l10n.tasks_recurrence_week_of_month)),
          items: [1, 2, 3, 4]
              .map((n) =>
                  DropdownMenuItem(value: n, child: Text(weekLabel(n))))
              .toList(),
          onChanged: (v) => onWeekOfMonthChanged(v ?? 1),
        ),
        DropdownButtonFormField<String>(
          value: weekday,
          decoration:
              InputDecoration(label: Text(l10n.tasks_recurrence_weekday)),
          items: _dayKeys
              .map((k) =>
                  DropdownMenuItem(value: k, child: Text(weekdayLabel(k))))
              .toList(),
          onChanged: (v) => onWeekdayChanged(v ?? 'MON'),
        ),
        ListTile(
          dense: true,
          leading: const Icon(Icons.access_time),
          title: Text(l10n.tasks_recurrence_time),
          trailing: Text(time),
          onTap: onTimeTap,
        ),
      ]);
}
