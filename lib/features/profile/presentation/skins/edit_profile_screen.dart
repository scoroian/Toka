// lib/features/profile/presentation/skins/edit_profile_screen.dart
//
// Wrapper que elige entre `EditProfileScreenV2` y
// `EditProfileScreenFuturista` según el `SkinMode` persistido. Ambas
// variantes consumen `editProfileViewModelNotifierProvider`.
import 'package:flutter/material.dart';

import '../../../../core/theme/skin_switcher.dart';
import 'edit_profile_screen_v2.dart';
import 'futurista/edit_profile_screen_futurista.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => SkinSwitch(
        v2: (_) => const EditProfileScreenV2(),
        futurista: (_) => const EditProfileScreenFuturista(),
      );
}
