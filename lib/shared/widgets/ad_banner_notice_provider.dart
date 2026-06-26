import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:toka/features/homes/application/dashboard_provider.dart';
import 'ad_visibility_provider.dart';

part 'ad_banner_notice_provider.g.dart';

/// Elegibilidad PURA para la caption "tu hogar es Premium pero ves banner".
///
/// Verdadero **solo** en la única fila confusa de la matriz de anuncios: miembro
/// no-pagador de un hogar Premium sin Toka Plus (espeja la rama premium de
/// `computeAdVisibility`, donde el banner sigue visible). En cualquier otra
/// combinación no hay nada que explicar.
bool computeBannerNoticeEligible({
  required bool homeIsPremium,
  required bool isPayer,
  required bool hasPlus,
}) =>
    homeIsPremium && !isPayer && !hasPlus;

/// Elegibilidad cableada reusando [adVisibilityProvider] como fuente de verdad.
///
/// Equivalencia (probada): `banner ∧ isPremium ⇔ premium ∧ ¬pagador ∧ ¬Plus`.
/// Como `banner = ¬Plus ∧ ¬(premium ∧ pagador)`, al conjugarlo con `premium`
/// queda `premium ∧ ¬Plus ∧ ¬pagador` — exactamente [computeBannerNoticeEligible].
///
/// Reusar [adVisibilityProvider] (en vez de releer auth/currentHome/plus) evita
/// duplicar el cómputo y NO acopla el camino de padding del shell al timer de
/// `authProvider`: donde adVisibility ya está resuelto/mockeado, esto lo sigue.
/// Fail-safe `false` mientras el dashboard no se conoce (cargando o error).
@Riverpod(keepAlive: true)
bool adBannerNoticeEligible(AdBannerNoticeEligibleRef ref) {
  final dashboard = ref.watch(dashboardProvider).valueOrNull;
  if (dashboard == null || !dashboard.premiumFlags.isPremium) return false;
  return ref.watch(adVisibilityProvider).banner;
}

/// Descarte de la caption para ESTA sesión (in-memory, ámbito global: reaparece
/// tras reiniciar la app, comportamiento suave y sin estado persistido).
///
/// Global (no por hogar) a propósito: ligar el descarte a un hogar concreto
/// exigiría leer `currentHomeProvider` en el camino de padding del shell, que
/// arrastra el timer de `authProvider`. Global es además "menos nag".
@Riverpod(keepAlive: true)
class AdBannerNoticeDismissed extends _$AdBannerNoticeDismissed {
  @override
  bool build() => false;

  void dismiss() => state = true;
}

/// Visible ⇔ elegible ∧ no descartada en esta sesión.
///
/// Route/teclado-agnóstico a propósito: cada consumidor (shell, helpers de
/// padding) lo combina con su propio `bannerVisible` para no reservar altura
/// cuando el banner no se muestra (ruta suprimida, teclado abierto, etc.).
@Riverpod(keepAlive: true)
bool adBannerNoticeVisible(AdBannerNoticeVisibleRef ref) {
  if (ref.watch(adBannerNoticeDismissedProvider)) return false;
  return ref.watch(adBannerNoticeEligibleProvider);
}
