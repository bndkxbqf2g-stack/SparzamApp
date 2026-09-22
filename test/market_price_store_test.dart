import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/services/market_price_store.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  test('eigene Marktpreise werden pro Produkt und Markt gespeichert', () async {
    final store = MarketPriceStore();
    final price = MarketPrice(
      productId: 'custom_test',
      storeName: 'Lidl',
      price: 2.49,
      updatedAt: DateTime(2026, 9, 22),
    );

    final next = await store.upsert(price, const <MarketPrice>[]);
    final loaded = await store.load();

    expect(next.single.key, 'Lidl|custom_test');
    expect(loaded.single.price, 2.49);
  });

  test('Open Prices überschreibt keinen manuellen Preis', () async {
    final store = MarketPriceStore();
    final manual = MarketPrice(
      productId: 'a',
      storeName: 'Lidl',
      price: 2.49,
      updatedAt: DateTime(2026, 9, 10),
    );
    final external = MarketPrice(
      productId: 'a',
      storeName: 'Lidl',
      price: 1.99,
      updatedAt: DateTime(2026, 9, 20),
      source: MarketPriceSource.openPrices,
      externalId: 123,
    );

    final first = await store.upsert(manual, const <MarketPrice>[]);
    final second = await store.upsert(external, first);

    expect(second.single.price, 2.49);
    expect(second.single.source, MarketPriceSource.manual);
  });

  test('neuerer Open-Prices-Preis ersetzt älteren Open-Prices-Preis', () async {
    final store = MarketPriceStore();
    final oldPrice = MarketPrice(
      productId: 'a',
      storeName: 'Lidl',
      price: 2.49,
      updatedAt: DateTime(2026, 9, 10),
      source: MarketPriceSource.openPrices,
    );
    final newPrice = MarketPrice(
      productId: 'a',
      storeName: 'Lidl',
      price: 2.29,
      updatedAt: DateTime(2026, 9, 20),
      source: MarketPriceSource.openPrices,
    );

    final first = await store.upsert(oldPrice, const <MarketPrice>[]);
    final second = await store.upsert(newPrice, first);

    expect(second.single.price, 2.29);
    expect(second.single.updatedAt, DateTime(2026, 9, 20));
  });

  test('alle Preise eines Produkts können gemeinsam entfernt werden', () async {
    final store = MarketPriceStore();
    final prices = [
      MarketPrice(
        productId: 'a',
        storeName: 'Lidl',
        price: 1,
        updatedAt: DateTime(2026, 9, 22),
      ),
      MarketPrice(
        productId: 'a',
        storeName: 'EDEKA',
        price: 2,
        updatedAt: DateTime(2026, 9, 22),
      ),
      MarketPrice(
        productId: 'b',
        storeName: 'Lidl',
        price: 3,
        updatedAt: DateTime(2026, 9, 22),
      ),
    ];

    var current = <MarketPrice>[];
    for (final price in prices) {
      current = await store.upsert(price, current);
    }

    final next = await store.removeProduct('a', current);
    expect(next.map((item) => item.productId), ['b']);
  });

  test('Sammelimport bewahrt eigene Preise und übernimmt neuere Fremdpreise',
      () async {
    final store = MarketPriceStore();
    final manual = MarketPrice(
      productId: 'milk',
      storeName: 'Lidl',
      price: 2.5,
      updatedAt: DateTime(2026, 9, 20),
    );
    final old = MarketPrice(
      productId: 'eggs',
      storeName: 'Lidl',
      price: 3,
      updatedAt: DateTime(2026, 9, 10),
      source: MarketPriceSource.openPrices,
    );
    final updated = MarketPrice(
      productId: 'eggs',
      storeName: 'Lidl',
      price: 2.6,
      updatedAt: DateTime(2026, 9, 22),
      source: MarketPriceSource.openPrices,
    );
    final ignored = MarketPrice(
      productId: 'milk',
      storeName: 'Lidl',
      price: 1,
      updatedAt: DateTime(2026, 9, 22),
      source: MarketPriceSource.openPrices,
    );

    final prices = await store.upsertMany([ignored, updated], [manual, old]);

    expect(prices.firstWhere((price) => price.productId == 'milk').price, 2.5);
    expect(prices.firstWhere((price) => price.productId == 'eggs').price, 2.6);
    expect((await store.load()).map((price) => price.price),
        prices.map((price) => price.price));
  });
}
