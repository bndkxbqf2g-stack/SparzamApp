import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/data/stores.dart';
import 'package:sparzamapp/features/route/route_optimizer.dart';
import 'package:sparzamapp/features/route/route_price_resolver.dart';
import 'package:sparzamapp/features/shopping_list/planning_market_prices.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/receipt_observation.dart';
import 'package:sparzamapp/services/market_price_observation_adapter.dart';
import 'package:sparzamapp/services/price_observation_adapters.dart';

void main() {
  // This is the only complete, source-backed receipt row currently preserved
  // in repository tests. Add further real-receipt rows only from originals.
  test('real Kaufland Schmand evidence reaches exact route pipeline when confirmed', () {
    const product = Product(
      id: 'schmand',
      name: 'Schmand',
      unit: 'Stück',
      group: 'schmand',
      aliases: ['K.Frischer Schmand'],
    );
    final receipt = ReceiptObservation(
      id: 'kaufland-230726|34',
      receiptFingerprint: 'kaufland-230726',
      rowLine: 34,
      rawLabel: 'K.Frischer Schmand',
      familyKey: 'schmand',
      storeName: 'Kaufland',
      observedAt: DateTime(2026, 7, 23),
      totalPrice: 0.79,
      quantity: null,
      quantityUnit: 'Stück',
      unitPrice: null,
      discounted: true,
      productId: product.id,
      identityConfirmed: true,
    );
    final now = DateTime(2026, 7, 24);
    final priceObservation = observationFromReceipt(receipt);
    final exactPrices = marketPricesFromObservations(
      [priceObservation],
      products: const [product],
      now: now,
    );
    final planning = planningMarketPrices(
      exactPrices: exactPrices,
      familyPrices: const [],
      now: now,
    );
    final item = ListItem(product: product);
    final kaufland = stores.singleWhere((store) => store.name == 'Kaufland');
    final quote = RoutePriceResolver(
      const [],
      marketPrices: planning,
      now: now,
    ).quote(kaufland, item);
    final plan = RouteOptimizer(
      [item],
      const [],
      marketPrices: planning,
      enabledStoreNames: const ['Kaufland'],
      maxStores: 1,
      euroPerKm: 0,
      now: now,
    ).bestSingleStorePlan();

    expect(priceObservation.identityConfidence, 1);
    expect(exactPrices, hasLength(1));
    expect(exactPrices.single.price, 0.79);
    expect(planning, hasLength(1));
    expect(quote?.total, 0.79);
    expect(quote?.observation?.source.name, 'receipt');
    expect(plan, isNotNull);
    expect(plan!.unassigned, isEmpty);
    expect(plan.stores.single.name, 'Kaufland');
    expect(plan.basket, 0.79);
  });

  test('same historical receipt no longer enters current route after 30 days', () {
    const product = Product(
      id: 'schmand',
      name: 'Schmand',
      unit: 'Stück',
      group: 'schmand',
    );
    final observation = observationFromReceipt(ReceiptObservation(
      id: 'kaufland-230726|34',
      receiptFingerprint: 'kaufland-230726',
      rowLine: 34,
      rawLabel: 'K.Frischer Schmand',
      familyKey: 'schmand',
      storeName: 'Kaufland',
      observedAt: DateTime(2026, 7, 23),
      totalPrice: 0.79,
      quantity: null,
      quantityUnit: 'Stück',
      unitPrice: null,
      discounted: true,
      productId: product.id,
      identityConfirmed: true,
    ));

    final projected = marketPricesFromObservations(
      [observation],
      products: const [product],
      now: DateTime(2026, 9, 25),
    );

    expect(projected, isEmpty);
  });
}
