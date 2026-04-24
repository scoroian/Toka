import 'package:flutter/material.dart';

/// Header de bloque con label mono uppercase + regla gradient + count opcional.
class BlockHeader extends StatelessWidget {
  const BlockHeader({
    super.key,
    required this.label,
    this.count,
  });

  final String label;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.42);

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 18, 0, 10),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: muted,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.onSurface.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 10),
            Text(
              count!.toString().padLeft(2, '0'),
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 10.5,
                color: muted,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
