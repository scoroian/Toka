import 'package:flutter/material.dart';

import '../../../../core/theme/skin_switcher.dart';
import 'plus_paywall_screen_v2.dart';

/// Wrapper skin-aware del paywall de Toka Plus.
class PlusPaywallScreen extends StatelessWidget {
  const PlusPaywallScreen({super.key});

  @override
  Widget build(BuildContext context) => SkinSwitch(
        v2: (_) => const PlusPaywallScreenV2(),
      );
}
