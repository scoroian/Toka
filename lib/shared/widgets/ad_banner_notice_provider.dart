import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/application/dashboard_provider.dart';
import 'package:toka/features/subscription/application/plus_provider.dart';

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

/// Elegibilidad cableada a Firestore (mismos inputs que `adVisibilityProvider`).
/// Fail-safe `false` mientras dashboard/home no se conocen (cargando o error).
@Riverpod(keepAlive: true)
bool adBannerNoticeEligible(AdBannerNoticeEligibleRef ref) {
  final dashboard = ref.watch(dashboardProvider).valueOrNull;
  final home = ref.watch(currentHomeProvider).valueOrNull;
  if (dashboard == null || home == null) return false;

  final uid = ref.watch(authProvider).whenOrNull(authenticated: (u) => u.uid);
  final isPayer = home.currentPayerUid != null && home.currentPayerUid == uid;
  final hasPlus = ref.watch(plusActiveProvider);

  return computeBannerNoticeEligible(
    homeIsPremium: dashboard.premiumFlags.isPremium,
    isPayer: isPayer,
    hasPlus: hasPlus,
  );
}

/// Conjunto de homeIds para los que el usuario descartó la caption en ESTA
/// sesión (in-memory: reaparece tras reiniciar la app, comportamiento suave y
/// sin estado persistido).
@Riverpod(keepAlive: true)
class AdBannerNoticeDismissal extends _$AdBannerNoticeDismissal {
  @override
  Set<String> build() => const {};

  void dismiss(String homeId) {
    if (state.contains(homeId)) return;
    state = {...state, homeId};
  }
}

/// Visible ⇔ elegible ∧ hay homeId ∧ no descartada para ese hogar.
///
/// Route/teclado-agnóstico a propósito: cada consumidor (shell, helpers de
/// padding) lo combina con su propio `bannerVisible` para no reservar altura
/// cuando el banner no se muestra (ruta suprimida, teclado abierto, etc.).
@Riverpod(keepAlive: true)
bool adBannerNoticeVisible(AdBannerNoticeVisibleRef ref) {
  if (!ref.watch(adBannerNoticeEligibleProvider)) return false;
  final homeId = ref.watch(currentHomeProvider).valueOrNull?.id;
  if (homeId == null) return false;
  return !ref.watch(adBannerNoticeDismissalProvider).contains(homeId);
}
