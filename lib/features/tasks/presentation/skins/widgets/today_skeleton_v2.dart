// lib/features/tasks/presentation/skins/widgets/today_skeleton_v2.dart
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors_v2.dart';

class TodaySkeletonV2 extends StatefulWidget {
  const TodaySkeletonV2({super.key});
  @override
  State<TodaySkeletonV2> createState() => _TodaySkeletonV2State();
}

class _TodaySkeletonV2State extends State<TodaySkeletonV2>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _shimmer = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base   = isDark ? AppColorsV2.surfaceDark : AppColorsV2.surfaceLight;
    final shine  = isDark
        ? AppColorsV2.surfaceVariantDark
        : AppColorsV2.surfaceVariantLight;

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (ctx, _) {
        final shadeColor = Color.lerp(base, shine, _shimmer.value)!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              Expanded(child: _Block(height: 60, color: shadeColor)),
              const SizedBox(width: 8),
              Expanded(child: _Block(height: 60, color: shadeColor)),
            ]),
            const SizedBox(height: 16),
            _Block(height: 12, width: 80, color: shadeColor),
            const SizedBox(height: 10),
            for (var i = 0; i < 4; i++) ...[
              _Block(height: 72, color: shadeColor),
              const SizedBox(height: 6),
            ],
          ],
        );
      },
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.height, required this.color, this.width});
  final double height;
  final Color color;
  final double? width;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12),
    ),
  );
}
