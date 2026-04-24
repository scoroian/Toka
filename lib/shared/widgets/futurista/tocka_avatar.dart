import 'package:flutter/material.dart';

/// Avatar circular con gradient lineal 135° y iniciales. Si `ring` != null,
/// dibuja un border sólido exterior.
class TockaAvatar extends StatelessWidget {
  const TockaAvatar({
    super.key,
    required this.name,
    required this.color,
    this.size = 28,
    this.ring,
  });

  final String name;
  final Color color;
  final double size;
  final Color? ring;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return letters;
  }

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.67)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );

    if (ring == null) return avatar;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring!, width: 2),
      ),
      child: avatar,
    );
  }
}
