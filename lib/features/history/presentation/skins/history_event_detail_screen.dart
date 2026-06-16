import 'package:flutter/material.dart';
import 'package:toka/core/theme/skin_switcher.dart';

import 'history_event_detail_screen_v2.dart';

/// Wrapper "skin-aware" que renderiza la pantalla de detalle de evento de
/// Historial v2 (única skin activa) según el `SkinMode` persistido. Consume
/// los providers `historyEventDetailProvider`, `homeMembersProvider` y
/// `authProvider`.
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
      );
}
