import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/subscription/application/tier_pricing_provider.dart';
import 'package:toka/features/subscription/domain/tier_catalog.dart';

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

Future<Map<String, TierProductInfo>> _resolve(InAppPurchase iap) async {
  final container = ProviderContainer(
    overrides: [inAppPurchaseProvider.overrideWithValue(iap)],
  );
  addTearDown(container.dispose);
  return container.read(tierPricingProvider.future);
}

void main() {
  setUpAll(() {
    registerFallbackValue(<String>{});
  });

  late MockInAppPurchase iap;

  setUp(() {
    iap = MockInAppPurchase();
    when(() => iap.isAvailable()).thenAnswer((_) async => true);
  });

  test('store devuelve los 6 SKUs → mapa con precios localizados de la store',
      () async {
    when(() => iap.queryProductDetails(any())).thenAnswer(
      (_) async => _resp([
        _pd('toka_pareja_monthly', '2,99 €'),
        _pd('toka_pareja_annual', '19,99 €'),
        _pd('toka_familia_monthly', '3,99 €'),
        _pd('toka_familia_annual', '29,99 €'),
        _pd('toka_grupo_monthly', '5,99 €'),
        _pd('toka_grupo_annual', '49,99 €'),
      ]),
    );

    final map = await _resolve(iap);

    expect(map, hasLength(6));
    expect(map[productIdFor(HomeTier.pareja, BillingCycle.monthly)]!.price,
        '2,99 €');
    expect(map[productIdFor(HomeTier.grupo, BillingCycle.annual)]!.price,
        '49,99 €');
  });

  test('store devuelve un subconjunto → solo esos SKUs (consumidor hará fallback)',
      () async {
    when(() => iap.queryProductDetails(any())).thenAnswer(
      (_) async => _resp([
        _pd('toka_familia_monthly', '3,99 €'),
        _pd('toka_familia_annual', '29,99 €'),
      ]),
    );

    final map = await _resolve(iap);

    expect(map, hasLength(2));
    expect(map.containsKey('toka_familia_monthly'), isTrue);
    expect(map.containsKey('toka_pareja_monthly'), isFalse);
  });

  test('filtra productos ajenos al catálogo de tiers', () async {
    when(() => iap.queryProductDetails(any())).thenAnswer(
      (_) async => _resp([
        _pd('toka_pareja_monthly', '2,99 €'),
        _pd('un_producto_ajeno', '9,99 €'),
      ]),
    );

    final map = await _resolve(iap);

    expect(map, hasLength(1));
    expect(map.containsKey('toka_pareja_monthly'), isTrue);
    expect(map.containsKey('un_producto_ajeno'), isFalse);
  });

  test('store no disponible → mapa vacío (sin lanzar)', () async {
    when(() => iap.isAvailable()).thenAnswer((_) async => false);

    final map = await _resolve(iap);

    expect(map, isEmpty);
  });

  test('queryProductDetails lanza → mapa vacío (sin lanzar)', () async {
    when(() => iap.queryProductDetails(any()))
        .thenThrow(Exception('store error'));

    final map = await _resolve(iap);

    expect(map, isEmpty);
  });

  test('consulta exactamente los 6 SKUs de tier', () async {
    when(() => iap.queryProductDetails(any())).thenAnswer((_) async => _resp([]));

    await _resolve(iap);

    final captured =
        verify(() => iap.queryProductDetails(captureAny())).captured.single
            as Set<String>;
    expect(captured, equals(allTierProductIds));
  });

  test('un ProductDetails plano (ni Google ni Apple) → introOffer sin trial',
      () async {
    when(() => iap.queryProductDetails(any())).thenAnswer(
      (_) async => _resp([_pd('toka_pareja_annual', '19,99 €')]),
    );

    final map = await _resolve(iap);

    expect(map['toka_pareja_annual']!.introOffer.hasFreeTrial, isFalse);
  });
}
