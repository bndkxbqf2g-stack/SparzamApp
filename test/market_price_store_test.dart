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
}
