import '../../../core/constants/free_limits.dart';

/// Resultado de resolver el tope efectivo de miembros de un hogar.
class MemberCapResult {
  const MemberCapResult({required this.cap, required this.limitReached});

  /// Tope efectivo de miembros, o `null` si no hay tope que aplicar en cliente
  /// (dashboard aún cargando, o premium legacy sin tope denormalizado). En ese
  /// caso el backend es el único backstop.
  final int? cap;

  /// `true` si el número de miembros activos alcanza o supera [cap].
  final bool limitReached;
}

/// Deriva el tope de miembros y si está alcanzado, a partir del entitlement
/// denormalizado del dashboard (`premiumFlags`).
///
/// El tope NO se recomputa en cliente: se lee `maxMembers` que el backend
/// escribe según el tier. Fallbacks conservadores:
///  - Sin dashboard (cargando) → sin tope (no bloquear; backend es backstop).
///  - Dashboard viejo sin `maxMembers`: premium → sin tope; free → Free (3).
///
/// El conteo de miembros se pasa EN VIVO (no del contador agregado del
/// dashboard, que se regenera de forma perezosa y queda stale).
MemberCapResult resolveMemberCap({
  required bool hasDashboard,
  required bool isPremium,
  required int? maxMembers,
  required int activeMembersCount,
}) {
  if (!hasDashboard) {
    return const MemberCapResult(cap: null, limitReached: false);
  }
  final cap =
      maxMembers ?? (isPremium ? null : FreeLimits.maxActiveMembers);
  if (cap == null) {
    return const MemberCapResult(cap: null, limitReached: false);
  }
  return MemberCapResult(cap: cap, limitReached: activeMembersCount >= cap);
}

/// Mensaje de límite contextual a mostrar cuando se alcanza el tope.
enum MemberLimitMessage {
  /// Hogar Free: sugiere hacerse Premium.
  free,

  /// Tier Pareja (tope 2): sugiere subir a Familia o Grupo.
  pareja,

  /// Tier Familia (tope 5): sugiere subir a Grupo.
  familia,

  /// Tier Grupo con el flag de packs OFF (tope 10): es el máximo, sin upsell.
  grupo,

  /// Tier Grupo con packs habilitados y por debajo del tope absoluto (25):
  /// ofrece ampliar con un pack de miembros.
  grupoPacks,

  /// Tope absoluto alcanzado (25, Grupo + ambos packs): solo Toka Business.
  business,

  /// Premium binario (flag de tiers OFF) en su tope: sin upsell.
  premiumMax,
}

/// Mensaje de límite para un `(tier, isPremium)`. `tier` es el string
/// denormalizado del dashboard (`'pareja'|'familia'|'grupo'|'free'|null`).
///
/// [packsEnabled] (flag de Remote Config) y [cap] (tope efectivo del hogar)
/// solo importan en Grupo: con packs ON y tope por debajo de
/// [kAbsoluteMaxMembers] se ofrece ampliar con un pack ([grupoPacks]); en el
/// tope absoluto se muestra Toka Business ([business]).
MemberLimitMessage memberLimitMessageFor({
  required String? tier,
  required bool isPremium,
  bool packsEnabled = false,
  int? cap,
}) {
  switch (tier) {
    case 'pareja':
      return MemberLimitMessage.pareja;
    case 'familia':
      return MemberLimitMessage.familia;
    case 'grupo':
      if (!packsEnabled) return MemberLimitMessage.grupo;
      // Con packs ON: si el tope ya es el absoluto, solo queda Business; si no,
      // se ofrece ampliar con un pack. cap desconocido (null) → aún no maxado.
      return (cap != null && cap >= kAbsoluteMaxMembers)
          ? MemberLimitMessage.business
          : MemberLimitMessage.grupoPacks;
    case 'free':
      return MemberLimitMessage.free;
    default:
      // tier null → flag de tiers OFF (modo binario).
      return isPremium ? MemberLimitMessage.premiumMax : MemberLimitMessage.free;
  }
}

/// Si el mensaje de límite debe ofrecer un CTA para subir de plan / comprar un
/// pack (lleva al paywall). Falso cuando ya se está en el máximo (Grupo sin
/// packs, premium binario) o en el tope absoluto ([business] tiene su propio
/// CTA, ver [memberLimitShowsBusiness]).
bool memberLimitShowsUpsell(MemberLimitMessage message) {
  switch (message) {
    case MemberLimitMessage.free:
    case MemberLimitMessage.pareja:
    case MemberLimitMessage.familia:
    case MemberLimitMessage.grupoPacks:
      return true;
    case MemberLimitMessage.grupo:
    case MemberLimitMessage.business:
    case MemberLimitMessage.premiumMax:
      return false;
  }
}

/// Si el mensaje debe ofrecer el CTA informativo de Toka Business (tope
/// absoluto alcanzado). Mutuamente excluyente con [memberLimitShowsUpsell].
bool memberLimitShowsBusiness(MemberLimitMessage message) =>
    message == MemberLimitMessage.business;
