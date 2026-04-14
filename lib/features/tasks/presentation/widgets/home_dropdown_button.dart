import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../application/today_view_model.dart';

/// Selector de hogar para el AppBar de TodayScreen.
class HomeDropdownButton extends StatelessWidget {
  const HomeDropdownButton({
    super.key,
    required this.homes,
    required this.onSelect,
    required this.onCreateHome,
    required this.onJoinHome,
  });

  final List<HomeDropdownItem> homes;
  final void Function(String homeId) onSelect;
  final VoidCallback onCreateHome;
  final VoidCallback onJoinHome;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selected = homes.where((h) => h.isSelected).firstOrNull;
    if (selected == null) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      key: const Key('home_dropdown'),
      tooltip: l10n.today_home_selector_my_homes,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              '${selected.emoji} ${selected.name}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
      itemBuilder: (context) => [
        ...homes.map(
          (h) => PopupMenuItem<String>(
            key: Key('home_item_${h.homeId}'),
            value: h.homeId,
            child: Row(
              children: [
                Expanded(child: Text('${h.emoji} ${h.name}')),
                if (h.hasPendingToday)
                  Container(
                    key: Key('pending_dot_${h.homeId}'),
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                if (h.isSelected) const Icon(Icons.check, size: 18),
              ],
            ),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          key: const Key('home_create_item'),
          value: '__create__',
          child: Row(children: [
            const Icon(Icons.add),
            const SizedBox(width: 8),
            Text(l10n.today_home_selector_create),
          ]),
        ),
        PopupMenuItem<String>(
          key: const Key('home_join_item'),
          value: '__join__',
          child: Row(children: [
            const Icon(Icons.qr_code_scanner),
            const SizedBox(width: 8),
            Text(l10n.today_home_selector_join),
          ]),
        ),
      ],
      onSelected: (value) {
        if (value == '__create__') {
          onCreateHome();
        } else if (value == '__join__') {
          onJoinHome();
        } else {
          onSelect(value);
        }
      },
    );
  }
}
