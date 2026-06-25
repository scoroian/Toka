// test/unit/features/subscription/renewal_product_test.dart
//
// La pantalla de rescate renueva el Premium que está expirando. Con el modelo de
// tiers activo (`home_tiers_enabled`), debe renovar el TIER ACTUAL del hogar, no
// el SKU legacy `toka_premium_*` (que el backend mapea a Grupo → upgrade no
// deseado + precio equivocado). Con el flag OFF (binario), conserva el SKU legacy.
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/subscription/domain/renewal_product.dart';
import 'package:toka/features/subscription/domain/subscription_products.dart';
import 'package:toka/features/subscription/domain/tier_catalog.dart';

void main() {
  group('renewalProductId — tiers OFF (binario)', () {
    test('anual → SKU legacy toka_premium_annual', () {
      expect(
        renewalProductId(
            tiersEnabled: false, tier: null, cycle: BillingCycle.annual),
        kAnnualProductId,
      );
    });

    test('mensual → SKU legacy toka_premium_monthly', () {
      expect(
        renewalProductId(
            tiersEnabled: false, tier: HomeTier.grupo, cycle: BillingCycle.monthly),
        kMonthlyProductId,
      );
    });
  });

  group('renewalProductId — tiers ON', () {
    test('renueva el tier actual (Pareja anual), NO el legacy', () {
      final sku = renewalProductId(
          tiersEnabled: true, tier: HomeTier.pareja, cycle: BillingCycle.annual);
      expect(sku, 'toka_pareja_annual');
      expect(sku, isNot(kAnnualProductId)); // no es legacy → no sube a Grupo
    });

    test('renueva Familia mensual', () {
      expect(
        renewalProductId(
            tiersEnabled: true, tier: HomeTier.familia, cycle: BillingCycle.monthly),
        'toka_familia_monthly',
      );
    });

    test('renueva Grupo anual', () {
      expect(
        renewalProductId(
            tiersEnabled: true, tier: HomeTier.grupo, cycle: BillingCycle.annual),
        'toka_grupo_annual',
      );
    });

    test('tier desconocido (null) → fallback legacy aunque tiers ON', () {
      // Dashboard antiguo sin tier denormalizado: no podemos resolver el tier,
      // caemos al SKU legacy en vez de adivinar.
      expect(
        renewalProductId(
            tiersEnabled: true, tier: null, cycle: BillingCycle.annual),
        kAnnualProductId,
      );
    });
  });
}
