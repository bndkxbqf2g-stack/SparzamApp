import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/shell/shell_routing.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/mobility_settings.dart';
import 'package:sparzamapp/models/offer.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  const product = Product(
    id: 'own-milk',
    name: 'Milch',
    group: 'Molkerei',
    unit: 'l',
  );
  const mobility = MobilitySettings(
    mode: MobilityMode.bike,
    enabledStoreNames: ['Lidl'],
  );

  test('die Route wählt das günstigste Angebot für die Listenmenge', () {
    final routing = ShellRouting(
      items: [ListItem(product: product, quantity: 2)],
      offers: [
        Offer(
          id: 'mehrfach',
          productId: product.id,
          storeName: 'Lidl',
          originalPrice: 2,
          offerPrice: 0.8,
          buyQuantity: 2,
          payQuantity: 1,
          validUntil: DateTime(2027),
        ),
        Offer(
          id: 'einzel',
          productId: product.id,
          storeName: 'Lidl',
          originalPrice: 2,
          offerPrice: 0.7,
          validUntil: DateTime(2027),
        ),
      ],
      mobility: mobility,
      marketPrices: [
        MarketPrice(
          productId: product.id,
          storeName: 'Lidl',
          price: 2,
          updatedAt: DateTime(2026, 9, 22),
        ),
      ],
      roadDistances: const {},
      roadMatrix: null,
    );

    final best = routing.current!.bestPlan()!;
    expect(best.stores.single.name, 'Lidl');
    expect(best.basket, closeTo(0.8, 0.001));
    expect(routing.regular!.bestSingleStorePlan()!.basket, 4);
  });

  test('ohne belegten Preis bleibt ein reiner Schätzplan ausgeschlossen', () {
    final routing = ShellRouting(
      items: [ListItem(product: product)],
      offers: const [],
      mobility: mobility,
      marketPrices: const [],
      roadDistances: const {},
      roadMatrix: null,
    );

    expect(routing.current!.bestPlan(), isNull);
  });
  test('ein fehlender Preis blockiert belegte Teilroute nicht', () {
    const unknown = Product(
      id: 'unknown-cheese',
      name: 'Bergkäse',
      group: 'Käse',
      unit: 'Stück',
    );
    final routing = ShellRouting(
      items: [
        ListItem(product: product),
        ListItem(product: unknown),
      ],
      offers: const [],
      mobility: mobility,
      marketPrices: [
        MarketPrice(
          productId: product.id,
          storeName: 'Lidl',
          price: 1.19,
          updatedAt: DateTime(2026, 9, 24),
        ),
      ],
      roadDistances: const {},
      roadMatrix: null,
    );

    final plan = routing.current!.bestPlan()!;
    expect(plan.stores.single.name, 'Lidl');
    expect(plan.pricedItemCount, 1);
    expect(plan.missingItemCount, 1);
    expect(plan.priceCoverage, 0.5);
    expect(plan.unassigned.single.product.id, unknown.id);
    expect(plan.basket, closeTo(1.19, 0.001));
  });
  test('marktübergreifende Preise erzeugen echte Händleralternativen', () {
    const multiMobility = MobilitySettings(
      mode: MobilityMode.bike,
      enabledStoreNames: ['Lidl', 'Kaufland', 'EDEKA'],
    );
    const schmand = Product(
      id: 'shopping-schmand',
      name: 'Schmand',
      group: 'Molkerei',
      unit: 'Stück',
    );
    final routing = ShellRouting(
      items: [ListItem(product: schmand)],
      offers: const [],
      mobility: multiMobility,
      marketPrices: [
        MarketPrice(productId: schmand.id, storeName: 'Lidl', price: 0.69, updatedAt: DateTime(2026, 9, 24)),
        MarketPrice(productId: schmand.id, storeName: 'Kaufland', price: 0.79, updatedAt: DateTime(2026, 9, 24)),
        MarketPrice(productId: schmand.id, storeName: 'EDEKA', price: 0.89, updatedAt: DateTime(2026, 9, 24)),
      ],
      roadDistances: const {},
      roadMatrix: null,
    );

    final alternatives = routing.current!.alternatives();
    final singleStores = alternatives
        .where((plan) => plan.stores.length == 1)
        .map((plan) => plan.stores.single.name)
        .toSet();
    expect(singleStores, containsAll(['Lidl', 'Kaufland', 'EDEKA']));
    expect(routing.current!.bestSingleStorePlan()!.stores.single.name, 'Lidl');
    expect(routing.current!.bestSingleStorePlan()!.basket, closeTo(0.69, 0.001));
  });

}
