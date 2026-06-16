import 'package:flutter/material.dart';

import '../../../../core/theme/skin_switcher.dart';
import 'members_screen_v2.dart';

/// Wrapper "skin-aware" que renderiza la pantalla de miembros v2 (única skin
/// activa) según el `SkinMode` persistido, consumiendo el mismo
/// `membersViewModelProvider`.
class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context) => SkinSwitch(
        v2: (_) => const MembersScreenV2(),
      );
}
