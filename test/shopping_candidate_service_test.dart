import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/offers/prospect_price_statistics.dart';
import 'package:sparzamapp/features/shopping_list/shopping_candidate_service.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/offer.dart';
import 'package:sparzamapp/models/price_observation.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/receipt_price_stat.dart';

void main() {
  final gouda = Product(
    id: 'gouda',
    name: 'Gouda jung',
    unit: '250 g',
    group: 'milch',
  );
  final edamer = Product(
    id: 'edamer',
    name: 'Edamer',
    unit: '250 g',
    group: 'milch',
  );
  final bergkaese = Product(
    id: 'bergkaese',
    name: 'Bergkäse',
    unit: '250 g',
    group: 'milch',
  );
  final now = DateTime(2026, 9, 27);

  test('generic cheese returns compatible concrete variants', () {
    final candidates = buildShoppingCandidates(
      request: 'Käse',
      catalogProducts: [gouda, edamer, bergkaese],
      offers: const [],
      marketPrices: const [],
      receiptPriceStats: const [],
      now: now,
    );

    expect(candidates.map((candidate) => candidate.product.id),
        containsAll(<String>['gouda', 'edamer', 'bergkaese']));
  });

  test('concrete variant never includes a sibling variant', () {
    final candidates = buildShoppingCandidates(
      request: 'Bergkäse',
      catalogProducts: [gouda, edamer, bergkaese],
      offers: const [],
      marketPrices: const [],
      receiptPriceStats: const [],
      now: now,
    );

    expect(candidates.map((candidate) => candidate.product.id), ['bergkaese']);
  });

  test('ambiguous H-milk receipt label offers both fat variants', () {
    final candidates = buildShoppingCandidates(
      request: 'K.H-Milch',
      catalogProducts: [
        Product(
          id: 'milk15',
          name: 'Milch 1,5 %',
          unit: '1 l',
          group: 'milch',
        ),
        Product(
          id: 'milk35',
          name: 'Vollmilch 3,5 %',
          unit: '1 l',
          group: 'milch',
        ),
      ],
      offers: const [],
      marketPrices: const [],
      receiptPriceStats: const [],
      now: now,
    );

    expect(
      candidates.map((candidate) => candidate.product.id),
      containsAll(<String>['milk15', 'milk35']),
    );
  });

  test('ambiguous H-milk label also considers ordinary milk offers', () {
    final candidates = buildShoppingCandidates(
      request: 'K.H-Milch',
      catalogProducts: [
        Product(
          id: 'fresh-milk',
          name: 'Frische Vollmilch',
          unit: '1 l',
          group: 'milch',
        ),
      ],
      offers: [
        Offer(
          id: 'fresh-sale',
          productId: 'fresh-milk',
          storeName: 'PENNY',
          originalPrice: 1.19,
          offerPrice: 0.99,
          validUntil: DateTime(2026, 9, 30),
        ),
      ],
      marketPrices: const [],
      receiptPriceStats: const [],
      now: now,
    );

    expect(candidates, hasLength(1));
    expect(candidates.single.product.id, 'fresh-milk');
    expect(candidates.single.bestPrice, 0.99);
  });

  test('only active offers and receipt prices from the last 60 days are shown', () {
    final candidates = buildShoppingCandidates(
      request: 'Käse',
      catalogProducts: [gouda],
      offers: [
        Offer(
          id: 'active',
          productId: 'gouda',
          storeName: 'ALDI Süd',
          originalPrice: 2,
          offerPrice: 1.49,
          validFrom: DateTime(2026, 9, 20),
          validUntil: DateTime(2026, 9, 30),
        ),
        Offer(
          id: 'expired',
          productId: 'gouda',
          storeName: 'Kaufland',
          originalPrice: 2,
          offerPrice: 1,
          validUntil: DateTime(2026, 9, 26),
        ),
      ],
      marketPrices: const [],
      receiptPriceStats: [
        ReceiptPriceStat(
          familyKey: 'kaese',
          storeName: 'EDEKA',
          latestPrice: 1.89,
          latestAt: DateTime(2026, 9, 1),
          observationCount: 1,
          medianPrice: 1.89,
          comparable: true,
          priceBasis: '250 g',
        ),
        ReceiptPriceStat(
          familyKey: 'kaese',
          storeName: 'Lidl',
          latestPrice: 1.29,
          latestAt: DateTime(2026, 7, 20),
          observationCount: 1,
          medianPrice: 1.29,
          comparable: true,
          priceBasis: '250 g',
        ),
      ],
      now: now,
    );

    final quotes = candidates.single.quotes;
    expect(quotes.map((quote) => quote.storeName), containsAll(<String>['ALDI Süd', 'EDEKA']));
    expect(quotes.map((quote) => quote.storeName), isNot(contains('Kaufland')));
    expect(quotes.map((quote) => quote.storeName), isNot(contains('Lidl')));
  });

  test('active offers are ranked before cheaper historical quotes', () {
    final candidates = buildShoppingCandidates(
      request: 'Käse',
      catalogProducts: [gouda, edamer],
      offers: [
        Offer(
          id: 'gouda-sale',
          productId: 'gouda',
          storeName: 'ALDI Süd',
          originalPrice: 2,
          offerPrice: 1.50,
          couponPercent: 10,
          validUntil: DateTime(2026, 9, 30),
        ),
      ],
      marketPrices: const [],
      receiptPriceStats: [
        ReceiptPriceStat(
          familyKey: 'kaese',
          productId: 'edamer',
          storeName: 'EDEKA',
          latestPrice: 0.99,
          latestAt: DateTime(2026, 9, 27),
          observationCount: 1,
          medianPrice: 0.99,
          comparable: true,
          priceBasis: '250 g',
        ),
      ],
      now: now,
    );

    expect(candidates.first.product.id, 'gouda');
    expect(candidates.first.quotes.first.isOffer, isTrue);
    expect(candidates.first.quotes.first.price, 1.35);
  });

  test('cashback offers hide a duplicate historical quote for that market', () {
    final candidates = buildShoppingCandidates(
      request: 'Käse',
      catalogProducts: [gouda],
      offers: [
        Offer(
          id: 'cashback-sale',
          productId: 'gouda',
          storeName: 'ALDI Süd',
          originalPrice: 2,
          offerPrice: 1.50,
          cashbackAmount: 0.20,
          validUntil: DateTime(2026, 9, 30),
        ),
      ],
      marketPrices: const [],
      receiptPriceStats: [
        ReceiptPriceStat(
          familyKey: 'kaese',
          productId: gouda.id,
          storeName: 'ALDI Süd',
          latestPrice: 1.29,
          latestAt: DateTime(2026, 9, 27),
          observationCount: 2,
          medianPrice: 1.39,
          comparable: true,
          priceBasis: '250 g',
        ),
      ],
      now: now,
    );

    expect(candidates.single.quotes, hasLength(1));
    expect(candidates.single.quotes.single.isOffer, isTrue);
    expect(candidates.single.quotes.single.label, 'Angebot, effektiv');
  });

  test('candidate prices use comparable receipt medians, not latest outliers', () {
    final candidates = buildShoppingCandidates(
      request: 'Käse',
      catalogProducts: [gouda],
      offers: const [],
      marketPrices: const [],
      receiptPriceStats: [
        ReceiptPriceStat(
          familyKey: 'kaese',
          productId: gouda.id,
          storeName: 'EDEKA',
          latestPrice: 2.49,
          latestAt: DateTime(2026, 9, 27),
          observationCount: 4,
          medianPrice: 1.59,
          comparable: true,
          priceBasis: '250 g',
        ),
        ReceiptPriceStat(
          familyKey: 'kaese',
          productId: gouda.id,
          storeName: 'Lidl',
          latestPrice: 0.49,
          latestAt: DateTime(2026, 9, 26),
          observationCount: 1,
          medianPrice: 0.49,
          comparable: false,
          priceBasis: 'Packung',
        ),
      ],
      now: now,
    );

    final quotes = candidates.single.quotes;
    expect(quotes.map((quote) => quote.storeName), ['EDEKA']);
    expect(quotes.single.price, 1.59);
    expect(quotes.single.label, 'Bon-Median (historisch)');
  });

  test('historical prospect medians fill stores without a current quote', () {
    final candidates = buildShoppingCandidates(
      request: 'Käse',
      catalogProducts: [gouda],
      offers: const [],
      marketPrices: const [],
      receiptPriceStats: const [],
      prospectPriceHistory: {
        gouda.id: ProspectPriceHistorySummary(
          productId: gouda.id,
          storeName: 'Lidl',
          medianPrice: 1.19,
          latestValidUntil: DateTime(2026, 9, 20),
          kind: PriceObservationKind.offer,
          observationCount: 2,
          alternatives: [
            ProspectPriceHistorySummary(
              productId: gouda.id,
              storeName: 'EDEKA',
              medianPrice: 1.49,
              latestValidUntil: DateTime(2026, 9, 18),
              kind: PriceObservationKind.regular,
              observationCount: 1,
            ),
          ],
        ),
      },
      now: now,
    );

    final quotes = candidates.single.quotes;
    expect(quotes.map((quote) => quote.storeName), ['Lidl', 'EDEKA']);
    expect(quotes.first.label, 'Früheres Angebot (Median)');
    expect(quotes.first.isHistorical, isTrue);
    expect(quotes.first.observedAt, DateTime(2026, 9, 20));
  });

  test('current quote keeps a learned prospect quote as historical context only', () {
    final candidates = buildShoppingCandidates(
      request: 'Käse',
      catalogProducts: [gouda],
      offers: const [],
      marketPrices: [
        MarketPrice(
          productId: gouda.id,
          storeName: 'Lidl',
          price: 1.99,
          updatedAt: now,
        ),
      ],
      receiptPriceStats: const [],
      prospectPriceHistory: {
        gouda.id: ProspectPriceHistorySummary(
          productId: gouda.id,
          storeName: 'Lidl',
          medianPrice: 0.79,
          latestValidUntil: DateTime(2026, 9, 20),
          kind: PriceObservationKind.offer,
          observationCount: 1,
        ),
      },
      now: now,
    );

    expect(candidates.single.quotes, hasLength(1));
    expect(candidates.single.quotes.single.price, 1.99);
    expect(candidates.single.quotes.single.isHistorical, isFalse);
  });
}
