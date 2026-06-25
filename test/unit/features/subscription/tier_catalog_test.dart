import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/subscription/domain/tier_catalog.dart';

void main() {
  group('HomeTier.maxMembers', () {
    test('cada tier tiene el tope de la spec de producto', () {
      expect(HomeTier.pareja.maxMembers, 2);
      expect(HomeTier.familia.maxMembers, 5);
      expect(HomeTier.grupo.maxMembers, 10);
    });
  });

  group('HomeTier.id', () {
    test('el id coincide con el string persistido por el backend', () {
      expect(HomeTier.pareja.id, 'pareja');
      expect(HomeTier.familia.id, 'familia');
      expect(HomeTier.grupo.id, 'grupo');
    });
  });

  group('homeTierFromString', () {
    test('mapea los strings premium del backend a su tier', () {
      expect(homeTierFromString('pareja'), HomeTier.pareja);
      expect(homeTierFromString('familia'), HomeTier.familia);
      expect(homeTierFromString('grupo'), HomeTier.grupo);
    });

    test('"free", null y valores desconocidos → null (no es un tier premium)',
        () {
      expect(homeTierFromString('free'), isNull);
      expect(homeTierFromString(null), isNull);
      expect(homeTierFromString(''), isNull);
      expect(homeTierFromString('garbage'), isNull);
    });
  });

  group('productIdFor', () {
    test('los 6 SKUs coinciden EXACTAMENTE con el catálogo del backend', () {
      expect(productIdFor(HomeTier.pareja, BillingCycle.monthly),
          'toka_pareja_monthly');
      expect(productIdFor(HomeTier.pareja, BillingCycle.annual),
          'toka_pareja_annual');
      expect(productIdFor(HomeTier.familia, BillingCycle.monthly),
          'toka_familia_monthly');
      expect(productIdFor(HomeTier.familia, BillingCycle.annual),
          'toka_familia_annual');
      expect(productIdFor(HomeTier.grupo, BillingCycle.monthly),
          'toka_grupo_monthly');
      expect(productIdFor(HomeTier.grupo, BillingCycle.annual),
          'toka_grupo_annual');
    });
  });

  group('allTierProductIds', () {
    test('contiene exactamente los 6 SKUs de tier', () {
      expect(allTierProductIds, hasLength(6));
      expect(
        allTierProductIds,
        containsAll(<String>{
          'toka_pareja_monthly',
          'toka_pareja_annual',
          'toka_familia_monthly',
          'toka_familia_annual',
          'toka_grupo_monthly',
          'toka_grupo_annual',
        }),
      );
    });
  });

  group('tierForProductId', () {
    test('revierte cada SKU a su tier', () {
      expect(tierForProductId('toka_pareja_monthly'), HomeTier.pareja);
      expect(tierForProductId('toka_pareja_annual'), HomeTier.pareja);
      expect(tierForProductId('toka_familia_monthly'), HomeTier.familia);
      expect(tierForProductId('toka_familia_annual'), HomeTier.familia);
      expect(tierForProductId('toka_grupo_monthly'), HomeTier.grupo);
      expect(tierForProductId('toka_grupo_annual'), HomeTier.grupo);
    });

    test('SKU no catalogado o legacy → null', () {
      expect(tierForProductId('toka_premium_monthly'), isNull);
      expect(tierForProductId('desconocido'), isNull);
    });
  });

  group('smallestTierForMembers', () {
    test('elige el menor tier cuyo tope cabe el número de miembros', () {
      expect(smallestTierForMembers(1), HomeTier.pareja);
      expect(smallestTierForMembers(2), HomeTier.pareja);
      expect(smallestTierForMembers(3), HomeTier.familia);
      expect(smallestTierForMembers(5), HomeTier.familia);
      expect(smallestTierForMembers(6), HomeTier.grupo);
      expect(smallestTierForMembers(10), HomeTier.grupo);
    });

    test('por encima del mayor tope cae al tier mayor (Grupo)', () {
      expect(smallestTierForMembers(11), HomeTier.grupo);
      expect(smallestTierForMembers(999), HomeTier.grupo);
    });
  });
}
