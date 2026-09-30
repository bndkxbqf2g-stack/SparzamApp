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
    expect(
      shoppingSuggestionPriceForProduct(
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
      )?.displayLabel,
      contains('Bon-Median ALDI Süd 0,95 €'),
    );
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
}
