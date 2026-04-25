import 'package:flutter/material.dart';
import 'package:toka/core/theme/skin_switcher.dart';

import 'futurista/history_event_detail_screen_futurista.dart';
import 'history_event_detail_screen_v2.dart';

/// Wrapper que elige entre la pantalla de detalle de evento de Historial v2 y
/// la variante futurista según el `SkinMode` persistido. Ambas variantes
/// consumen los mismos providers (`historyEventDetailProvider`,
/// `homeMembersProvider`, `authProvider`).
class HistoryEventDetailScreen extends StatelessWidget {
  const HistoryEventDetailScreen({
    super.key,
    required this.homeId,
    required this.eventId,
  });

  final String homeId;
  final String eventId;

  @override
  Widget build(BuildContext context) => SkinSwitch(
        v2: (_) => HistoryEventDetailScreenV2(
          homeId: homeId,
          eventId: eventId,
        ),
        futurista: (_) => HistoryEventDetailScreenFuturista(
          homeId: homeId,
          eventId: eventId,
        ),
      );
}
