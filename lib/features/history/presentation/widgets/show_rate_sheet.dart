import 'package:flutter/material.dart';

import '../../application/history_view_model.dart';
import 'rate_event_sheet.dart';

/// Abre el bottom sheet de valoración para un evento del historial.
/// Función top-level reutilizable por cualquier skin — el sheet en sí
/// (`RateEventSheet`) es independiente de la skin.
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
