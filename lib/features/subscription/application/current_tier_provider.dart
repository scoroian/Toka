import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../homes/application/dashboard_provider.dart';
import '../domain/tier_catalog.dart';

/// Tier premium ACTUAL del hogar, derivado del entitlement denormalizado por el
/// backend (`dashboard.premiumFlags.tier`). `null` si no hay tier vigente (Free,
/// flag de tiers OFF, o dashboard antiguo sin el campo). El cliente solo LEE el
/// tier; nunca lo recomputa.
///
/// Es un `Provider` derivado simple (sin codegen) para poder overridearlo en
/// tests con un `HomeTier?` directo, sin construir un `HomeDashboard` completo ni
/// inicializar Firebase. Lo consume la pantalla de rescate para renovar el tier
/// correcto (ver `renewalProductId`).
final currentHomeTierProvider = Provider<HomeTier?>((ref) {
  final tierStr = ref.watch(
    dashboardProvider.select((d) => d.valueOrNull?.premiumFlags.tier),
  );
  return homeTierFromString(tierStr);
});
