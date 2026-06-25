import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/subscription/application/member_packs_pricing_provider.dart';
import 'package:toka/features/subscription/application/tier_pricing_provider.dart';
import 'package:toka/features/subscription/domain/member_pack_catalog.dart';

class MockInAppPurchase extends Mock implements InAppPurchase {}

ProductDetails _pd(String id, String price) => ProductDetails(
      id: id,
      title: id,
      description: id,
      price: price,
      rawPrice: 0,
      currencyCode: 'EUR',
    );

ProductDetailsResponse _resp(List<ProductDetails> details) =>
    ProductDetailsResponse(productDetails: details, notFoundIDs: const []);

Future<Map<String, String>> _resolve(InAppPurchase iap) async {
  final container = ProviderContainer(
    overrides: [inAppPurchaseProvider.overrideWithValue(iap)],
  );
  addTearDown(container.dispose);
  return container.read(memberPacksPricingProvider.future);
}

void main() {
  setUpAll(() => registerFallbackValue(<String>{}));

  late MockInAppPurchase iap;
  setUp(() {
    iap = MockInAppPurchase();
    when(() => iap.isAvailable()).thenAnswer((_) async => true);
  });

  test('store devuelve los 4 SKUs de pack → mapa con precios de la store',
      () async {
    when(() => iap.queryProductDetails(any())).thenAnswer(
      (_) async => _resp([
        _pd('toka_pack5_monthly', '1,49 €'),
        _pd('toka_pack5_annual', '9,99 €'),
        _pd('toka_pack10_monthly', '2,49 €'),
        _pd('toka_pack10_annual', '19,99 €'),
      ]),
    );

    final map = await _resolve(iap);

    expect(map, hasLength(4));
    expect(map['toka_pack5_monthly'], '1,49 €');
    expect(map['toka_pack5_annual'], '9,99 €');
    expect(map['toka_pack10_monthly'], '2,49 €');
    expect(map['toka_pack10_annual'], '19,99 €');
  });

  test('store devuelve solo algunos → solo esos (el resto irá a fallback)',
      () async {
    when(() => iap.queryProductDetails(any())).thenAnswer(
      (_) async => _resp([_pd('toka_pack5_annual', '9,99 €')]),
    );

    final map = await _resolve(iap);

    expect(map, hasLength(1));
    expect(map.containsKey('toka_pack5_annual'), isTrue);
    expect(map.containsKey('toka_pack10_annual'), isFalse);
  });

  test('filtra productos ajenos a los packs (p. ej. SKUs de tier)', () async {
    when(() => iap.queryProductDetails(any())).thenAnswer(
      (_) async => _resp([
        _pd('toka_pack10_monthly', '2,49 €'),
        _pd('toka_grupo_annual', '49,99 €'),
      ]),
    );

    final map = await _resolve(iap);

    expect(map, hasLength(1));
    expect(map.containsKey('toka_pack10_monthly'), isTrue);
    expect(map.containsKey('toka_grupo_annual'), isFalse);
  });

  test('store no disponible → mapa vacío (sin lanzar)', () async {
    when(() => iap.isAvailable()).thenAnswer((_) async => false);
    expect(await _resolve(iap), isEmpty);
  });

  test('queryProductDetails lanza → mapa vacío (sin lanzar)', () async {
    when(() => iap.queryProductDetails(any())).thenThrow(Exception('store error'));
    expect(await _resolve(iap), isEmpty);
  });

  test('consulta exactamente los 4 SKUs de pack', () async {
    when(() => iap.queryProductDetails(any())).thenAnswer((_) async => _resp([]));

    await _resolve(iap);

    final captured = verify(() => iap.queryProductDetails(captureAny()))
        .captured
        .single as Set<String>;
    expect(captured, equals(allMemberPackProductIds));
  });
}
