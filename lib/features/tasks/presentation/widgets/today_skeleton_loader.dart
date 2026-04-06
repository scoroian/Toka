import 'package:flutter/material.dart';

class TodaySkeletonLoader extends StatefulWidget {
  const TodaySkeletonLoader({super.key});

  @override
  State<TodaySkeletonLoader> createState() => _TodaySkeletonLoaderState();
}

class _TodaySkeletonLoaderState extends State<TodaySkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 0.7).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, _) => Opacity(
        opacity: _opacity.value,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SkeletonBox(height: 80, borderRadius: 12),
              const SizedBox(height: 16),
              for (int i = 0; i < 3; i++) ...[
                const _SkeletonBox(height: 20, width: 100),
                const SizedBox(height: 8),
                const _SkeletonBox(height: 72, borderRadius: 12),
                const SizedBox(height: 8),
                const _SkeletonBox(height: 72, borderRadius: 12),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const _SkeletonBox({
    required this.height,
    this.width,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
