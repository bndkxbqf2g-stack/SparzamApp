import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/route/route_price_resolver.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/offer.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/store.dart';

void main() {
  const product = Product(
    id: 'test',
    name: 'Test',
    unit: '1 Stk.',
    group: 'test',
  );
  const store = Store(
    name: 'Markt',
    location: 'Ort',
    distanceKm: 1,
    prices: {'test': 2.0},
  );

  test('uses effective offer price', () {
    final offer = Offer(
      id: '1',
      productId: 'test',
      storeName: 'Markt',
      originalPrice: 2,
      offerPrice: 1.5,
      validUntil: DateTime(2026, 9, 30),
      couponPercent: 10,
    );
    final resolver = RoutePriceResolver(
      [offer],
      now: DateTime(2026, 9, 22),
    );
    final quote = resolver.quote(store, ListItem(product: product, quantity: 2));
    expect(quote!.total, 2.7);
    expect(quote.usesOffer, isTrue);
  });

  test('applies 3 for 2 to requested quantity', () {
    final offer = Offer(
      id: '2',
      productId: 'test',
      storeName: 'Markt',
      originalPrice: 2,
      offerPrice: 1.5,
      validUntil: DateTime(2026, 9, 30),
      buyQuantity: 3,
      payQuantity: 2,
    );
    final resolver = RoutePriceResolver(
      [offer],
      now: DateTime(2026, 9, 22),
    );
    final quote = resolver.quote(store, ListItem(product: product, quantity: 3));
    expect(quote!.total, 3.0);
  });
}
