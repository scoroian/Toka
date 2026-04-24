import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../futurista/tocka_tab_bar.dart';

/// Shell futurista con TockaTabBar floating. Mismas 5 rutas que MainShellV2.
class MainShellFuturista extends ConsumerWidget {
  const MainShellFuturista({super.key, required this.child});
  final Widget child;

  static const _routes = [
    AppRoutes.home,
    AppRoutes.history,
    AppRoutes.members,
    AppRoutes.tasks,
    AppRoutes.settings,
  ];

  int _indexFromRoute(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    for (var i = 0; i < _routes.length; i++) {
      if (loc.startsWith(_routes[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final items = [
      TockaTabBarItem(icon: Icons.home_outlined, label: l10n.today_screen_title),
      TockaTabBarItem(icon: Icons.history, label: l10n.history_title),
      TockaTabBarItem(icon: Icons.group_outlined, label: l10n.members_title),
      TockaTabBarItem(icon: Icons.check_circle_outline, label: l10n.tasks_title),
      TockaTabBarItem(icon: Icons.settings_outlined, label: l10n.settings_title),
    ];

    return Scaffold(
      body: Stack(
        children: [
          child,
          Positioned(
            left: 10,
            right: 10,
            bottom: MediaQuery.of(context).padding.bottom + 12,
            child: TockaTabBar(
              activeIndex: _indexFromRoute(context),
              items: items,
              onTap: (i) => context.go(_routes[i]),
            ),
          ),
        ],
      ),
    );
  }
}
