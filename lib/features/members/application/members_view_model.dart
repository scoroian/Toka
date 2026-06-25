// lib/features/members/application/members_view_model.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_provider.dart';
import '../../homes/application/current_home_provider.dart';
import '../../homes/application/dashboard_provider.dart';
import '../../homes/application/homes_provider.dart';
import '../../homes/domain/home_membership.dart';
import '../domain/member.dart';
import 'member_limit.dart';
import 'members_provider.dart';

part 'members_view_model.g.dart';

class MembersViewData {
  const MembersViewData({
    required this.activeMembers,
    required this.frozenMembers,
    required this.leftMembers,
    required this.canReinstate,
    required this.canInvite,
    required this.homeId,
    required this.isPremium,
    required this.tier,
    required this.activeMembersCount,
    required this.effectiveMaxMembers,
    required this.limitReached,
  });
  final List<Member> activeMembers;
  final List<Member> frozenMembers;
  /// Miembros 'left' que se pueden reincorporar.
  final List<Member> leftMembers;
  /// True si el usuario actual (owner/admin) puede reincorporar miembros.
  final bool canReinstate;
  /// True cuando rol permite invitar Y no se ha alcanzado el tope del plan.
  final bool canInvite;
  final String homeId;
  final bool isPremium;
  /// Tier efectivo del hogar (`'pareja'|'familia'|'grupo'|'free'|null`),
  /// denormalizado por el backend. `null` con el flag de tiers OFF.
  final String? tier;
  final int activeMembersCount;
  /// Tope de miembros efectivo del plan, o `null` si no aplica tope en cliente.
  final int? effectiveMaxMembers;
  /// True cuando `activeMembersCount` alcanza el tope efectivo del plan (Free o
  /// cualquier tier premium).
  final bool limitReached;
}

abstract class MembersViewModel {
  AsyncValue<MembersViewData?> get viewData;
}

class _MembersViewModelImpl implements MembersViewModel {
  const _MembersViewModelImpl({required this.viewData});
  @override
  final AsyncValue<MembersViewData?> viewData;
}

@riverpod
MembersViewModel membersViewModel(MembersViewModelRef ref) {
  final homeAsync = ref.watch(currentHomeProvider);
  final auth = ref.watch(authProvider);
  final uid = auth.whenOrNull(authenticated: (u) => u.uid) ?? '';

  final viewData = homeAsync.whenData((home) {
    if (home == null) return null;

    final membershipsAsync =
        uid.isNotEmpty ? ref.watch(userMembershipsProvider(uid)) : null;
    final myMembership = membershipsAsync?.valueOrNull
        ?.where((m) => m.homeId == home.id)
        .cast<HomeMembership?>()
        .firstOrNull;
    final roleCanInvite = myMembership?.role == MemberRole.owner ||
        myMembership?.role == MemberRole.admin;

    final membersAsync = ref.watch(homeMembersProvider(home.id));
    final allMembers = membersAsync.valueOrNull ?? [];
    final activeMembers =
        allMembers.where((m) => m.status == MemberStatus.active).toList();
    final frozenMembers =
        allMembers.where((m) => m.status == MemberStatus.frozen).toList();
    // Antiguos miembros (status='left') para reincorporación — provider aparte
    // (la lista principal los excluye a propósito). Excluimos las cuentas
    // ELIMINADAS (accountDeleted): el usuario Auth ya no existe, no se pueden
    // reincorporar y mostraban su uid crudo + un botón "Reincorporar" inválido.
    final leftMembers =
        (ref.watch(leftMembersProvider(home.id)).valueOrNull ?? const [])
            .where((m) => !m.accountDeleted)
            .toList();

    // Gating del tope de miembros: el tier y el tope efectivo se LEEN del
    // entitlement denormalizado por el backend (`premiumFlags.tier/maxMembers`),
    // nunca se recomputan en cliente. Fallback conservador: sin dashboard
    // asumimos Premium sin tope hasta que llegue (el backend es el backstop
    // real). Con el flag de tiers OFF, el backend escribe tope binario (10/3) y
    // tier null → la UI cae sola al comportamiento anterior.
    final dashboardAsync = ref.watch(dashboardProvider);
    final dashboard = dashboardAsync.valueOrNull;
    final flags = dashboard?.premiumFlags;
    final isPremium = flags?.isPremium ?? true;
    final tier = flags?.tier;
    // El conteo de miembros activos se toma del stream EN VIVO de miembros
    // (homeMembersProvider excluye status='left'), NO de
    // dashboard.planCounters.activeMembers: ese contador agregado se regenera de
    // forma perezosa en backend y queda stale tras expulsar/abandonar, lo que
    // bloqueaba indebidamente invitar a un reemplazo (mostraba "lleno" con menos
    // activos). El conteo en vivo siempre es coherente con la lista que ve el
    // usuario.
    final activeMembersCount = activeMembers.length;
    final cap = resolveMemberCap(
      hasDashboard: dashboard != null,
      isPremium: isPremium,
      maxMembers: flags?.maxMembers,
      activeMembersCount: activeMembersCount,
    );

    return MembersViewData(
      activeMembers: activeMembers,
      frozenMembers: frozenMembers,
      leftMembers: leftMembers,
      canReinstate: roleCanInvite,
      canInvite: roleCanInvite && !cap.limitReached,
      homeId: home.id,
      isPremium: isPremium,
      tier: tier,
      activeMembersCount: activeMembersCount,
      effectiveMaxMembers: cap.cap,
      limitReached: cap.limitReached,
    );
  });

  return _MembersViewModelImpl(viewData: viewData);
}
