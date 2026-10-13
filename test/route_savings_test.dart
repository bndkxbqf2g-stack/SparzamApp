import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/route/route_price_resolver.dart';
import 'package:sparzamapp/features/route/route_savings.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/offer.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/route_plan.dart';
import 'package:sparzamapp/models/store.dart';

void main() {
  const store = Store(
    name: 'PENNY',
    location: 'Zellingen',
    distanceKm: 1,
    prices: {},
    branchId: 'penny_zellingen',
  );
  const product = Product(
    id: 'milk',
    name: 'Vollmilch',
    unit: '1 l',
    group: 'molkerei',
  );

  test('summiert nur aktive belegte Angebotsersparnisse', () {
    final now = DateTime(2026, 10, 13);
    final resolver = RoutePriceResolver(
      [
        Offer(
          id: 'active',
          productId: product.id,
          storeName: store.name,
          originalPrice: 2,
          offerPrice: 1.5,
          validFrom: DateTime(2026, 10, 12),
          validUntil: DateTime(2026, 10, 17),
          proofRef: 'https://example.test/active',
          locationId: store.branchId,
        ),
        Offer(
          id: 'expired',
          productId: product.id,
          storeName: store.name,
          originalPrice: 2,
          offerPrice: 1,
          validUntil: DateTime(2026, 10, 12),
          proofRef: 'https://example.test/expired',
          locationId: store.branchId,
        ),
      ],
      now: now,
    );
    final plan = RoutePlan(
      stores: const [store],
      assignments: {
        store: [ListItem(product: product, quantity: 2)],
      },
      basket: 3,
      travel: 0,
      total: 3,
      unassigned: const [],
    );

    expect(routeOfferSavings(plan, resolver), 1);
  });

  test('liefert keine Ersparnis für fehlende Belege', () {
    final resolver = RoutePriceResolver(
      const [],
      now: DateTime(2026, 10, 13),
    );
    final plan = RoutePlan(
      stores: const [store],
      assignments: {
        store: [ListItem(product: product)],
      },
      basket: 0,
      travel: 0,
      total: 0,
      unassigned: [ListItem(product: product)],
    );

    expect(routeOfferSavings(plan, resolver), 0);
  });
}
