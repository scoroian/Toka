import 'package:flutter/material.dart';

import '../../application/history_view_model.dart';
import 'rate_event_sheet.dart';

/// Abre el bottom sheet de valoración para un evento del historial.
/// Función top-level compartida por la skin v2 y la futurista — el sheet en
/// sí (`RateEventSheet`) es el mismo en ambas skins.
Future<void> showRateSheet(
  BuildContext ctx,
  HistoryViewModel vm,
  TaskEventItem item,
) {
  return showModalBottomSheet<void>(
    context: ctx,
    isScrollControlled: true,
    builder: (_) => RateEventSheet(
      onSubmit: (rating, note) =>
          vm.rateEvent(item.raw.id, rating, note: note),
    ),
  );
}
