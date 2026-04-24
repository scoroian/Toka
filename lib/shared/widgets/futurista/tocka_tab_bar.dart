import 'dart:ui';
import 'package:flutter/material.dart';

class TockaTabBarItem {
  const TockaTabBarItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

/// TabBar floating futurista con blur + active indicator con glow.
class TockaTabBar extends StatelessWidget {
  const TockaTabBar({
    super.key,
    required this.activeIndex,
    required this.items,
    required this.onTap,
  });

  final int activeIndex;
  final List<TockaTabBarItem> items;
  final void Function(int index) onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: cs.onSurface.withValues(alpha: 0.16),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 40,
                offset: const Offset(0, 20),
                spreadRadius: -10,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (int i = 0; i < items.length; i++)
                Expanded(
                  child: _TabItem(
                    item: items[i],
                    active: i == activeIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.item, required this.active, required this.onTap});
  final TockaTabBarItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = active ? cs.primary : cs.onSurface.withValues(alpha: 0.42);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (active)
              Container(
                width: 28,
                height: 3,
                margin: const EdgeInsets.only(bottom: 3),
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.55),
                      blurRadius: 12,
                    ),
                  ],
                ),
              )
            else
              const SizedBox(height: 6),
            Icon(item.icon, size: 20, color: color),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
