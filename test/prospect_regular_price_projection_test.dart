import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/services/market_price_observation_adapter.dart';
import 'package:sparzamapp/models/price_observation.dart';
import 'package:sparzamapp/models/market_price.dart';

void main() {
  final now = DateTime(2026, 10, 14, 12);

  test('projects a current regular prospect observation as a prospect price', () {
    final observation = PriceObservation(
      id: 'prospect|leaflet|lidl|coffee|regular',
      productId: 'coffee-500',
      storeName: 'Lidl',
      locationId: 'lidl-branch-1',
      price: 6.99,
      observedAt: DateTime(2026, 10, 14, 8),
      source: PriceObservationSource.leaflet,
      kind: PriceObservationKind.regular,
      validFrom: DateTime(2026, 10, 12),
      validUntil: DateTime(2026, 10, 17),
      proofRef: 'https://example.test/lidl/coffee',
    );

    final projected = marketPricesFromObservations([observation], now: now);

    expect(projected, hasLength(1));
    expect(projected.single.source, MarketPriceSource.prospect);
    expect(projected.single.sourceLabel, 'Prospekt');
    expect(projected.single.price, 6.99);
    expect(
      projected.single.isUsable(now: now, openPricesMaxAgeDays: 60),
      isTrue,
    );
  });

  test('does not project a prospect offer observation into a regular price', () {
    final observation = PriceObservation(
      id: 'prospect|leaflet|lidl|coffee|offer',
      productId: 'coffee-500',
      storeName: 'Lidl',
      price: 4.99,
      observedAt: DateTime(2026, 10, 14, 8),
      source: PriceObservationSource.leaflet,
      kind: PriceObservationKind.offer,
      validFrom: DateTime(2026, 10, 12),
      validUntil: DateTime(2026, 10, 17),
      proofRef: 'https://example.test/lidl/coffee',
    );

    expect(marketPricesFromObservations([observation], now: now), isEmpty);
  });
  test('rejects a legacy prospect offer from the current basis', () {
    final price = MarketPrice(
      productId: 'coffee-500',
      storeName: 'Lidl',
      sourceLocationId: 'lidl-branch-1',
      price: 4.99,
      updatedAt: now,
      source: MarketPriceSource.prospect,
      kind: PriceObservationKind.offer,
      discounted: true,
    );

    expect(price.isProspectOffer, isTrue);
    expect(
      price.isUsable(now: now, openPricesMaxAgeDays: 60),
      isFalse,
    );
  });
  test('keeps a branchless prospect regular price as history only', () {
    final observation = PriceObservation(
      id: 'prospect|leaflet|lidl|coffee|branchless',
      productId: 'coffee-500',
      storeName: 'Lidl',
      price: 6.99,
      observedAt: DateTime(2026, 10, 14, 8),
      source: PriceObservationSource.leaflet,
      kind: PriceObservationKind.regular,
      validFrom: DateTime(2026, 10, 12),
      validUntil: DateTime(2026, 10, 17),
      proofRef: 'https://example.test/lidl/coffee',
    );

    expect(marketPricesFromObservations([observation], now: now), isEmpty);
  });

  test(
    'keeps only the newest current regular claim for an exact branch slot',
    () {
      final olderPeriod = PriceObservation(
        id: 'prospect|leaflet|lidl|coffee|older-period',
        productId: 'coffee-500',
        storeName: 'Lidl',
        locationId: 'lidl-branch-1',
        price: 7.99,
        observedAt: DateTime(2026, 10, 14, 8),
        source: PriceObservationSource.leaflet,
        sourceAdapter: 'kaufda',
        kind: PriceObservationKind.regular,
        validFrom: DateTime(2026, 10, 12),
        validUntil: DateTime(2026, 10, 20),
        proofRef: 'https://example.test/lidl/older',
      );
      final newerPeriod = PriceObservation(
        id: 'prospect|leaflet|lidl|coffee|newer-period',
        productId: 'coffee-500',
        storeName: 'Lidl',
        locationId: 'lidl-branch-1',
        price: 8.49,
        observedAt: DateTime(2026, 10, 15, 8),
        source: PriceObservationSource.leaflet,
        sourceAdapter: 'kaufda',
        kind: PriceObservationKind.regular,
        validFrom: DateTime(2026, 10, 15),
        validUntil: DateTime(2026, 10, 22),
        proofRef: 'https://example.test/lidl/newer',
      );
      final otherBranch = PriceObservation(
        id: 'prospect|leaflet|lidl|coffee|other-branch',
        productId: 'coffee-500',
        storeName: 'Lidl',
        locationId: 'lidl-branch-2',
        price: 6.49,
        observedAt: DateTime(2026, 10, 15, 8),
        source: PriceObservationSource.leaflet,
        sourceAdapter: 'kaufda',
        kind: PriceObservationKind.regular,
        validFrom: DateTime(2026, 10, 15),
        validUntil: DateTime(2026, 10, 22),
        proofRef: 'https://example.test/lidl/other',
      );

      final projected = marketPricesFromObservations(
        [olderPeriod, newerPeriod, otherBranch],
        now: DateTime(2026, 10, 16, 12),
      );

      expect(projected, hasLength(2));
      final branchOne = projected.singleWhere(
        (price) => price.sourceLocationId == 'lidl-branch-1',
      );
      expect(branchOne.price, 8.49);
      expect(branchOne.proofRef, 'https://example.test/lidl/newer');
      expect(
        projected.where(
          (price) => price.sourceLocationId == 'lidl-branch-2',
        ),
        hasLength(1),
      );
    },
  );

}
