import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/shopping_list/shopping_suggestions.dart';
import 'package:sparzamapp/features/offers/prospect_price_statistics.dart';
import 'package:sparzamapp/models/price_observation.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/offer.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/recent_purchase.dart';
import 'package:sparzamapp/models/receipt_price_stat.dart';

void main() {
  const regular = Product(
    id: 'milk-35',
    name: 'Vollmilch 3,5 %',
    unit: '1 l',
    group: 'milch',
    isFavorite: true,
  );
  const lowFat = Product(
    id: 'milk-15',
    name: 'Milch 1,5 %',
    unit: '1 l',
    group: 'milch',
  );
  final now = DateTime(2026, 9, 30);

  test('generic staple suggestions rank the lowest current offer first', () {
    final results = buildSuggestions(
      query: 'Milch',
      knownItems: [
        RecentPurchase(
          id: 'milk-35',
          name: 'Vollmilch 3,5 %',
          unit: '1 l',
          group: 'milch',
          purchaseCount: 12,
        ),
      ],
      recentPurchases: const [],
      preferredProductByGroup: const {'milch': 'milk-35'},
      catalogProducts: [regular, lowFat],
      offers: [
        Offer(
          id: 'aldi-sale',
          productId: lowFat.id,
          storeName: 'ALDI Süd',
          originalPrice: 1.49,
          offerPrice: 0.95,
          validFrom: DateTime(2026, 9, 28),
          validUntil: DateTime(2026, 10, 2),
          source: 'leaflet',
          proofRef: 'https://example.test/aldi/milk',
        ),
      ],
      enabledStores: const ['ALDI Süd', 'Lidl'],
      now: now,
    );

    expect(results.map((product) => product.id), [lowFat.id, regular.id]);
    expect(
      shoppingSuggestionPriceForProduct(
        results.first,
        offers: [
          Offer(
            id: 'aldi-sale',
            productId: lowFat.id,
            storeName: 'ALDI Süd',
            originalPrice: 1.49,
            offerPrice: 0.95,
            validUntil: DateTime(2026, 10, 2),
          ),
        ],
        enabledStores: const ['ALDI Süd'],
        now: now,
      )?.displayLabel,
      contains('Angebot ALDI Süd 0,95 €'),
    );
  });

  test('generic potato search keeps plain potatoes before wedges', () {
    final results = buildSuggestions(
      query: 'Kartoffeln 2,5Kg',
      knownItems: const [],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: const [
        Product(
          id: 'wedges',
          name: 'Kartoffel-Wedges',
          unit: '750 g',
          group: 'tiefkuehl',
          aliases: ['kartoffeln'],
        ),
        Product(
          id: 'plain',
          name: 'Kartoffeln',
          unit: '2 kg',
          group: 'obst_gemuese',
          aliases: ['kartoffel'],
        ),
      ],
      now: now,
    );

    expect(results.map((product) => product.id), ['plain', 'wedges']);
  });

  test(
    'ambiguous H-milk label offers both fat choices without merging them',
    () {
      final results = buildSuggestions(
        query: 'K.H-Milch',
        knownItems: const [],
        recentPurchases: const [],
        preferredProductByGroup: const {},
        catalogProducts: [regular, lowFat],
        offers: [
          Offer(
            id: 'synthetic-offer',
            productId: lowFat.id,
            storeName: 'ALDI Süd',
            originalPrice: 1.40,
            offerPrice: 0.95,
            validUntil: DateTime(2026, 10, 2),
          ),
        ],
        now: now,
      );
      expect(results.map((item) => item.id), [lowFat.id, regular.id]);
      expect(results.first.name, 'Milch 1,5 %');
    },
  );

  test('beef mince query never suggests mixed mince as the same item', () {
    final results = buildSuggestions(
      query: 'XXL R.-Hackfleisch',
      knownItems: const [],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: const [
        Product(
          id: 'mixed',
          name: 'Hackfleisch gemischt',
          unit: '500 g',
          group: 'fleisch',
        ),
      ],
      now: now,
    );
    expect(results, isEmpty);
  });

  test(
    'recalled receipt label never receives a family median as its price',
    () {
      const recalled = Product(
        id: 'receipt_suggestion_milk',
        name: 'H-Milch',
        unit: 'Packung',
        group: 'milch',
        aliases: ['K.H-Milch'],
      );
      final hint = shoppingSuggestionPriceForProduct(
        recalled,
        receiptPriceStats: [
          ReceiptPriceStat(
            familyKey: 'milch',
            storeName: 'Kaufland',
            latestPrice: 0.85,
            latestAt: DateTime(2026, 9, 29),
            observationCount: 3,
            medianPrice: 0.85,
            comparable: true,
            priceBasis: 'Packung',
          ),
        ],
        now: now,
      );
      expect(hint, isNull);
    },
  );

  test('receipt median ranks known prices when no active offer exists', () {
    final results = buildSuggestions(
      query: 'Milch',
      knownItems: const [],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: [regular, lowFat],
      receiptPriceStats: [
        ReceiptPriceStat(
          familyKey: 'milch',
          productId: regular.id,
          storeName: 'Lidl',
          latestPrice: 1.49,
          latestAt: DateTime(2026, 9, 29),
          observationCount: 3,
          medianPrice: 1.39,
          comparable: true,
          priceBasis: '1 l',
        ),
        ReceiptPriceStat(
          familyKey: 'milch',
          productId: lowFat.id,
          storeName: 'ALDI Süd',
          latestPrice: 1.05,
          latestAt: DateTime(2026, 9, 29),
          observationCount: 4,
          medianPrice: 0.95,
          comparable: true,
          priceBasis: '1 l',
        ),
      ],
      now: now,
    );

    expect(results.map((product) => product.id), [lowFat.id, regular.id]);
    final hint = shoppingSuggestionPriceForProduct(
      results.first,
      receiptPriceStats: [
        ReceiptPriceStat(
          familyKey: 'milch',
          productId: lowFat.id,
          storeName: 'ALDI Süd',
          latestPrice: 1.05,
          latestAt: DateTime(2026, 9, 29),
          observationCount: 4,
          medianPrice: 0.95,
          comparable: true,
          priceBasis: '1 l',
        ),
      ],
      now: now,
    );
    expect(hint?.isHistorical, isTrue);
    expect(hint?.displayLabel, contains('Bon-Median ALDI Süd 0,95 €'));
    expect(hint?.displayLabel, contains('Stand 29.09.2026'));
  });

  test('stale receipts and disabled-market offers do not rank products', () {
    final hint = shoppingSuggestionPriceForProduct(
      lowFat,
      offers: [
        Offer(
          id: 'disabled',
          productId: lowFat.id,
          storeName: 'Netto',
          originalPrice: 1.49,
          offerPrice: 0.95,
          validUntil: DateTime(2026, 10, 2),
        ),
      ],
      marketPrices: [
        MarketPrice(
          productId: lowFat.id,
          storeName: 'Lidl',
          price: 0.79,
          updatedAt: DateTime(2026, 8, 1),
          source: MarketPriceSource.receipt,
        ),
      ],
      enabledStores: const ['ALDI Süd', 'Lidl'],
      now: now,
    );

    expect(hint, isNull);
  });

  test('active offers outrank cheaper receipt prices for generic staples', () {
    const pastaOffer = Product(
      id: 'pasta-1kg',
      name: 'Penne Nudeln',
      unit: '1 kg',
      group: 'nudeln',
    );
    const pastaReceipt = Product(
      id: 'pasta-500g',
      name: 'Spaghetti',
      unit: '500 g',
      group: 'nudeln',
    );

    final results = buildSuggestions(
      query: 'Nudeln',
      knownItems: const [],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: const [pastaReceipt, pastaOffer],
      offers: [
        Offer(
          id: 'penne-sale',
          productId: pastaOffer.id,
          storeName: 'Lidl',
          originalPrice: 2.5,
          offerPrice: 2.0,
          validUntil: DateTime(2026, 10, 2),
        ),
      ],
      receiptPriceStats: [
        ReceiptPriceStat(
          familyKey: 'nudeln',
          productId: pastaReceipt.id,
          storeName: 'ALDI Süd',
          latestPrice: 0.5,
          latestAt: DateTime(2026, 9, 29),
          observationCount: 3,
          medianPrice: 0.5,
          comparable: true,
          priceBasis: '500 g',
        ),
      ],
      now: now,
    );

    expect(results.map((product) => product.id), [
      pastaOffer.id,
      pastaReceipt.id,
    ]);
  });

  test('offer suggestions compare normalized prices across package sizes', () {
    const pastaOneKg = Product(
      id: 'pasta-1kg',
      name: 'Penne Nudeln',
      unit: '1 kg',
      group: 'nudeln',
    );
    const pastaHalfKg = Product(
      id: 'pasta-500g',
      name: 'Spaghetti',
      unit: '500 g',
      group: 'nudeln',
    );

    final results = buildSuggestions(
      query: 'Nudeln',
      knownItems: const [],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: const [pastaHalfKg, pastaOneKg],
      offers: [
        Offer(
          id: 'penne-sale',
          productId: pastaOneKg.id,
          storeName: 'Lidl',
          originalPrice: 2.5,
          offerPrice: 2.0,
          validUntil: DateTime(2026, 10, 2),
        ),
        Offer(
          id: 'spaghetti-sale',
          productId: pastaHalfKg.id,
          storeName: 'ALDI Süd',
          originalPrice: 1.8,
          offerPrice: 1.25,
          validUntil: DateTime(2026, 10, 2),
        ),
      ],
      now: now,
    );

    expect(results.map((product) => product.id), [
      pastaOneKg.id,
      pastaHalfKg.id,
    ]);
  });

  test(
    'past prospect price is visible as history and does not beat an offer',
    () {
      final history = {
        regular.id: ProspectPriceHistorySummary(
          productId: regular.id,
          storeName: 'Netto',
          medianPrice: 0.49,
          latestValidUntil: DateTime(2026, 9, 27),
          kind: PriceObservationKind.offer,
          observationCount: 3,
        ),
      };
      final results = buildSuggestions(
        query: 'Milch',
        knownItems: const [],
        recentPurchases: const [],
        preferredProductByGroup: const {},
        catalogProducts: const [regular, lowFat],
        prospectPriceHistory: history,
        offers: [
          Offer(
            id: 'current-milk',
            productId: lowFat.id,
            storeName: 'ALDI Süd',
            originalPrice: 1.29,
            offerPrice: 0.95,
            validUntil: DateTime(2026, 10, 3),
          ),
        ],
        now: now,
      );

      expect(results.first.id, lowFat.id);
      expect(
        shoppingSuggestionPriceForProduct(
          regular,
          prospectPriceHistory: history,
          now: now,
        )?.displayLabel,
        contains('Früheres Angebot (Median) Netto 0,49 € · Stand 27.09.2026'),
      );
    },
  );

  test('cheapest enabled historical prospect market is used as the hint', () {
    final history = prospectPriceHistorySummaries([
      PriceObservation(
        id: 'netto-history',
        productId: regular.id,
        storeName: 'Netto',
        price: 1.19,
        quantity: 1,
        unit: 'l',
        observedAt: DateTime(2026, 9, 1),
        source: PriceObservationSource.leaflet,
        kind: PriceObservationKind.offer,
        validUntil: DateTime(2026, 9, 10),
        proofRef: 'https://example.test/netto-history',
      ),
      PriceObservation(
        id: 'lidl-history',
        productId: regular.id,
        storeName: 'Lidl',
        price: 0.89,
        quantity: 1,
        unit: 'l',
        observedAt: DateTime(2026, 9, 1),
        source: PriceObservationSource.leaflet,
        kind: PriceObservationKind.offer,
        validUntil: DateTime(2026, 9, 10),
        proofRef: 'https://example.test/lidl-history',
      ),
    ], now: DateTime(2026, 9, 30));

    final hint = shoppingSuggestionPriceForProduct(
      regular,
      prospectPriceHistory: history,
      enabledStores: const ['Lidl'],
      now: DateTime(2026, 9, 30),
    );

    expect(hint?.storeName, 'Lidl');
    expect(hint?.price, 0.89);
    expect(hint?.isHistorical, isTrue);
  });
}
