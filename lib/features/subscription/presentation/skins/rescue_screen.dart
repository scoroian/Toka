// lib/features/subscription/presentation/skins/rescue_screen.dart
//
// Wrapper "skin-aware" que renderiza `RescueScreenV2` (única skin activa)
// según el `SkinMode` persistido, consumiendo el mismo
// `rescueViewModelProvider`.

import 'package:flutter/material.dart';

import '../../../../core/theme/skin_switcher.dart';
import 'rescue_screen_v2.dart';

class RescueScreen extends StatelessWidget {
  const RescueScreen({super.key});

  @override
  Widget build(BuildContext context) => SkinSwitch(
        v2: (_) => const RescueScreenV2(),
      );
}
