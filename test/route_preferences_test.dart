import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/route/route_optimizer.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  const milk = Product(
    id: 'milch_35',
    name: 'Milch',
    unit: '1 l',
    group: 'milch',
  );
  const noodles = Product(
    id: 'nudeln',
    name: 'Nudeln',
    unit: '500 g',
    group: 'nudeln',
  );

  List<ListItem> items() => [
        ListItem(product: milk),
        ListItem(product: noodles),
      ];

  test('maxStores begrenzt erzeugte Routen', () {
    final optimizer = RouteOptimizer(
      items(),
      const [],
      euroPerKm: 0,
      maxStores: 1,
    );

    expect(
      optimizer.storeCombinations().every((combo) => combo.length == 1),
      isTrue,
    );
    expect(optimizer.bestPlan()!.stores.length, 1);
  });

  test('Mindestvorteil verhindert unnötigen zweiten Markt', () {
    final strict = RouteOptimizer(
      items(),
      const [],
      euroPerKm: 0,
      maxStores: 2,
      minExtraStoreSavings: 0.05,
    );
    final relaxed = RouteOptimizer(
      items(),
      const [],
      euroPerKm: 0,
      maxStores: 2,
      minExtraStoreSavings: 0.01,
    );

    expect(strict.bestPlan()!.stores.length, 1);
    expect(relaxed.bestPlan()!.stores.length, 2);
  });

  test('deaktivierte Märkte werden aus der Optimierung entfernt', () {
    final optimizer = RouteOptimizer(
      items(),
      const [],
      euroPerKm: 0,
      enabledStoreNames: const ['Lidl', 'PENNY'],
    );

    expect(
      optimizer.availableStores.map((store) => store.name),
      ['Lidl', 'PENNY'],
    );
    expect(
      optimizer.alternatives().every(
            (plan) => plan.stores.every(
              (store) => const ['Lidl', 'PENNY'].contains(store.name),
            ),
          ),
      isTrue,
    );
  });
}
