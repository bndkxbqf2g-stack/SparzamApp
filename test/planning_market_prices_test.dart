import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/shopping_list/planning_market_prices.dart';
import 'package:sparzamapp/features/shopping_list/shopping_price_quotes.dart';
import 'package:sparzamapp/features/route/route_price_resolver.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/store.dart';

void main() {
  for (final name in ['Schmand', 'Joghurt']) {
    test('$name uses the same exact price in list and route', () {
      final product = Product(id: name, name: name, unit: 'Stück', group: name);
      final item = ListItem(product: product);
      final prices = planningMarketPrices(
        familyPrices: [
          MarketPrice(productId: name, storeName: 'Lidl', price: 0.69,
              updatedAt: DateTime(2026, 9, 24), source: MarketPriceSource.receipt),
        ],
        exactPrices: [
          MarketPrice(productId: name, storeName: 'Lidl', price: 0.79,
              updatedAt: DateTime(2026, 9, 23)),
        ],
      );
      const store = Store(name: 'Lidl', location: 'Ort', distanceKm: 1,
          prices: <String, double>{});
      expect(shoppingQuotes(item, prices: prices, offers: []).single.unitPrice,
          0.79);
      expect(RoutePriceResolver([], marketPrices: prices).quote(store, item)!.total,
          0.79);
    });
  }

  test('planning keeps quality ranking instead of blindly taking newest exact price', () {
    final now = DateTime(2026, 9, 25);
    final prices = planningMarketPrices(
      exactPrices: [
        MarketPrice(
          productId: 'schmand',
          storeName: 'Lidl',
          price: 0.79,
          updatedAt: DateTime(2026, 8, 20),
          source: MarketPriceSource.manual,
        ),
        MarketPrice(
          productId: 'schmand',
          storeName: 'Lidl',
          price: 0.89,
          updatedAt: DateTime(2026, 9, 25),
          source: MarketPriceSource.openPrices,
        ),
      ],
      familyPrices: const [],
      now: now,
    );

    expect(prices, hasLength(1));
    expect(prices.single.price, 0.79);

    const store = Store(
      name: 'Lidl',
      location: 'Ort',
      distanceKm: 1,
      prices: <String, double>{},
    );
    const product = Product(
      id: 'schmand',
      name: 'Schmand',
      unit: 'Stück',
      group: 'schmand',
    );
    final quote = RoutePriceResolver(
      const [],
      marketPrices: prices,
      now: now,
    ).quote(store, ListItem(product: product));

    expect(quote, isNotNull);
    expect(quote!.total, 0.79);
  });

}
