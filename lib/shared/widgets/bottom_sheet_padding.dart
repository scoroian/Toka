import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Devuelve el padding inferior que un BottomSheet debe aplicar para que
/// sus acciones no queden tapadas por el teclado ni por la gesture area.
///
/// Los bottom sheets modales (`showModalBottomSheet`) ya flotan por encima
/// de la NavBar y del AdBanner gracias a su `rootNavigator`/barrier, por
/// lo que no necesitamos compensar esos huecos. Intentarlo generaba un
/// hueco vacío de ~130px al pie del sheet.
///
/// - [hasNavBar]: se conserva por compatibilidad de llamadas existentes;
///   no afecta al resultado.
///
/// Fórmula:
///   viewInsets.bottom (teclado)
/// + padding.bottom    (gesture area / safe area)
double bottomSheetSafeBottom(
  BuildContext context,
  WidgetRef ref, {
  required bool hasNavBar,
}) {
  final mq = MediaQuery.of(context);
  return mq.viewInsets.bottom + mq.padding.bottom;
}
