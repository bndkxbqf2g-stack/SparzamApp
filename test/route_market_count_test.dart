import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/route/route_optimizer.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/store.dart';
import 'package:sparzamapp/models/mobility_settings.dart';

void main() {
  const product = Product(
    id: 'six-market-product',
    name: 'Milch',
    unit: '1 l',
    group: 'milch',
  );

  const catalog = <Store>[
    Store(name: 'Markt 1', location: 'Ort 1', distanceKm: 1, prices: {}),
    Store(name: 'Markt 2', location: 'Ort 2', distanceKm: 1, prices: {}),
    Store(name: 'Markt 3', location: 'Ort 3', distanceKm: 1, prices: {}),
    Store(name: 'Markt 4', location: 'Ort 4', distanceKm: 1, prices: {}),
    Store(name: 'Markt 5', location: 'Ort 5', distanceKm: 1, prices: {}),
    Store(name: 'Markt 6', location: 'Ort 6', distanceKm: 1, prices: {}),
  ];

  test('erzeugt Kombinationen bis zum sechsten konfigurierten Markt', () {
    final optimizer = RouteOptimizer(
      [ListItem(product: product)],
      const [],
      storeCatalog: catalog,
      enabledStoreNames: catalog.map((store) => store.name).toList(),
      maxStores: 6,
      euroPerKm: 0,
      marketPrices: [
        for (final store in catalog)
          MarketPrice(
            productId: product.id,
            storeName: store.name,
            price: 1,
            updatedAt: DateTime(2026, 10, 15),
          ),
      ],
      now: DateTime(2026, 10, 15),
    );

    final combinations = optimizer.storeCombinations();

    // Summe von C(6,k), k=1..6.
    expect(combinations, hasLength(63));
    expect(combinations.map((combo) => combo.length).toSet(), {1, 2, 3, 4, 5, 6});
    expect(combinations.last.map((store) => store.name), [
      'Markt 1',
      'Markt 2',
      'Markt 3',
      'Markt 4',
      'Markt 5',
      'Markt 6',
    ]);
  });

  test('MobilitySettings akzeptiert sechs Märkte aus dem lokalen Format', () {
    final settings = MobilitySettings.fromJson({'maxStores': 6});
    expect(settings.maxStores, 6);
  });
}
