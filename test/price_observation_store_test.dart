import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/price_observation.dart';
import 'package:sparzamapp/services/market_price_observation_adapter.dart';
import 'package:sparzamapp/services/price_observation_store.dart';
import 'package:sparzamapp/features/route/market_price_quality.dart';

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty());
  tearDown(() => SharedPreferencesAsyncPlatform.instance = null);

  test('distinct prices persist, repeated imports are idempotent', () async {
    final store = PriceObservationStore();
    final older = observationFromMarketPrice(MarketPrice(
      productId: 'generic', storeName: 'Lidl', price: 0.79,
      updatedAt: DateTime(2026, 9, 1),
    ));
    final newer = observationFromMarketPrice(MarketPrice(
      productId: 'generic', storeName: 'Lidl', price: 0.89,
      updatedAt: DateTime(2026, 9, 24),
    ));
    await Future.wait([store.append([older]), store.append([newer])]);
    await store.append([older, newer]);
    final saved = await PriceObservationStore().load();
    expect(saved, hasLength(2));
    expect(saved.map((item) => item.price), containsAll([0.79, 0.89]));
  });

  test('record keeps branch, amount, offer validity and proof separately', () {
    final original = PriceObservation(
      id: 'shelf-1', productId: 'milk-15', familyKey: 'milch',
      variant: '1,5 %', ean: '4000000000001', storeName: 'Lidl',
      locationId: 'store-7', region: 'Zellingen', price: 1.09,
      quantity: 1, unit: 'l', unitPrice: 1.09,
      kind: PriceObservationKind.offer,
      validFrom: DateTime(2026, 9, 21),
      validUntil: DateTime(2026, 9, 27),
      observedAt: DateTime(2026, 9, 24),
      source: PriceObservationSource.shelfImage,
      identityConfidence: 0.9, proofRef: 'local-photo-7',
    );
    final restored = PriceObservation.fromJson(original.toJson());
    expect(restored.ean, original.ean);
    expect(restored.locationId, 'store-7');
    expect(restored.validUntil, DateTime(2026, 9, 27));
    expect(restored.proofRef, 'local-photo-7');
    expect(restored.identityConfidence, 0.9);
  });

  test('exact observation history projects every supported price for routing', () {
    final projected = marketPricesFromObservations([
      PriceObservation(
        id: 'old', productId: 'schmand', storeName: 'Lidl', price: 0.79,
        observedAt: DateTime(2026, 8, 1),
        source: PriceObservationSource.manual,
      ),
      PriceObservation(
        id: 'new', productId: 'schmand', storeName: 'Lidl', price: 0.89,
        observedAt: DateTime(2026, 9, 24),
        source: PriceObservationSource.openPrices,
        proofRef: 'open-prices:42',
      ),
    ]);

    expect(projected, hasLength(2));
    expect(projected.map((item) => item.price), containsAll([0.79, 0.89]));
    expect(projected.last.externalId, 42);
  });

  test('family-only or uncertain identity is not projected as exact route price', () {
    final projected = marketPricesFromObservations([
      PriceObservation(
        id: 'family', familyKey: 'schmand', storeName: 'Lidl', price: 0.69,
        observedAt: DateTime(2026, 9, 24),
        source: PriceObservationSource.manual,
      ),
      PriceObservation(
        id: 'uncertain', productId: 'schmand', storeName: 'Lidl', price: 0.59,
        observedAt: DateTime(2026, 9, 24),
        source: PriceObservationSource.manual, identityConfidence: 0.8,
      ),
    ]);

    expect(projected, isEmpty);
  });

  test('source confidence and age confidence are separate', () {
    final old = MarketPrice(productId: 'x', storeName: 'Lidl',
        price: 0.79, updatedAt: DateTime(2026, 7, 23),
        source: MarketPriceSource.receipt, discounted: true);
    final quality = marketPriceQuality(old, DateTime(2026, 9, 24));
    expect(quality.sourceRate, 0.05);
    expect(quality.ageRate, 0.20);
    expect(quality.discountRate, 0.10);
    expect(quality.confidence, closeTo(0.65, 0.00001));
  });
}
