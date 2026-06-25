import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/members/application/member_limit.dart';

void main() {
  group('resolveMemberCap', () {
    test('sin dashboard (cargando) → sin tope cliente, nunca bloquea', () {
      final r = resolveMemberCap(
        hasDashboard: false,
        isPremium: true,
        maxMembers: null,
        activeMembersCount: 99,
      );
      expect(r.cap, isNull);
      expect(r.limitReached, isFalse);
    });

    test('Free (tope 3): bloquea en 3, no en 2', () {
      expect(
        resolveMemberCap(
          hasDashboard: true,
          isPremium: false,
          maxMembers: 3,
          activeMembersCount: 2,
        ).limitReached,
        isFalse,
      );
      expect(
        resolveMemberCap(
          hasDashboard: true,
          isPremium: false,
          maxMembers: 3,
          activeMembersCount: 3,
        ).limitReached,
        isTrue,
      );
    });

    test('Pareja (tope 2): tope±1 y justo en el tope', () {
      expect(
        resolveMemberCap(
          hasDashboard: true,
          isPremium: true,
          maxMembers: 2,
          activeMembersCount: 1,
        ).limitReached,
        isFalse,
      );
      expect(
        resolveMemberCap(
          hasDashboard: true,
          isPremium: true,
          maxMembers: 2,
          activeMembersCount: 2,
        ).limitReached,
        isTrue,
      );
      expect(
        resolveMemberCap(
          hasDashboard: true,
          isPremium: true,
          maxMembers: 2,
          activeMembersCount: 3,
        ).limitReached,
        isTrue,
      );
    });

    test('Familia (tope 5): bloquea en 5, no en 4', () {
      expect(
        resolveMemberCap(
          hasDashboard: true,
          isPremium: true,
          maxMembers: 5,
          activeMembersCount: 4,
        ).limitReached,
        isFalse,
      );
      expect(
        resolveMemberCap(
          hasDashboard: true,
          isPremium: true,
          maxMembers: 5,
          activeMembersCount: 5,
        ).limitReached,
        isTrue,
      );
    });

    test('Grupo (tope 10): bloquea en 10, no en 9', () {
      expect(
        resolveMemberCap(
          hasDashboard: true,
          isPremium: true,
          maxMembers: 10,
          activeMembersCount: 9,
        ).limitReached,
        isFalse,
      );
      expect(
        resolveMemberCap(
          hasDashboard: true,
          isPremium: true,
          maxMembers: 10,
          activeMembersCount: 10,
        ).limitReached,
        isTrue,
      );
    });

    test('lista vacía (0 miembros) nunca bloquea', () {
      expect(
        resolveMemberCap(
          hasDashboard: true,
          isPremium: false,
          maxMembers: 3,
          activeMembersCount: 0,
        ).limitReached,
        isFalse,
      );
    });

    test('dashboard viejo sin maxMembers + premium → sin tope cliente (legacy)',
        () {
      final r = resolveMemberCap(
        hasDashboard: true,
        isPremium: true,
        maxMembers: null,
        activeMembersCount: 50,
      );
      expect(r.cap, isNull);
      expect(r.limitReached, isFalse);
    });

    test('dashboard viejo sin maxMembers + free → cae al tope Free 3 (legacy)',
        () {
      final r = resolveMemberCap(
        hasDashboard: true,
        isPremium: false,
        maxMembers: null,
        activeMembersCount: 3,
      );
      expect(r.cap, 3);
      expect(r.limitReached, isTrue);
    });

    test('flag OFF: premium binario (tope 10) bloquea en 10', () {
      expect(
        resolveMemberCap(
          hasDashboard: true,
          isPremium: true,
          maxMembers: 10,
          activeMembersCount: 10,
        ).limitReached,
        isTrue,
      );
    });
  });

  group('memberLimitMessageFor', () {
    test('mapea cada tier a su mensaje', () {
      expect(memberLimitMessageFor(tier: 'pareja', isPremium: true),
          MemberLimitMessage.pareja);
      expect(memberLimitMessageFor(tier: 'familia', isPremium: true),
          MemberLimitMessage.familia);
      expect(memberLimitMessageFor(tier: 'grupo', isPremium: true),
          MemberLimitMessage.grupo);
      expect(memberLimitMessageFor(tier: 'free', isPremium: false),
          MemberLimitMessage.free);
    });

    test('tier null (flag OFF): premium → premiumMax, free → free', () {
      expect(memberLimitMessageFor(tier: null, isPremium: true),
          MemberLimitMessage.premiumMax);
      expect(memberLimitMessageFor(tier: null, isPremium: false),
          MemberLimitMessage.free);
    });

    test('Grupo con flag de packs OFF → grupo (máximo 10, sin packs)', () {
      expect(
        memberLimitMessageFor(
            tier: 'grupo', isPremium: true, packsEnabled: false, cap: 10),
        MemberLimitMessage.grupo,
      );
    });

    test('Grupo con flag de packs ON y cap < 25 → grupoPacks (ofrece pack)', () {
      // Grupo base (10), con +5 (15) y con +10 (20): aún cabe ampliar.
      for (final cap in [10, 15, 20]) {
        expect(
          memberLimitMessageFor(
              tier: 'grupo', isPremium: true, packsEnabled: true, cap: cap),
          MemberLimitMessage.grupoPacks,
          reason: 'cap $cap debería ofrecer pack',
        );
      }
    });

    test('Grupo con flag de packs ON y cap = 25 → business (tope absoluto)', () {
      expect(
        memberLimitMessageFor(
            tier: 'grupo', isPremium: true, packsEnabled: true, cap: 25),
        MemberLimitMessage.business,
      );
    });

    test('Grupo con packs ON pero cap desconocido (null) → grupoPacks', () {
      expect(
        memberLimitMessageFor(
            tier: 'grupo', isPremium: true, packsEnabled: true, cap: null),
        MemberLimitMessage.grupoPacks,
      );
    });

    test('el flag de packs NO afecta a pareja/familia/free', () {
      expect(
        memberLimitMessageFor(
            tier: 'pareja', isPremium: true, packsEnabled: true, cap: 2),
        MemberLimitMessage.pareja,
      );
      expect(
        memberLimitMessageFor(
            tier: 'familia', isPremium: true, packsEnabled: true, cap: 5),
        MemberLimitMessage.familia,
      );
      expect(
        memberLimitMessageFor(
            tier: 'free', isPremium: false, packsEnabled: true, cap: 3),
        MemberLimitMessage.free,
      );
    });
  });

  group('memberLimitShowsUpsell', () {
    test('Free/Pareja/Familia ofrecen subir de plan', () {
      expect(memberLimitShowsUpsell(MemberLimitMessage.free), isTrue);
      expect(memberLimitShowsUpsell(MemberLimitMessage.pareja), isTrue);
      expect(memberLimitShowsUpsell(MemberLimitMessage.familia), isTrue);
    });

    test('Grupo y premium binario están en el máximo: sin upsell', () {
      expect(memberLimitShowsUpsell(MemberLimitMessage.grupo), isFalse);
      expect(memberLimitShowsUpsell(MemberLimitMessage.premiumMax), isFalse);
    });

    test('grupoPacks ofrece upsell (al paywall, a por un pack)', () {
      expect(memberLimitShowsUpsell(MemberLimitMessage.grupoPacks), isTrue);
    });

    test('business NO ofrece upsell al paywall (tiene su propio CTA)', () {
      expect(memberLimitShowsUpsell(MemberLimitMessage.business), isFalse);
    });
  });

  group('memberLimitShowsBusiness', () {
    test('solo business muestra el CTA de Toka Business', () {
      expect(memberLimitShowsBusiness(MemberLimitMessage.business), isTrue);
      for (final m in [
        MemberLimitMessage.free,
        MemberLimitMessage.pareja,
        MemberLimitMessage.familia,
        MemberLimitMessage.grupo,
        MemberLimitMessage.grupoPacks,
        MemberLimitMessage.premiumMax,
      ]) {
        expect(memberLimitShowsBusiness(m), isFalse, reason: '$m');
      }
    });
  });
}
