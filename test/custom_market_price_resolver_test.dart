import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/route/route_price_resolver.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/store.dart';

void main() {
  const custom = Product(
    id: 'custom_coffee',
    name: 'Kaffee',
    unit: '500 g',
    group: 'kaffee',
  );
  const store = Store(
    name: 'Lidl',
    location: 'Ort',
    distanceKm: 1,
    prices: {},
  );

  test('eigener Marktpreis macht eigenes Produkt routenfähig', () {
    final resolver = RoutePriceResolver(
      const [],
      marketPrices: [
        MarketPrice(
          productId: custom.id,
          storeName: store.name,
          price: 4.99,
          updatedAt: DateTime(2026, 9, 22),
        ),
      ],
    );

    final quote = resolver.quote(
      store,
      ListItem(product: custom, quantity: 2),
    );

    expect(quote, isNotNull);
    expect(quote!.unitPrice, 4.99);
    expect(quote.total, 9.98);
  });

  test('eigener Marktpreis überschreibt vorhandenen Demo-Preis', () {
    const demoStore = Store(
      name: 'Lidl',
      location: 'Ort',
      distanceKm: 1,
      prices: {'custom_coffee': 5.99},
    );
    final resolver = RoutePriceResolver(
      const [],
      marketPrices: [
        MarketPrice(
          productId: custom.id,
          storeName: demoStore.name,
          price: 4.49,
          updatedAt: DateTime(2026, 9, 22),
        ),
      ],
    );

    expect(
      resolver.quote(demoStore, ListItem(product: custom))!.unitPrice,
      4.49,
    );
  });
}
