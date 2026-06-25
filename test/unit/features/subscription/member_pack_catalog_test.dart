import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/subscription/domain/member_pack_catalog.dart';
import 'package:toka/features/subscription/domain/tier_catalog.dart';

void main() {
  group('MemberPack.seats', () {
    test('cada pack añade las plazas de la spec de producto', () {
      expect(MemberPack.plus5.seats, 5);
      expect(MemberPack.plus10.seats, 10);
    });
  });

  group('MemberPack.id', () {
    test('el id coincide con el PackKind persistido por el backend', () {
      expect(MemberPack.plus5.id, 'plus5');
      expect(MemberPack.plus10.id, 'plus10');
    });
  });

  group('packProductIdFor', () {
    test('los 4 SKUs coinciden EXACTAMENTE con el catálogo del backend', () {
      expect(packProductIdFor(MemberPack.plus5, BillingCycle.monthly),
          'toka_pack5_monthly');
      expect(packProductIdFor(MemberPack.plus5, BillingCycle.annual),
          'toka_pack5_annual');
      expect(packProductIdFor(MemberPack.plus10, BillingCycle.monthly),
          'toka_pack10_monthly');
      expect(packProductIdFor(MemberPack.plus10, BillingCycle.annual),
          'toka_pack10_annual');
    });
  });

  group('allMemberPackProductIds', () {
    test('contiene exactamente los 4 SKUs de pack', () {
      expect(allMemberPackProductIds, hasLength(4));
      expect(
        allMemberPackProductIds,
        containsAll(<String>{
          'toka_pack5_monthly',
          'toka_pack5_annual',
          'toka_pack10_monthly',
          'toka_pack10_annual',
        }),
      );
    });
  });

  group('memberPackForProductId', () {
    test('revierte cada SKU a su pack', () {
      expect(memberPackForProductId('toka_pack5_monthly'), MemberPack.plus5);
      expect(memberPackForProductId('toka_pack5_annual'), MemberPack.plus5);
      expect(memberPackForProductId('toka_pack10_monthly'), MemberPack.plus10);
      expect(memberPackForProductId('toka_pack10_annual'), MemberPack.plus10);
    });

    test('SKU no catalogado (incl. SKUs de tier) → null', () {
      expect(memberPackForProductId('toka_grupo_annual'), isNull);
      expect(memberPackForProductId('toka_premium_monthly'), isNull);
      expect(memberPackForProductId('desconocido'), isNull);
    });
  });

  group('kAbsoluteMaxMembers', () {
    test('el tope absoluto es 25 (espejo de ABSOLUTE_MAX_MEMBERS del backend)',
        () {
      expect(kAbsoluteMaxMembers, 25);
    });
  });

  group('resultingCap', () {
    test('comprar +5 sobre Grupo (10) → 15', () {
      expect(resultingCap(currentMax: 10, pack: MemberPack.plus5), 15);
    });

    test('comprar +10 sobre Grupo (10) → 20', () {
      expect(resultingCap(currentMax: 10, pack: MemberPack.plus10), 20);
    });

    test('comprar +10 cuando ya hay +5 (currentMax 15) → 25', () {
      expect(resultingCap(currentMax: 15, pack: MemberPack.plus10), 25);
    });

    test('comprar +5 cuando ya hay +10 (currentMax 20) → 25', () {
      expect(resultingCap(currentMax: 20, pack: MemberPack.plus5), 25);
    });

    test('nunca supera el tope absoluto de 25', () {
      expect(resultingCap(currentMax: 20, pack: MemberPack.plus10), 25);
      expect(resultingCap(currentMax: 25, pack: MemberPack.plus5), 25);
    });
  });
}
