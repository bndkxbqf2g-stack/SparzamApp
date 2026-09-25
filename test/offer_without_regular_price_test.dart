import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/route/route_price_resolver.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/offer.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/store.dart';
import 'package:sparzamapp/services/price_observation_adapters.dart';

void main() {
  const product = Product(
    id: 'schmand',
    name: 'Schmand',
    unit: '200 g',
    group: 'schmand',
  );

  final offerOnly = Offer(
    id: 'edeka-sale-only',
    productId: product.id,
    storeName: 'EDEKA',
    originalPrice: 0.69,
    originalPriceVerified: false,
    offerPrice: 0.69,
    validUntil: DateTime(2026, 9, 26),
    source: 'retailerWebsite',
    proofRef: 'https://www.edeka.de/maerkte/example',
  );

  test('offer-only evidence does not invent a regular observation', () {
    final observations = observationsFromOffer(
      offerOnly,
      observedAt: DateTime(2026, 9, 25),
    ).toList();

    expect(observations, hasLength(1));
    expect(observations.single.price, 0.69);
    expect(observations.single.discounted, isTrue);
  });

  test('verified offer-only evidence remains a routable current price', () {
    const store = Store(
      name: 'EDEKA',
      location: 'Zellingen',
      distanceKm: 1.4,
      prices: <String, double>{},
    );

    final quote = RoutePriceResolver(
      [offerOnly],
      now: DateTime(2026, 9, 25),
    ).quote(store, ListItem(product: product));

    expect(quote, isNotNull);
    expect(quote!.unitPrice, 0.69);
    expect(quote.total, 0.69);
    expect(quote.isEstimated, isFalse);
    expect(quote.usesOffer, isTrue);
    expect(quote.savings, 0);
  });
}
