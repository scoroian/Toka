import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:toka/features/subscription/application/intro_offer_parser.dart';
import 'package:toka/features/subscription/domain/intro_offer.dart';

void main() {
  group('iso8601PeriodToDays (Google Play billingPeriod)', () {
    test('días, semanas, meses y años', () {
      expect(iso8601PeriodToDays('P14D'), 14);
      expect(iso8601PeriodToDays('P3D'), 3);
      expect(iso8601PeriodToDays('P1W'), 7);
      expect(iso8601PeriodToDays('P2W'), 14);
      expect(iso8601PeriodToDays('P1M'), 30);
      expect(iso8601PeriodToDays('P1Y'), 365);
    });

    test('formato no reconocido → 0', () {
      expect(iso8601PeriodToDays(''), 0);
      expect(iso8601PeriodToDays('basura'), 0);
      expect(iso8601PeriodToDays('14'), 0);
    });

    test('tolera espacios alrededor', () {
      expect(iso8601PeriodToDays(' P14D '), 14);
    });
  });

  group('extractIntroOffer', () {
    test('ProductDetails genérico (no plataforma) → IntroOffer.none', () {
      final generic = ProductDetails(
        id: 'toka_premium_annual',
        title: 'Anual',
        description: 'Plan anual',
        price: '29,99 €',
        rawPrice: 29.99,
        currencyCode: 'EUR',
      );
      expect(extractIntroOffer(generic), IntroOffer.none);
    });
  });

  group('IntroOffer', () {
    test('hasFreeTrial refleja freeTrialDays', () {
      expect(const IntroOffer(freeTrialDays: 14).hasFreeTrial, isTrue);
      expect(IntroOffer.none.hasFreeTrial, isFalse);
      expect(const IntroOffer(freeTrialDays: 0).hasFreeTrial, isFalse);
    });

    test('igualdad por días', () {
      expect(const IntroOffer(freeTrialDays: 14),
          const IntroOffer(freeTrialDays: 14));
      expect(const IntroOffer(freeTrialDays: 7) == IntroOffer.none, isFalse);
    });
  });
}
