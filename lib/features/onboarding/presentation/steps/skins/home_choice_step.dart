import 'package:flutter/material.dart';
import 'package:toka/core/theme/skin_switcher.dart';

import 'futurista/home_choice_step_futurista.dart';
import 'home_choice_step_v2.dart';

/// Wrapper que delega en la skin activa (`v2` o `futurista`) preservando
/// la firma del constructor para que el ViewModel/Coordinator que lo invoca
/// no necesite saber qué skin está activa.
class HomeChoiceStep extends StatelessWidget {
  const HomeChoiceStep({
    super.key,
    required this.isLoading,
    required this.error,
    required this.onCreateHome,
    required this.onJoinHome,
    required this.onPrev,
  });

  final bool isLoading;
  final String? error;
  final Future<void> Function(String name, String? emoji) onCreateHome;
  final Future<void> Function(String code) onJoinHome;
  final VoidCallback onPrev;

  @override
  Widget build(BuildContext context) => SkinSwitch(
        v2: (_) => HomeChoiceStepV2(
          isLoading: isLoading,
          error: error,
          onCreateHome: onCreateHome,
          onJoinHome: onJoinHome,
          onPrev: onPrev,
        ),
        futurista: (_) => HomeChoiceStepFuturista(
          isLoading: isLoading,
          error: error,
          onCreateHome: onCreateHome,
          onJoinHome: onJoinHome,
          onPrev: onPrev,
        ),
      );
}
