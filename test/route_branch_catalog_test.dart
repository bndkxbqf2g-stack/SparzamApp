import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/shell/shell_routing.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/mobility_settings.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/store.dart';

void main() {
  const product = Product(
    id: 'branch-catalog-product',
    name: 'Milch',
    unit: '1 l',
    group: 'milch',
  );
  const branchA = Store(
    name: 'Lidl',
    branchId: 'lidl-a',
    location: 'Ort A',
    address: 'A-Straße 1',
    distanceKm: 2,
    prices: {},
  );
  const branchB = Store(
    name: 'Lidl',
    branchId: 'lidl-b',
    location: 'Ort B',
    address: 'B-Straße 1',
    distanceKm: 8,
    prices: {},
  );
  const mobility = MobilitySettings(
    mode: MobilityMode.bike,
    enabledStoreNames: ['Lidl'],
  );

  ShellRouting routing(List<Store> catalog) => ShellRouting(
        items: [ListItem(product: product)],
        offers: const [],
        mobility: mobility,
        marketPrices: const [],
        roadDistances: const {},
        roadMatrix: null,
        storeCatalog: catalog,
      );

  test('reicht den exakten Filialkatalog bis zum Optimierer', () {
    final current = routing(const [branchA]).current!;
    expect(current.availableStores.single.branchId, 'lidl-a');
    expect(current.availableStores.single.address, 'A-Straße 1');
  });

  test('invalidiert den Shell-Snapshot bei geändertem Filialkatalog', () {
    final cache = ShellRoutingSnapshotCache();
    final items = <ListItem>[ListItem(product: product)];
    final first = cache.resolve(
      items: items,
      offers: const [],
      mobility: mobility,
      marketPrices: const [],
      openPricesMaxAgeDays: 60,
      roadDistances: const {},
      roadMatrix: null,
      storeCatalog: const [branchA],
    );
    final second = cache.resolve(
      items: items,
      offers: const [],
      mobility: mobility,
      marketPrices: const [],
      openPricesMaxAgeDays: 60,
      roadDistances: const {},
      roadMatrix: null,
      storeCatalog: const [branchB],
    );

    expect(second, isNot(same(first)));
    expect(second.current!.availableStores.single.branchId, 'lidl-b');
  });
}
