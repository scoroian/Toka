import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/subscription/application/plus_pricing_provider.dart';
import 'package:toka/features/subscription/application/tier_pricing_provider.dart';
import 'package:toka/features/subscription/domain/subscription_products.dart';

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
  return container.read(plusPricingProvider.future);
}

void main() {
  setUpAll(() => registerFallbackValue(<String>{}));

  late MockInAppPurchase iap;
  setUp(() {
    iap = MockInAppPurchase();
    when(() => iap.isAvailable()).thenAnswer((_) async => true);
  });

  test('store devuelve ambos SKUs Plus → mapa con precios de la store', () async {
    when(() => iap.queryProductDetails(any())).thenAnswer(
      (_) async => _resp([
        _pd(kPlusMonthlyProductId, '1,99 €'),
        _pd(kPlusAnnualProductId, '14,99 €'),
      ]),
    );

    final map = await _resolve(iap);

    expect(map, hasLength(2));
    expect(map[kPlusMonthlyProductId]!.price, '1,99 €');
    expect(map[kPlusAnnualProductId]!.price, '14,99 €');
  });

  test('store devuelve solo el mensual → solo ese SKU (fallback del resto)',
      () async {
    when(() => iap.queryProductDetails(any())).thenAnswer(
      (_) async => _resp([_pd(kPlusMonthlyProductId, '1,99 €')]),
    );

    final map = await _resolve(iap);

    expect(map, hasLength(1));
    expect(map.containsKey(kPlusMonthlyProductId), isTrue);
    expect(map.containsKey(kPlusAnnualProductId), isFalse);
  });

  test('filtra productos ajenos a Plus', () async {
    when(() => iap.queryProductDetails(any())).thenAnswer(
      (_) async => _resp([
        _pd(kPlusAnnualProductId, '14,99 €'),
        _pd('toka_premium_annual', '29,99 €'),
      ]),
    );

    final map = await _resolve(iap);

    expect(map, hasLength(1));
    expect(map.containsKey(kPlusAnnualProductId), isTrue);
    expect(map.containsKey('toka_premium_annual'), isFalse);
  });

  test('store no disponible → mapa vacío (sin lanzar)', () async {
    when(() => iap.isAvailable()).thenAnswer((_) async => false);
    expect(await _resolve(iap), isEmpty);
  });

  test('queryProductDetails lanza → mapa vacío (sin lanzar)', () async {
    when(() => iap.queryProductDetails(any())).thenThrow(Exception('store error'));
    expect(await _resolve(iap), isEmpty);
  });

  test('consulta exactamente los 2 SKUs de Plus', () async {
    when(() => iap.queryProductDetails(any())).thenAnswer((_) async => _resp([]));

    await _resolve(iap);

    final captured = verify(() => iap.queryProductDetails(captureAny()))
        .captured
        .single as Set<String>;
    expect(captured, equals(kPlusProductIds));
  });
}
