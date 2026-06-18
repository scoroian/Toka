import 'package:flutter/material.dart';

/// Avatar circular del hogar: muestra la foto (`photoUrl`) si existe, o la
/// inicial del nombre como fallback. Misma semántica que el avatar grande de
/// Ajustes del hogar (`home_settings_screen_v2.dart`), extraída a un widget
/// reutilizable para la cabecera de Hoy, el selector de hogares y la lista de
/// "Mis hogares".
class HomeAvatar extends StatelessWidget {
  const HomeAvatar({
    super.key,
    required this.photoUrl,
    required this.name,
    this.radius = 16,
  });

  /// URL de la foto del hogar. `null` → se pinta la inicial.
  final String? photoUrl;

  /// Nombre del hogar; se usa su primera letra como inicial de fallback.
  final String name;

  /// Radio del círculo. La cabecera usa uno pequeño; las tiles uno mayor.
  final double radius;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
      child: hasPhoto
          ? null
          : Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(fontSize: radius * 0.9),
            ),
    );
  }
}
