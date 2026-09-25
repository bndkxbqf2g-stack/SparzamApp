import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/route/route_optimizer.dart';
import 'package:sparzamapp/features/route/route_price_quality.dart';
import 'package:sparzamapp/features/route/route_price_resolver.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/offer.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/store.dart';

void main() {
  final today = DateTime(2026, 9, 24);
  const schmand = Product(id: 'schmand', name: 'Schmand',
      unit: 'Stück', group: 'schmand');
  const edeka = Store(name: 'EDEKA', location: 'Zellingen', distanceKm: 1,
      prices: {});
  const lidl = Store(name: 'Lidl', location: 'Zellingen', distanceKm: 1,
      prices: {});

  test('fresh discounted receipt adds an explicit planning margin', () {
    final price = MarketPrice(productId: 'schmand', storeName: 'Lidl',
        price: 0.79, updatedAt: DateTime(2026, 9, 23),
        source: MarketPriceSource.receipt, discounted: true);
    final quote = RoutePriceResolver(const [], now: today,
        marketPrices: [price]).quote(lidl, ListItem(product: schmand))!;
    expect(quote.total, 0.79);
    expect(priceUncertaintyReserve(quote, today), closeTo(0.79 * 0.15, 0.00001));
    expect(MarketPrice.fromJson(price.toJson()).discounted, isTrue);
  });

  test('fresh offer has no historical receipt margin', () {
    final quote = RoutePriceResolver([
      Offer(id: 'sale', productId: 'schmand', storeName: 'Lidl',
          originalPrice: 0.89, offerPrice: 0.69,
          validUntil: DateTime(2026, 9, 25)),
    ], now: today).quote(lidl, ListItem(product: schmand))!;
    expect(quote.usesOffer, isTrue);
    expect(priceUncertaintyReserve(quote, today), 0);
  });

  test('whole basket can outweigh uncertainty on one receipt item', () {
    final prices = [
      MarketPrice(productId: 'schmand', storeName: 'Lidl', price: 0.79,
          updatedAt: DateTime(2026, 9, 23),
          source: MarketPriceSource.receipt, discounted: true),
      MarketPrice(productId: 'schmand', storeName: 'EDEKA', price: 0.89,
          updatedAt: today),
    ];
    RouteOptimizer optimizer(List<ListItem> items) => RouteOptimizer(
      items, const [], marketPrices: prices, now: today,
      enabledStoreNames: const ['Lidl', 'EDEKA'], euroPerKm: 0,
      maxStores: 1,
    );
    final oneItem = optimizer([ListItem(product: schmand)]);
    expect(oneItem.bestPlan()!.stores.single.name, edeka.name);
    expect(oneItem.bestPlan()!.basket, 0.89);

    const noodles = Product(id: 'nudeln', name: 'Nudeln',
        unit: '500 g', group: 'nudeln');
    final wholeBasket = optimizer([
      ListItem(product: schmand), ListItem(product: noodles),
    ]);
    expect(wholeBasket.bestPlan()!.stores.single.name, lidl.name);
    expect(wholeBasket.bestPlan()!.basket, closeTo(1.68, 0.00001));
  });
}
