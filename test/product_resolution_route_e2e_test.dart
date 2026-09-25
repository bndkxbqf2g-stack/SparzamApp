import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/route/route_optimizer.dart';
import 'package:sparzamapp/features/shopping_list/planning_market_prices.dart';
import 'package:sparzamapp/features/shopping_list/receipt_family_market_prices.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/receipt_observation.dart';

void main() {
  test('compatible receipt observations reach route optimization', () {
    const paprika = Product(
      id: 'shopping-paprika',
      name: 'Paprika',
      unit: 'Stück',
      group: 'gemuese',
    );
    final item = ListItem(product: paprika);
    final now = DateTime(2026, 9, 25);
    final familyPrices = receiptFamilyMarketPrices(
      items: [item],
      now: now,
      observations: [
        for (final entry in [
          ('Lidl', 'Paprika Mix 500g', 0.99),
          ('EDEKA', 'rote Paprika', 1.29),
          ('Kaufland', 'Pringles Paprika', 0.49),
        ])
          ReceiptObservation(
            id: 'paprika-${entry.$1}',
            receiptFingerprint: 'receipt-${entry.$1}',
            rowLine: 1,
            rawLabel: entry.$2,
            familyKey: '',
            storeName: entry.$1,
            observedAt: now,
            totalPrice: entry.$3,
            quantity: null,
            quantityUnit: '',
            unitPrice: null,
            discounted: false,
          ),
      ],
    );
    final planning = planningMarketPrices(exactPrices: const [], familyPrices: familyPrices);
    final optimizer = RouteOptimizer(
      [item],
      const [],
      marketPrices: planning,
      enabledStoreNames: const ['Lidl', 'EDEKA', 'Kaufland'],
      maxStores: 1,
      now: now,
    );

    final route = optimizer.bestSingleStorePlan();
    expect(familyPrices.map((price) => price.storeName).toSet(), {'Lidl', 'EDEKA'});
    expect(route, isNotNull);
    expect(route!.pricedItemCount, 1);
    expect(route.unassigned, isEmpty);
    expect(route.stores.single.name, 'Lidl');
  });
}
