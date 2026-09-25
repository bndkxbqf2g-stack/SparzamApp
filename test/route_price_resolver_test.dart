import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/route/route_price_resolver.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/offer.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/store.dart';
import 'package:sparzamapp/models/market_price.dart';

void main() {
  const product = Product(
    id: 'test',
    name: 'Test',
    unit: '1 Stk.',
    group: 'test',
  );
  const store = Store(
    name: 'Markt',
    location: 'Ort',
    distanceKm: 1,
    prices: {'test': 2.0},
  );

  test('uses effective offer price', () {
    final offer = Offer(
      id: '1',
      productId: 'test',
      storeName: 'Markt',
      originalPrice: 2,
      offerPrice: 1.5,
      validUntil: DateTime(2026, 9, 30),
      couponPercent: 10,
    );
    final resolver = RoutePriceResolver(
      [offer],
      now: DateTime(2026, 9, 22),
    );
    final quote = resolver.quote(store, ListItem(product: product, quantity: 2));
    expect(quote!.total, 2.7);
    expect(quote.usesOffer, isTrue);
  });

  test('does not activate an offer before validFrom', () {
    final offer = Offer(
      id: 'future',
      productId: 'test',
      storeName: 'Markt',
      originalPrice: 2,
      offerPrice: 1,
      validFrom: DateTime(2026, 9, 26),
      validUntil: DateTime(2026, 9, 30),
    );
    final before = RoutePriceResolver([offer], now: DateTime(2026, 9, 25))
        .quote(store, ListItem(product: product));
    final active = RoutePriceResolver([offer], now: DateTime(2026, 9, 26))
        .quote(store, ListItem(product: product));

    expect(before!.total, 2);
    expect(before.usesOffer, isFalse);
    expect(active!.total, 1);
    expect(active.usesOffer, isTrue);
  });

  test('applies 3 for 2 to requested quantity', () {
    final offer = Offer(
      id: '2',
      productId: 'test',
      storeName: 'Markt',
      originalPrice: 2,
      offerPrice: 1.5,
      validUntil: DateTime(2026, 9, 30),
      buyQuantity: 3,
      payQuantity: 2,
    );
    final resolver = RoutePriceResolver(
      [offer],
      now: DateTime(2026, 9, 22),
    );
    final quote = resolver.quote(store, ListItem(product: product, quantity: 3));
    expect(quote!.total, 3.0);
  });

  test('estimates a missing price and marks it as estimated', () {
    const missing = Product(
      id: 'unknown-milk',
      name: 'Milch',
      unit: '1 l',
      group: 'milch',
    );
    const storeWithoutPrice = Store(
      name: 'Ohne Preis',
      location: 'Ort',
      distanceKm: 1,
      prices: <String, double>{},
    );
    final quote = RoutePriceResolver(const []).quote(
      storeWithoutPrice,
      ListItem(product: missing),
    );

    expect(quote, isNotNull);
    expect(quote!.unitPrice, 1.29);
    expect(quote.isEstimated, isTrue);
  });

  test('uses the median of observed prices for an unknown store', () {
    const missingStore = Store(
      name: 'Unbekannt',
      location: 'Ort',
      distanceKm: 1,
      prices: <String, double>{},
    );
    const product = Product(
      id: 'same-product',
      name: 'Produkt',
      unit: '1 Stk.',
      group: 'sonstiges',
    );
    final quote = RoutePriceResolver(
      const [],
      marketPrices: [
        MarketPrice(
          productId: 'same-product',
          storeName: 'A',
          price: 1.0,
          updatedAt: DateTime(2026, 9, 23),
        ),
        MarketPrice(
          productId: 'same-product',
          storeName: 'B',
          price: 1.4,
          updatedAt: DateTime(2026, 9, 23),
        ),
        MarketPrice(
          productId: 'same-product',
          storeName: 'C',
          price: 1.8,
          updatedAt: DateTime(2026, 9, 23),
        ),
      ],
    ).quote(missingStore, ListItem(product: product));

    expect(quote!.unitPrice, 1.4);
    expect(quote.isEstimated, isTrue);
  });

  test('fresh receipt can beat a dearer manual price regardless of order', () {
    final manual = MarketPrice(
      productId: 'test', storeName: 'Markt', price: 0.89,
      updatedAt: DateTime(2026, 9, 20),
    );
    final receipt = MarketPrice(
      productId: 'test', storeName: 'Markt', price: 0.79,
      updatedAt: DateTime(2026, 9, 23),
      source: MarketPriceSource.receipt,
    );
    for (final order in [[manual, receipt], [receipt, manual]]) {
      final quote = RoutePriceResolver(const [],
          now: DateTime(2026, 9, 24), marketPrices: order)
          .quote(store, ListItem(product: product));
      expect(quote!.total, 0.79);
      expect(quote.observation?.source, MarketPriceSource.receipt);
    }
  });

  test('old discounted receipt cannot beat a fresh confirmed price', () {
    final quote = RoutePriceResolver(const [], marketPrices: [
      MarketPrice(productId: 'test', storeName: 'Markt', price: 0.79,
          updatedAt: DateTime(2026, 7, 1),
          source: MarketPriceSource.receipt, discounted: true),
      MarketPrice(productId: 'test', storeName: 'Markt', price: 0.89,
          updatedAt: DateTime(2026, 9, 20)),
    ], now: DateTime(2026, 9, 24))
        .quote(store, ListItem(product: product));
    expect(quote!.total, 0.89);
    expect(quote.observation?.updatedAt, DateTime(2026, 9, 20));
  });

  test('offer never transfers to a different product with a similar id', () {
    const other = Product(id: 'milch_15', name: 'Milch 1,5 %',
        unit: '1 l', group: 'milch');
    const market = Store(name: 'Markt', location: 'Ort', distanceKm: 1,
        prices: {'milch_15': 1.25});
    final quote = RoutePriceResolver([
      Offer(id: 'milk-offer', productId: 'milch_35', storeName: 'Markt',
          originalPrice: 1.29, offerPrice: 0.69,
          validUntil: DateTime(2026, 9, 30)),
    ], now: DateTime(2026, 9, 24))
        .quote(market, ListItem(product: other));
    expect(quote!.total, 1.25);
    expect(quote.usesOffer, isFalse);
  });
}
