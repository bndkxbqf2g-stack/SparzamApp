import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/offers/offer_import.dart';
import 'package:sparzamapp/features/offers/prospect_offer_products.dart';
import 'package:sparzamapp/features/route/route_optimizer.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/market_price.dart';

void main() {
  test('route compares leaflet savings with round-trip driving cost', () {
    final now = DateTime(2026, 9, 30);
    final offerBacked = prospectOfferProducts(
      records: [
        OfferImportRecord(
          sourceId: 'netto-coffee',
          productLabel: 'Jacobs Kaffee Crema 500 g',
          storeName: 'Netto',
          originalPrice: 8,
          offerPrice: 5,
          validFrom: DateTime(2026, 9, 28),
          validUntil: DateTime(2026, 10, 2),
          source: 'retailerWebsite',
          proofRef: 'https://example.test/netto/coffee',
        ),
      ],
      catalogProducts: const [],
      now: now,
    ).single;
    final item = ListItem(product: offerBacked.product);
    final localPrice = MarketPrice(
      productId: item.product.id,
      storeName: 'Lidl',
      price: 8,
      updatedAt: now,
    );

    RouteOptimizer optimizer(double euroPerKm) => RouteOptimizer(
      [item],
      [offerBacked.offer],
      marketPrices: [localPrice],
      enabledStoreNames: const ['Lidl', 'Netto'],
      roadDistances: const {'Lidl': 1, 'Netto': 5.8},
      euroPerKm: euroPerKm,
      maxStores: 1,
      now: now,
    );

    final cheapTravel = optimizer(0.22).bestSingleStorePlan()!;
    expect(cheapTravel.stores.single.name, 'Netto');
    expect(cheapTravel.basket, 5);
    expect(cheapTravel.travel, closeTo(2.552, 0.001));

    final expensiveTravel = optimizer(0.5).bestSingleStorePlan()!;
    expect(expensiveTravel.stores.single.name, 'Lidl');
    expect(expensiveTravel.basket, 8);
    expect(expensiveTravel.travel, 1);
  });
}
