import 'package:flutter/material.dart';

/// Devuelve el widget visual apropiado para una tarea.
/// [kind] es 'emoji' o 'icon'.
/// [value] es el emoji string o el codePoint como string.
/// [size] controla el tamaño.
Widget taskVisualWidget(String kind, String value, {double size = 22}) {
  if (kind == 'icon' && value.isNotEmpty) {
    final cp = int.tryParse(value);
    if (cp != null) {
      return Icon(
        IconData(cp, fontFamily: 'MaterialIcons'),
        size: size,
      );
    }
  }
  // Fallback: emoji o valor desconocido
  return Text(
    value.isNotEmpty ? value : '📋',
    style: TextStyle(fontSize: size * 0.9),
  );
}
