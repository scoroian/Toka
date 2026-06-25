import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/subscription/domain/member_pack_catalog.dart';
import 'package:toka/features/subscription/domain/tier_catalog.dart';
import 'package:toka/features/subscription/presentation/pack_display.dart';
import 'package:toka/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations l10n;
  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('es'));
  });

  group('packFallbackPrice / packDisplayPrice', () {
    test('sin store usa los precios fallback (ARB) por pack×ciclo', () {
      expect(packDisplayPrice(l10n, MemberPack.plus5, BillingCycle.monthly, const {}),
          '1,49 €');
      expect(packDisplayPrice(l10n, MemberPack.plus5, BillingCycle.annual, const {}),
          '9,99 €');
      expect(packDisplayPrice(l10n, MemberPack.plus10, BillingCycle.monthly, const {}),
          '2,49 €');
      expect(packDisplayPrice(l10n, MemberPack.plus10, BillingCycle.annual, const {}),
          '19,99 €');
    });

    test('el precio de la store gana sobre el fallback', () {
      const store = {'toka_pack5_monthly': r'US$1.99'};
      expect(packDisplayPrice(l10n, MemberPack.plus5, BillingCycle.monthly, store),
          r'US$1.99');
      // Un SKU no resuelto por la store sigue con el fallback ARB.
      expect(packDisplayPrice(l10n, MemberPack.plus5, BillingCycle.annual, store),
          '9,99 €');
    });
  });

  group('packDisplayName', () {
    test('nombre localizado de cada pack', () {
      expect(packDisplayName(l10n, MemberPack.plus5), 'Pack +5 miembros');
      expect(packDisplayName(l10n, MemberPack.plus10), 'Pack +10 miembros');
    });
  });
}
