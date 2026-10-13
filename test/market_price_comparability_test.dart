import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/route/route_price_resolver.dart';
import 'package:sparzamapp/features/shopping_list/shopping_price_quotes.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/price_observation.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/store.dart';
import 'package:sparzamapp/services/market_price_comparability.dart';
import 'package:sparzamapp/services/market_price_observation_adapter.dart';

void main() {
  const coffee = Product(
    id: 'coffee',
    name: 'Kaffee',
    unit: '500 g',
    group: 'kaffee',
  );
  const store = Store(
    name: 'Lidl',
    location: 'Zellingen',
    distanceKm: 1,
    prices: <String, double>{},
  );

  test('compares explicit price quantities with the product package', () {
    final matching = MarketPrice(
      productId: coffee.id,
      storeName: store.name,
      price: 4.99,
      updatedAt: DateTime(2026, 10, 12),
      quantity: 0.5,
      unit: 'kg',
    );
    final wrong = MarketPrice(
      productId: coffee.id,
      storeName: store.name,
      price: 4.99,
      updatedAt: DateTime(2026, 10, 12),
      quantity: 1,
      unit: 'kg',
    );

    expect(marketPriceMatchesProduct(matching, coffee), isTrue);
    expect(marketPriceMatchesProduct(wrong, coffee), isFalse);
  });

  test('keeps a legacy price without quantity readable', () {
    final legacy = MarketPrice(
      productId: coffee.id,
      storeName: store.name,
      price: 4.99,
      updatedAt: DateTime(2026, 10, 12),
    );

    expect(marketPriceMatchesProduct(legacy, coffee), isTrue);
  });

  test('route and shopping matrix both hide an incompatible package', () {
    final wrong = MarketPrice(
      productId: coffee.id,
      storeName: store.name,
      price: 4.99,
      updatedAt: DateTime(2026, 10, 12),
      quantity: 1,
      unit: 'kg',
    );
    final item = ListItem(product: coffee);

    expect(
      RoutePriceResolver(
        const [],
        marketPrices: [wrong],
        now: DateTime(2026, 10, 12),
      ).quote(store, item),
      isNull,
    );
    expect(
      shoppingQuotes(
        item,
        prices: [wrong],
        offers: const [],
        now: DateTime(2026, 10, 12),
      ),
      isEmpty,
    );
  });

  test('observation projection applies the same package boundary', () {
    final wrong = PriceObservation(
      id: 'wrong-pack',
      productId: coffee.id,
      storeName: store.name,
      price: 4.99,
      observedAt: DateTime(2026, 10, 12),
      source: PriceObservationSource.manual,
      quantity: 1,
      unit: 'kg',
    );
    final matching = PriceObservation(
      id: 'matching-pack',
      productId: coffee.id,
      storeName: store.name,
      price: 4.99,
      observedAt: DateTime(2026, 10, 12),
      source: PriceObservationSource.manual,
      quantity: 500,
      unit: 'g',
    );

    final projected = marketPricesFromObservations(
      [wrong, matching],
      products: [coffee],
      now: DateTime(2026, 10, 12),
    );

    expect(projected, hasLength(1));
    expect(projected.single.price, 4.99);
    expect(projected.single.quantity, 500);
  });
}
