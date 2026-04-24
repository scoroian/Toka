import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/skin_switcher.dart';
import 'main_shell_futurista.dart';
import 'main_shell_v2.dart';

/// Elige el shell según skin activo. Ambos shells envuelven el mismo `child`.
class MainShellRoot extends ConsumerWidget {
  const MainShellRoot({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkinSwitch(
      v2: (_) => MainShellV2(child: child),
      futurista: (_) => MainShellFuturista(child: child),
    );
  }
}
