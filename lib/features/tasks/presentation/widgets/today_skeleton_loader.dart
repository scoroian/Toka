import 'package:flutter/material.dart';

class TodaySkeletonLoader extends StatelessWidget {
  const TodaySkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}
