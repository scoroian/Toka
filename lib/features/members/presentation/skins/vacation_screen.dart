import 'package:flutter/material.dart';
import 'package:toka/core/theme/skin_switcher.dart';

import 'futurista/vacation_screen_futurista.dart';
import 'vacation_screen_v2.dart';

/// Wrapper que selecciona la skin activa (v2 o futurista) para la pantalla
/// de vacaciones / ausencia. Ambos sub-widgets consumen el mismo
/// `vacationViewModelNotifierProvider`, sólo cambia la presentación.
class VacationScreen extends StatelessWidget {
  const VacationScreen({
    super.key,
    required this.homeId,
    required this.uid,
  });

  final String homeId;
  final String uid;

  @override
  Widget build(BuildContext context) => SkinSwitch(
        v2: (_) => VacationScreenV2(homeId: homeId, uid: uid),
        futurista: (_) => VacationScreenFuturista(homeId: homeId, uid: uid),
      );
}
