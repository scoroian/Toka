import 'package:flutter/material.dart';

import '../../../../../core/theme/skin_switcher.dart';
import 'futurista/welcome_step_futurista.dart';
import 'welcome_step_v2.dart';

/// Wrapper que selecciona la variante de [WelcomeStep] según la skin activa.
class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => SkinSwitch(
        v2: (_) => WelcomeStepV2(onStart: onStart),
        futurista: (_) => WelcomeStepFuturista(onStart: onStart),
      );
}
