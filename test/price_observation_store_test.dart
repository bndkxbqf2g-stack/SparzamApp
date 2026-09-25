import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/price_observation.dart';
import 'package:sparzamapp/services/market_price_observation_adapter.dart';
import 'package:sparzamapp/services/price_observation_store.dart';
import 'package:sparzamapp/services/price_observation_adapters.dart';
import 'package:sparzamapp/models/receipt_observation.dart';
import 'package:sparzamapp/models/offer.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/price_data_settings.dart';
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

  test('receipt adapter preserves quantity and family without faking identity', () {
    final observation = observationFromReceipt(ReceiptObservation(
      id: 'r1', receiptFingerprint: 'fp', rowLine: 1,
      rawLabel: 'SCHMAND 200G', familyKey: 'schmand',
      storeName: 'Lidl', observedAt: DateTime(2026, 9, 24),
      totalPrice: 0.69, quantity: 200, quantityUnit: 'g',
      unitPrice: 3.45, discounted: false,
    ));
    expect(observation.familyKey, 'schmand');
    expect(observation.quantity, 200);
    expect(observation.identityConfidence, 0);
  });

  test('receipt product id alone does not create exact identity confidence', () {
    final automatic = observationFromReceipt(ReceiptObservation(
      id: 'r-auto', receiptFingerprint: 'fp-auto', rowLine: 1,
      rawLabel: 'Unbekannte Spezialität', familyKey: 'unbekannte spezialitaet',
      storeName: 'Lidl', observedAt: DateTime(2026, 9, 24),
      totalPrice: 2.49, quantity: null, quantityUnit: 'Stück',
      unitPrice: null, discounted: false,
      productId: 'receipt_auto_specialitaet',
    ));
    final confirmed = observationFromReceipt(ReceiptObservation(
      id: 'r-confirmed', receiptFingerprint: 'fp-confirmed', rowLine: 1,
      rawLabel: 'Schmand', familyKey: 'schmand',
      storeName: 'Lidl', observedAt: DateTime(2026, 9, 24),
      totalPrice: 0.69, quantity: null, quantityUnit: 'Stück',
      unitPrice: null, discounted: false,
      productId: 'schmand', identityConfirmed: true,
    ));

    expect(automatic.productId, 'receipt_auto_specialitaet');
    expect(automatic.identityConfidence, 0);
    expect(confirmed.identityConfidence, 1);
  });

  test('legacy automatic receipt ids migrate as unconfirmed', () {
    final restored = ReceiptObservation.fromJson({
      'id': 'legacy',
      'receiptFingerprint': 'legacy-fp',
      'rowLine': 1,
      'rawLabel': 'Unbekannte Spezialität',
      'familyKey': 'unbekannte spezialitaet',
      'storeName': 'Lidl',
      'observedAt': '2026-09-24T00:00:00.000',
      'totalPrice': 2.49,
      'quantity': null,
      'quantityUnit': 'Stück',
      'unitPrice': null,
      'discounted': false,
      'productId': 'receipt_auto_specialitaet',
    });

    expect(restored.identityConfirmed, isFalse);
    expect(observationFromReceipt(restored).identityConfidence, 0);
  });

  test('legacy receipt price observations default to unconfirmed identity', () {
    final restored = PriceObservation.fromJson({
      'id': 'receipt|legacy',
      'productId': 'schmand',
      'familyKey': 'schmand',
      'storeName': 'Lidl',
      'price': 0.69,
      'observedAt': '2026-09-24T00:00:00.000',
      'source': 'receipt',
    });

    expect(restored.identityConfidence, 0);
    expect(marketPricesFromObservations([restored]), isEmpty);
  });

  test('legacy non-receipt price observations keep exact identity', () {
    final restored = PriceObservation.fromJson({
      'id': 'manual|legacy',
      'productId': 'schmand',
      'storeName': 'Lidl',
      'price': 0.79,
      'observedAt': '2026-09-24T00:00:00.000',
      'source': 'manual',
    });

    expect(restored.identityConfidence, 1);
    expect(marketPricesFromObservations([restored]), hasLength(1));
  });

  test('offer adapter carries validity into observation', () {
    final observation = observationFromOffer(
      Offer(id: 'o1', productId: 'schmand', storeName: 'Lidl',
        originalPrice: 0.89, offerPrice: 0.69,
        validUntil: DateTime(2026, 9, 27)),
      observedAt: DateTime(2026, 9, 24),
    );
    expect(observation.kind, PriceObservationKind.offer);
    expect(observation.validUntil, DateTime(2026, 9, 27));
    expect(observation.discounted, isTrue);
  });

  test('leaflet preserves regular price as separate evidence', () {
    final offer = Offer(
      id: 'leaflet-1', productId: 'chocolate', storeName: 'Lidl',
      originalPrice: 2.19, offerPrice: 1.99,
      validFrom: DateTime(2026, 9, 25),
      validUntil: DateTime(2026, 9, 26),
      source: 'leaflet', proofRef: 'leaflet:lidl:2026-09-25:p1',
    );
    final regular = regularObservationFromOffer(
      offer, observedAt: DateTime(2026, 9, 25),
    );
    final discounted = observationFromOffer(
      offer, observedAt: DateTime(2026, 9, 25),
    );

    expect(regular.price, 2.19);
    expect(regular.kind, PriceObservationKind.regular);
    expect(regular.source, PriceObservationSource.leaflet);
    expect(regular.proofRef, offer.proofRef);
    expect(discounted.price, 1.99);
    expect(discounted.kind, PriceObservationKind.offer);
    expect(discounted.validFrom, DateTime(2026, 9, 25));
    expect(discounted.source, PriceObservationSource.leaflet);
  });

  test('exact route projection rejects a different declared package size', () {
    const product = Product(
      id: 'schmand-200', name: 'Schmand 200 g', unit: '200 g',
      group: 'schmand', packageAmount: 200, packageUnit: 'g',
    );
    final projected = marketPricesFromObservations([
      PriceObservation(
        id: 'wrong-pack', productId: product.id, storeName: 'Lidl',
        price: 0.69, quantity: 500, unit: 'g',
        observedAt: DateTime(2026, 9, 24),
        source: PriceObservationSource.receipt,
      ),
      PriceObservation(
        id: 'right-pack', productId: product.id, storeName: 'Edeka',
        price: 0.89, quantity: 0.2, unit: 'kg',
        observedAt: DateTime(2026, 9, 24),
        source: PriceObservationSource.receipt,
      ),
    ], products: const [product]);

    expect(projected, hasLength(1));
    expect(projected.single.storeName, 'Edeka');
  });

  test('disabled Open Prices history cannot re-enter route planning', () {
    final projected = marketPricesFromObservations([
      PriceObservation(
        id: 'open', productId: 'schmand', storeName: 'Lidl', price: 0.69,
        observedAt: DateTime(2026, 9, 24),
        source: PriceObservationSource.openPrices,
      ),
      PriceObservation(
        id: 'manual', productId: 'schmand', storeName: 'Edeka', price: 0.89,
        observedAt: DateTime(2026, 9, 24),
        source: PriceObservationSource.manual,
      ),
    ], settings: const PriceDataSettings(openPricesEnabled: false),
       now: DateTime(2026, 9, 24));

    expect(projected, hasLength(1));
    expect(projected.single.storeName, 'Edeka');
  });

  test('future offer validity cannot enter route planning early', () {
    final projected = marketPricesFromObservations([
      PriceObservation(
        id: 'future-offer', productId: 'schmand', storeName: 'Lidl',
        price: 0.49, observedAt: DateTime(2026, 9, 24),
        validFrom: DateTime(2026, 10, 1),
        validUntil: DateTime(2026, 10, 7),
        source: PriceObservationSource.manual,
        kind: PriceObservationKind.offer,
      ),
    ], now: DateTime(2026, 9, 25));

    expect(projected, isEmpty);
  });

  test('invalid observation cannot bypass store validation into routing', () {
    final projected = marketPricesFromObservations([
      PriceObservation(
        id: 'invalid', productId: 'schmand', storeName: 'Lidl',
        price: -0.49, observedAt: DateTime(2026, 9, 24),
        source: PriceObservationSource.manual,
      ),
    ], now: DateTime(2026, 9, 25));

    expect(projected, isEmpty);
  });

  test('old Open Prices history respects configured maximum age', () {
    final projected = marketPricesFromObservations([
      PriceObservation(
        id: 'old-open', productId: 'schmand', storeName: 'Lidl', price: 0.69,
        observedAt: DateTime(2026, 7, 1),
        source: PriceObservationSource.openPrices,
      ),
    ], settings: const PriceDataSettings(openPricesMaxAgeDays: 30),
       now: DateTime(2026, 9, 24));

    expect(projected, isEmpty);
  });


  test('old exact receipt history is excluded from route price projection', () {
    final projected = marketPricesFromObservations([
      PriceObservation(
        id: 'old-receipt',
        productId: 'schmand',
        storeName: 'Lidl',
        price: 0.69,
        observedAt: DateTime(2026, 8, 24),
        source: PriceObservationSource.receipt,
      ),
    ], now: DateTime(2026, 9, 25));

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
