// lib/features/profile/presentation/skins/edit_profile_screen.dart
//
// Wrapper "skin-aware" que renderiza `EditProfileScreenV2` (única skin activa)
// según el `SkinMode` persistido, consumiendo
// `editProfileViewModelNotifierProvider`.
import 'package:flutter/material.dart';

import '../../../../core/theme/skin_switcher.dart';
import 'edit_profile_screen_v2.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => SkinSwitch(
        v2: (_) => const EditProfileScreenV2(),
      );
}
