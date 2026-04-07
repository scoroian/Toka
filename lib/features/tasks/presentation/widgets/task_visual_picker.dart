import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class TaskVisualPicker extends StatefulWidget {
  const TaskVisualPicker({
    super.key,
    required this.selectedKind,
    required this.selectedValue,
    required this.onChanged,
  });

  final String selectedKind;
  final String selectedValue;
  final void Function(String kind, String value) onChanged;

  @override
  State<TaskVisualPicker> createState() => _TaskVisualPickerState();
}

class _TaskVisualPickerState extends State<TaskVisualPicker>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _emojis = [
    '🏠', '🍽️', '🧹', '🧺', '🛒', '🌿', '🐾', '🚗',
    '💰', '🔧', '📦', '🗑️', '🛁', '🪴', '🧴', '🍳',
    '🥗', '🧃', '☕', '🍰', '🛋️', '🪟', '🚿', '🪣',
  ];

  static const _iconData = [
    Icons.home,
    Icons.kitchen,
    Icons.local_laundry_service,
    Icons.cleaning_services,
    Icons.shopping_cart,
    Icons.directions_car,
    Icons.pets,
    Icons.yard,
    Icons.build,
    Icons.recycling,
    Icons.bathtub,
    Icons.wb_sunny,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.selectedKind == 'icon' ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.tasks_field_visual,
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: widget.selectedKind == 'emoji'
                  ? Text(widget.selectedValue,
                      style: const TextStyle(fontSize: 32))
                  : Icon(Icons.task_alt,
                      size: 36,
                      color: Theme.of(context).colorScheme.onPrimaryContainer),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Emoji'), Tab(text: 'Icono')],
        ),
        SizedBox(
          height: 160,
          child: TabBarView(
            controller: _tabController,
            children: [
              GridView.count(
                crossAxisCount: 6,
                padding: const EdgeInsets.all(8),
                children: _emojis
                    .map((e) => GestureDetector(
                          onTap: () => widget.onChanged('emoji', e),
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: widget.selectedKind == 'emoji' &&
                                      widget.selectedValue == e
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(e,
                                  style: const TextStyle(fontSize: 22)),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              GridView.count(
                crossAxisCount: 6,
                padding: const EdgeInsets.all(8),
                children: _iconData
                    .map((icon) => GestureDetector(
                          onTap: () => widget.onChanged(
                              'icon', icon.codePoint.toString()),
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: widget.selectedKind == 'icon' &&
                                      widget.selectedValue ==
                                          icon.codePoint.toString()
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(icon, size: 22),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
