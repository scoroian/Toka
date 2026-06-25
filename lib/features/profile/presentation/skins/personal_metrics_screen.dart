import 'package:flutter/material.dart';

import '../../../../core/theme/skin_switcher.dart';
import 'personal_metrics_screen_v2.dart';

/// Wrapper skin-aware de la pantalla de métricas personales.
class PersonalMetricsScreen extends StatelessWidget {
  const PersonalMetricsScreen({super.key});

  @override
  Widget build(BuildContext context) => SkinSwitch(
        v2: (_) => const PersonalMetricsScreenV2(),
      );
}
