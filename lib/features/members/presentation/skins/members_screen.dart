import 'package:flutter/material.dart';

import '../../../../core/theme/skin_switcher.dart';
import 'futurista/members_screen_futurista.dart';
import 'members_screen_v2.dart';

/// Wrapper que elige entre la pantalla de miembros v2 y la variante futurista
/// según el `SkinMode` persistido. Ambas variantes consumen el mismo
/// `membersViewModelProvider`.
class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context) => SkinSwitch(
        v2: (_) => const MembersScreenV2(),
        futurista: (_) => const MembersScreenFuturista(),
      );
}
