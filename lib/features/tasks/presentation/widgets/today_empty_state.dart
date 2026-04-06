import 'package:flutter/material.dart';

class TodayEmptyState extends StatelessWidget {
  const TodayEmptyState({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('No tasks'));
}
