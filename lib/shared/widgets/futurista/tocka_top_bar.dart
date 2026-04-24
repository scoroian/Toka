import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tocka_avatar.dart';

typedef MemberAvatar = ({String name, Color color});

/// TopBar futurista: botón de home + stack de avatars + slot trailing.
class TockaTopBar extends ConsumerWidget {
  const TockaTopBar({
    super.key,
    required this.homeName,
    required this.members,
    this.onHomeTap,
    this.trailing,
  });

  final String homeName;
  final List<MemberAvatar> members;
  final VoidCallback? onHomeTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 10,
        16,
        10,
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onHomeTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.55),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      homeName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 14,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          if (members.isNotEmpty)
            SizedBox(
              height: 26,
              width: members.take(3).length * 18.0 + 8,
              child: Stack(
                children: [
                  for (int i = 0; i < members.take(3).length; i++)
                    Positioned(
                      left: i * 18.0,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: cs.surface, width: 2),
                        ),
                        child: TockaAvatar(
                          name: members[i].name,
                          color: members[i].color,
                          size: 26,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}
