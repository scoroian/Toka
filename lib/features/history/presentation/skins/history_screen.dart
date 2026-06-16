import 'package:flutter/material.dart';

import '../../../../core/theme/skin_switcher.dart';
import 'history_screen_v2.dart';

/// Wrapper "skin-aware" que renderiza la pantalla Historial v2 (única skin
/// activa) según el `SkinMode` persistido, consumiendo el mismo
/// `historyViewModelProvider`.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) => SkinSwitch(
        v2: (_) => const HistoryScreenV2(),
      );
}
