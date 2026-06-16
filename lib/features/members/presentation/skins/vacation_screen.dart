import 'package:flutter/material.dart';
import 'package:toka/core/theme/skin_switcher.dart';

import 'vacation_screen_v2.dart';

/// Wrapper "skin-aware" que renderiza la pantalla de vacaciones / ausencia v2
/// (única skin activa) según el `SkinMode` persistido, consumiendo el mismo
/// `vacationViewModelNotifierProvider`.
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
      );
}
