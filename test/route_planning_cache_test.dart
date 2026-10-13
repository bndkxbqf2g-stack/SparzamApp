import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/route/route_optimizer.dart';
import 'package:sparzamapp/features/route/route_price_resolver.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/store.dart';

void main() {
  final now = DateTime(2026, 10, 12);
  const product = Product(
    id: 'cache-milk',
    name: 'Milch',
    unit: '1 l',
    group: 'milch',
  );
  const store = Store(
    name: 'Lidl',
    location: 'Thüngersheim',
    branchId: 'lidl-97225',
    distanceKm: 2,
    prices: <String, double>{},
  );

  test('wiederholte Preisauflösung verwendet dieselbe Quote', () {
    final resolver = RoutePriceResolver(
      const [],
      now: now,
      marketPrices: [
        MarketPrice(
          productId: product.id,
          storeName: store.name,
          price: 1.09,
          updatedAt: now,
          sourceLocationId: store.branchId,
        ),
      ],
    );
    final item = ListItem(product: product, quantity: 2);

    final first = resolver.quote(store, item);
    final second = resolver.quote(store, item);

    expect(first, isNotNull);
    expect(second, same(first));
  });

  test('Route-Ergebnisse bleiben bei wiederholten Zugriffen stabil', () {
    final optimizer = RouteOptimizer(
      [ListItem(product: product)],
      const [],
      now: now,
      maxStores: 2,
      enabledStoreNames: const ['Lidl', 'ALDI Süd'],
      marketPrices: [
        MarketPrice(
          productId: product.id,
          storeName: 'Lidl',
          price: 1.09,
          updatedAt: now,
        ),
        MarketPrice(
          productId: product.id,
          storeName: 'ALDI Süd',
          price: 1.19,
          updatedAt: now,
        ),
      ],
    );

    final alternatives = optimizer.alternatives();
    final best = optimizer.bestPlan();
    final single = optimizer.bestSingleStorePlan();

    expect(optimizer.alternatives(), same(alternatives));
    expect(optimizer.bestPlan(), same(best));
    expect(optimizer.bestSingleStorePlan(), same(single));
  });
}
