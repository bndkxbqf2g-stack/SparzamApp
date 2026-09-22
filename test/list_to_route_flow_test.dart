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

  test('ohne Preis oder Angebot gibt es keinen vollständigen Plan', () {
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
}
