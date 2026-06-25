import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/application/dashboard_provider.dart';
import 'package:toka/features/subscription/application/plus_provider.dart';

part 'ad_visibility_provider.g.dart';

/// Visibilidad de anuncios resuelta per-usuario: combina el estado premium del
/// hogar, el rol de pagador y el entitlement individual Toka Plus.
///
/// `banner` e `interstitial` son independientes: el Premium del hogar elimina el
/// intersticial para TODOS sus miembros (beneficio colectivo), mientras que el
/// banner solo se quita individualmente (siendo el pagador de un hogar Premium, o
/// teniendo Toka Plus).
class AdVisibility {
  const AdVisibility({required this.banner, required this.interstitial});

  final bool banner;
  final bool interstitial;

  /// Estado conservador usado como fail-safe mientras no se conoce el estado
  /// (premium/Plus/pagador cargando o en error): ambos ocultos.
  static const AdVisibility hidden =
      AdVisibility(banner: false, interstitial: false);

  @override
  bool operator ==(Object other) =>
      other is AdVisibility &&
      other.banner == banner &&
      other.interstitial == interstitial;

  @override
  int get hashCode => Object.hash(banner, interstitial);

  @override
  String toString() => 'AdVisibility(banner: $banner, interstitial: $interstitial)';
}

/// Función PURA que genera la matriz de visibilidad de anuncios.
///
/// Reglas (fuente de verdad del comportamiento):
/// - **Intersticial** visible ⇔ el hogar NO es Premium ∧ el usuario NO tiene Plus.
/// - **Banner** visible ⇔ el usuario NO tiene Plus ∧ no es el pagador de un hogar
///   Premium.
AdVisibility computeAdVisibility({
  required bool homeIsPremium,
  required bool isPayer,
  required bool hasPlus,
}) {
  final interstitial = !homeIsPremium && !hasPlus;
  final banner = !hasPlus && !(homeIsPremium && isPayer);
  return AdVisibility(banner: banner, interstitial: interstitial);
}

/// Visibilidad de anuncios para el usuario y hogar actuales.
///
/// Inputs **leídos de Firestore** (nunca hardcode):
/// - Premium del hogar ← `dashboardProvider.premiumFlags.isPremium`
///   (calculado por el backend; cubre cualquier tier).
/// - Pagador ← `currentHomeProvider.currentPayerUid == uid` (`authProvider`).
/// - Toka Plus ← `plusActiveProvider`.
///
/// **Fail-safe**: si el dashboard o el hogar todavía no se conocen (cargando o
/// error → `valueOrNull == null`) devuelve [AdVisibility.hidden] (ocultar ambos),
/// para no parpadear un anuncio a un usuario de pago. Reactivo: se recalcula en
/// caliente cuando cambia el premium del hogar, el pagador o el estado de Plus.
@Riverpod(keepAlive: true)
AdVisibility adVisibility(AdVisibilityRef ref) {
  final dashboard = ref.watch(dashboardProvider).valueOrNull;
  final home = ref.watch(currentHomeProvider).valueOrNull;
  // Estado aún desconocido → fail-safe a ocultar ambos.
  if (dashboard == null || home == null) return AdVisibility.hidden;

  final uid = ref.watch(authProvider).whenOrNull(authenticated: (u) => u.uid);
  final isPayer = home.currentPayerUid != null && home.currentPayerUid == uid;
  final hasPlus = ref.watch(plusActiveProvider);

  return computeAdVisibility(
    homeIsPremium: dashboard.premiumFlags.isPremium,
    isPayer: isPayer,
    hasPlus: hasPlus,
  );
}
