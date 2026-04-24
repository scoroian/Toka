// lib/features/profile/presentation/skins/own_profile_screen.dart
//
// Wrapper que elige entre `OwnProfileScreenV2` y `ProfileScreenFuturista`
// según el `SkinMode` persistido. Ambas variantes consumen
// `ownProfileViewModelProvider`.
import 'package:flutter/material.dart';

import '../../../../core/theme/skin_switcher.dart';
import 'futurista/profile_screen_futurista.dart';
import 'own_profile_screen_v2.dart';

class OwnProfileScreen extends StatelessWidget {
  const OwnProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => SkinSwitch(
        v2: (_) => const OwnProfileScreenV2(),
        futurista: (_) => const ProfileScreenFuturista(isOwnProfile: true),
      );
}
