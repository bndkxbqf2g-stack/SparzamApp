import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/features/shell/shell_price_coordinator.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/price_point.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/services/market_price_store.dart';
import 'package:sparzamapp/services/open_prices_sync_service.dart';
import 'package:sparzamapp/services/price_history_store.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  tearDown(() => SharedPreferencesAsyncPlatform.instance = null);

  test('Preisänderung aktualisiert Preisbuch und Verlauf gemeinsam', () async {
    final coordinator = ShellPriceCoordinator(
      marketPriceStore: MarketPriceStore(),
      priceHistoryStore: PriceHistoryStore(),
    );
    final price = MarketPrice(
      productId: 'milk',
      storeName: 'Lidl',
      price: 1.19,
      updatedAt: DateTime.now(),
    );

    final saved = await coordinator.save(
      price: price,
      prices: const [],
      history: const [],
    );
    final deleted = await coordinator.delete(
      productId: 'milk',
      storeName: 'Lidl',
      prices: saved.prices,
    );

    expect(saved.prices, [price]);
    expect(saved.history.single.source, PricePointSource.manual);
    expect(deleted, isEmpty);
  });

  test('Open-Prices-Sync persistiert Preise und Verlauf gemeinsam', () async {
    final coordinator = ShellPriceCoordinator(
      marketPriceStore: MarketPriceStore(),
      priceHistoryStore: PriceHistoryStore(),
    );
    const product = Product(
      id: 'milk',
      name: 'Milch',
      group: 'Molkerei',
      unit: 'l',
      ean: '4000000000001',
    );
    final fetched = MarketPrice(
      productId: product.id,
      storeName: 'Lidl',
      price: 1.09,
      updatedAt: DateTime.now(),
      source: MarketPriceSource.openPrices,
    );
    final service = OpenPricesSyncService(
      fetcher: (_, _) async => [fetched],
    );

    final result = await coordinator.syncOpenPrices(
      products: const [product],
      maxAgeDays: 14,
      prices: const [],
      history: const [],
      service: service,
    );

    expect(result.prices, [fetched]);
    expect(result.history.single.source, PricePointSource.openPrices);
    expect(result.productsChecked, 1);
    expect(result.productsWithEan, 1);
    expect(result.pricesFound, 1);
    expect(result.productsProcessed, 1);
    expect(result.cancelled, isFalse);
  });

  test('Abgebrochener Sync persistiert bereits gefundene Preise', () async {
    final coordinator = ShellPriceCoordinator(
      marketPriceStore: MarketPriceStore(),
      priceHistoryStore: PriceHistoryStore(),
    );
    var cancel = false;
    final service = OpenPricesSyncService(
      fetcher: (product, _) async => [
        MarketPrice(
          productId: product.id,
          storeName: 'Lidl',
          price: 1.09,
          updatedAt: DateTime.now(),
          source: MarketPriceSource.openPrices,
        ),
      ],
    );

    final result = await coordinator.syncOpenPrices(
      products: const [
        Product(id: 'one', name: 'Eins', unit: 'Stk', group: 'x', ean: '1'),
        Product(id: 'two', name: 'Zwei', unit: 'Stk', group: 'x', ean: '2'),
      ],
      maxAgeDays: 14,
      prices: const [],
      history: const [],
      service: service,
      onProgress: (_, _) {
        cancel = true;
      },
      shouldCancel: () => cancel,
    );

    expect(result.cancelled, isTrue);
    expect(result.productsProcessed, 1);
    expect(result.prices.single.productId, 'one');
    expect(result.history.single.productId, 'one');
  });
}
