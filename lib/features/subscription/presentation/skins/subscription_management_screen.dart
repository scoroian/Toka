import 'package:flutter/material.dart';

import '../../../../core/theme/skin_switcher.dart';
import 'futurista/subscription_management_screen_futurista.dart';
import 'subscription_management_screen_v2.dart';

/// Wrapper "skin-aware" para la pantalla *Ajustes → Gestionar suscripción*.
///
/// Selecciona la implementación según el skin activo:
///   - [AppSkin.v2]        → [SubscriptionManagementScreenV2].
///   - [AppSkin.futurista] → [SubscriptionManagementScreenFuturista].
class SubscriptionManagementScreen extends StatelessWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  Widget build(BuildContext context) => SkinSwitch(
        v2: (_) => const SubscriptionManagementScreenV2(),
        futurista: (_) => const SubscriptionManagementScreenFuturista(),
      );
}
