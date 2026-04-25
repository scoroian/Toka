// lib/features/subscription/presentation/skins/paywall_screen.dart
//
// Wrapper que elige entre `PaywallScreenV2` y `PaywallScreenFuturista`
// según el `SkinMode` persistido. Ambas variantes consumen el mismo
// `paywallViewModelProvider`.

import 'package:flutter/material.dart';

import '../../../../core/theme/skin_switcher.dart';
import '../paywall_entry_context.dart';
import 'futurista/paywall_screen_futurista.dart';
import 'paywall_screen_v2.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({
    super.key,
    this.entryContext = PaywallEntryContext.fromFree,
  });

  final PaywallEntryContext entryContext;

  @override
  Widget build(BuildContext context) => SkinSwitch(
        v2: (_) => PaywallScreenV2(entryContext: entryContext),
        futurista: (_) => PaywallScreenFuturista(entryContext: entryContext),
      );
}
