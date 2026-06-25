import 'package:flutter_test/flutter_test.dart';
import 'package:toka/shared/widgets/ad_visibility_provider.dart';

void main() {
  group('computeAdVisibility — 5 filas de la matriz', () {
    test('Fila 1: Free, sin Plus → banner sí, intersticial sí', () {
      final v = computeAdVisibility(
        homeIsPremium: false,
        isPayer: false,
        hasPlus: false,
      );
      expect(v.banner, isTrue);
      expect(v.interstitial, isTrue);
    });

    test('Fila 2: Free, con Plus → banner no, intersticial no', () {
      final v = computeAdVisibility(
        homeIsPremium: false,
        isPayer: false,
        hasPlus: true,
      );
      expect(v.banner, isFalse);
      expect(v.interstitial, isFalse);
    });

    test('Fila 3: Premium, pagador → banner no, intersticial no', () {
      final v = computeAdVisibility(
        homeIsPremium: true,
        isPayer: true,
        hasPlus: false,
      );
      expect(v.banner, isFalse);
      expect(v.interstitial, isFalse);
    });

    test('Fila 4: Premium, miembro sin Plus → banner sí, intersticial no', () {
      final v = computeAdVisibility(
        homeIsPremium: true,
        isPayer: false,
        hasPlus: false,
      );
      expect(v.banner, isTrue);
      expect(v.interstitial, isFalse);
    });

    test('Fila 5: Premium, miembro con Plus → banner no, intersticial no', () {
      final v = computeAdVisibility(
        homeIsPremium: true,
        isPayer: false,
        hasPlus: true,
      );
      expect(v.banner, isFalse);
      expect(v.interstitial, isFalse);
    });
  });

  group('computeAdVisibility — combinaciones cruzadas', () {
    test('Premium + pagador + Plus → ambos no (Plus y pagador refuerzan)', () {
      final v = computeAdVisibility(
        homeIsPremium: true,
        isPayer: true,
        hasPlus: true,
      );
      expect(v.banner, isFalse);
      expect(v.interstitial, isFalse);
    });

    test(
        'Free + "pagador"=true (degenerado, sin Plus) → banner sí, intersticial sí '
        '(solo el pagador de un hogar PREMIUM pierde banner)', () {
      final v = computeAdVisibility(
        homeIsPremium: false,
        isPayer: true,
        hasPlus: false,
      );
      expect(v.banner, isTrue);
      expect(v.interstitial, isTrue);
    });

    test('Free + "pagador"=true + Plus → ambos no (Plus manda)', () {
      final v = computeAdVisibility(
        homeIsPremium: false,
        isPayer: true,
        hasPlus: true,
      );
      expect(v.banner, isFalse);
      expect(v.interstitial, isFalse);
    });
  });

  group('computeAdVisibility — reglas invariantes', () {
    test('regla intersticial: visible ⇔ NO premium ∧ NO Plus', () {
      for (final premium in [false, true]) {
        for (final payer in [false, true]) {
          for (final plus in [false, true]) {
            final v = computeAdVisibility(
              homeIsPremium: premium,
              isPayer: payer,
              hasPlus: plus,
            );
            expect(v.interstitial, equals(!premium && !plus),
                reason: 'premium=$premium payer=$payer plus=$plus');
          }
        }
      }
    });

    test('regla banner: visible ⇔ NO Plus ∧ NO (premium ∧ pagador)', () {
      for (final premium in [false, true]) {
        for (final payer in [false, true]) {
          for (final plus in [false, true]) {
            final v = computeAdVisibility(
              homeIsPremium: premium,
              isPayer: payer,
              hasPlus: plus,
            );
            expect(v.banner, equals(!plus && !(premium && payer)),
                reason: 'premium=$premium payer=$payer plus=$plus');
          }
        }
      }
    });

    test('cada "tier" Premium colapsa en homeIsPremium=true: '
        'pagador→sin banner, miembro→con banner (sin Plus)', () {
      // El modelo no distingue tier en la función pura: cualquier Premium es
      // homeIsPremium=true. Verificamos las dos posiciones (pagador/miembro).
      final payer = computeAdVisibility(
          homeIsPremium: true, isPayer: true, hasPlus: false);
      final member = computeAdVisibility(
          homeIsPremium: true, isPayer: false, hasPlus: false);
      expect(payer.banner, isFalse);
      expect(member.banner, isTrue);
      expect(payer.interstitial, isFalse);
      expect(member.interstitial, isFalse);
    });
  });
}
