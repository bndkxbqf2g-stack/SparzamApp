import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/shopping_list/shopping_candidate_service.dart';
import 'package:sparzamapp/models/offer.dart';
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
}
