// lib/features/profile/presentation/skins/own_profile_screen.dart
//
// Wrapper "skin-aware" que renderiza `OwnProfileScreenV2` (única skin activa)
// según el `SkinMode` persistido, consumiendo `ownProfileViewModelProvider`.
import 'package:flutter/material.dart';

import '../../../../core/theme/skin_switcher.dart';
import 'own_profile_screen_v2.dart';

class OwnProfileScreen extends StatelessWidget {
  const OwnProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => SkinSwitch(
        v2: (_) => const OwnProfileScreenV2(),
      );
}
