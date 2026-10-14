import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/offers/offer_import.dart';
import 'package:sparzamapp/features/offers/prospect_regular_price_persistence.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/services/market_price_observation_adapter.dart';
import 'package:sparzamapp/services/price_observation_store.dart';

void main() {
  const coffee = Product(
    id: 'coffee-500',
    name: 'Jacobs Kaffee Crema 500 g',
    unit: '500 g',
    group: 'kaffee',
  );
  final now = DateTime(2026, 10, 12, 12);
  final current = OfferImportRecord(
    sourceId: 'kaufda-coffee-current',
    productLabel: coffee.name,
    storeName: 'Lidl',
    originalPrice: 7.99,
    offerPrice: 4.99,
    validFrom: DateTime(2026, 10, 10),
    validUntil: DateTime(2026, 10, 17),
    source: 'retailerWebsite',
    sourceAdapter: 'kaufda',
    branchId: 'lidl-branch-1',
    proofRef: 'https://example.test/kaufda/coffee',
    capturedAt: now,
  );

  PriceObservationStore memoryStore() {
    var raw = <String>[];
    return PriceObservationStore(
      readRaw: () async => raw,
      writeRaw: (values) async => raw = [...values],
    );
  }

  test('stores only the current regular prospect price and projects it', () async {
    final store = memoryStore();
    final result = await persistCurrentProspectRegularPrices(
      store: store,
      records: [current],
      catalogProducts: const [coffee],
      observedAt: now,
      now: now,
    );

    expect(result.learned, hasLength(1));
    expect(result.learned.single.kind, PriceObservationKind.regular);
    expect(result.learned.single.price, 7.99);
    expect(result.learned.single.storeName, 'Lidl');
    expect(result.learned.single.locationId, 'lidl-branch-1');
    expect(result.learned.single.proofRef, current.proofRef);
    expect(result.stored, hasLength(1));
    expect(result.stored.single.kind, PriceObservationKind.regular);
    expect(result.stored.single.discounted, isFalse);

    final projected = marketPricesFromObservations(
      result.stored,
      products: const [coffee],
      now: now,
    );
    expect(projected, hasLength(1));
    expect(projected.single.source, MarketPriceSource.prospect);
    expect(projected.single.price, 7.99);
    expect(projected.single.kind, PriceObservationKind.regular);
  });

  test('filters offers and invalid periods and deduplicates refreshes', () async {
    final store = memoryStore();
    final offerOnly = current.copyWith(
      sourceId: 'offer-only',
      originalPrice: null,
    );
    final expired = current.copyWith(
      sourceId: 'expired',
      validFrom: DateTime(2026, 10, 1),
      validUntil: DateTime(2026, 10, 11),
    );
    final future = current.copyWith(
      sourceId: 'future',
      validFrom: DateTime(2026, 10, 13),
    );

    final first = await persistCurrentProspectRegularPrices(
      store: store,
      records: [current, offerOnly, expired, future],
      catalogProducts: const [coffee],
      observedAt: now,
      now: now,
    );
    final second = await persistCurrentProspectRegularPrices(
      store: store,
      records: [current],
      catalogProducts: const [coffee],
      observedAt: now,
      now: now,
    );

    expect(first.learned, hasLength(1));
    expect(first.learned.single.sourceAdapter, 'kaufda');
    expect(first.stored, hasLength(1));
    expect(second.learned, hasLength(1));
    expect(second.stored, hasLength(1));
    expect(second.stored.single.id, first.stored.single.id);
    expect(second.stored.single.price, 7.99);
  });

  test('does not persist without a feed timestamp', () async {
    final store = memoryStore();
    final result = await persistCurrentProspectRegularPrices(
      store: store,
      records: [current],
      catalogProducts: const [coffee],
      now: now,
    );

    expect(result.learned, isEmpty);
    expect(result.stored, isEmpty);
  });
}

extension on OfferImportRecord {
  OfferImportRecord copyWith({
    String? sourceId,
    double? originalPrice,
    DateTime? validFrom,
    DateTime? validUntil,
  }) =>
      OfferImportRecord(
        sourceId: sourceId ?? this.sourceId,
        productLabel: productLabel,
        storeName: storeName,
        originalPrice: originalPrice ?? this.originalPrice,
        offerPrice: offerPrice,
        validUntil: validUntil ?? this.validUntil,
        validFrom: validFrom ?? this.validFrom,
        source: source,
        proofRef: proofRef,
        packageSize: packageSize,
        sourceAdapter: sourceAdapter,
        regionalOnly: regionalOnly,
        brochureId: brochureId,
        brochurePage: brochurePage,
        publisherId: publisherId,
        capturedAt: capturedAt,
        branchId: branchId,
        location: location,
        address: address,
      );
}
