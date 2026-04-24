import 'package:flutter/material.dart';

import '../../../../core/theme/skin_switcher.dart';
import 'futurista/history_screen_futurista.dart';
import 'history_screen_v2.dart';

/// Wrapper que elige entre la pantalla Historial v2 y la variante futurista
/// según el `SkinMode` persistido. Ambas variantes consumen el mismo
/// `historyViewModelProvider`.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) => SkinSwitch(
        v2: (_) => const HistoryScreenV2(),
        futurista: (_) => const HistoryScreenFuturista(),
      );
}
