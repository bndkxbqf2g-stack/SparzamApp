import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/shell/shell_routing.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/mobility_settings.dart';

void main() {
  test('leere Einkaufsliste erzeugt keine Routenberechnung', () {
    final routing = ShellRouting(
      items: const [],
      offers: const [],
      mobility: const MobilitySettings(),
      marketPrices: const [],
      roadDistances: const {},
      roadMatrix: null,
    );

    expect(routing.current, isNull);
    expect(routing.regular, isNull);
  });

  test('reuses optimizers for one routing snapshot', () {
    final routing = ShellRouting(
      items: [
        ListItem(
          product: const Product(
            id: 'milk',
            name: 'Milch 1 l',
            unit: '1 l',
            group: 'milch',
          ),
        ),
      ],
      offers: const [],
      mobility: const MobilitySettings(),
      marketPrices: const [],
      roadDistances: const {},
      roadMatrix: null,
    );

    final firstCurrent = routing.current;
    final secondCurrent = routing.current;
    final firstRegular = routing.regular;
    final secondRegular = routing.regular;

    expect(firstCurrent, isNotNull);
    expect(identical(firstCurrent, secondCurrent), isTrue);
    expect(identical(firstRegular, secondRegular), isTrue);
  });

  test('routing snapshot invalidiert sich bei geänderter Menge', () {
    final items = [
      ListItem(
        product: const Product(
          id: 'milk',
          name: 'Milch 1 l',
          unit: '1 l',
          group: 'milch',
        ),
      ),
    ];
    const mobility = MobilitySettings();
    final cache = ShellRoutingSnapshotCache();

    final first = cache.resolve(
      items: items,
      offers: const [],
      mobility: mobility,
      marketPrices: const [],
      openPricesMaxAgeDays: 60,
      roadDistances: const {},
      roadMatrix: null,
    );
    final reused = cache.resolve(
      items: items,
      offers: const [],
      mobility: mobility,
      marketPrices: const [],
      openPricesMaxAgeDays: 60,
      roadDistances: const {},
      roadMatrix: null,
    );

    expect(identical(first, reused), isTrue);

    items.single.quantity = 2;
    final changed = cache.resolve(
      items: items,
      offers: const [],
      mobility: mobility,
      marketPrices: const [],
      openPricesMaxAgeDays: 60,
      roadDistances: const {},
      roadMatrix: null,
    );

    expect(identical(first, changed), isFalse);
  });

}
