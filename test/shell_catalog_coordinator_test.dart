import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/features/shell/shell_catalog_coordinator.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/offer.dart';
import 'package:sparzamapp/models/price_point.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/services/market_price_store.dart';
import 'package:sparzamapp/services/offer_store.dart';
import 'package:sparzamapp/services/price_history_store.dart';
import 'package:sparzamapp/services/product_catalog_store.dart';
import 'package:sparzamapp/services/shopping_list_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  tearDown(() => SharedPreferencesAsyncPlatform.instance = null);

  test('Speichern aktualisiert Katalog und vorhandenen Listeneintrag', () async {
    final coordinator = ShellCatalogCoordinator(
      productCatalogStore: ProductCatalogStore(),
      shoppingListStore: ShoppingListStore(),
      marketPriceStore: MarketPriceStore(),
      priceHistoryStore: PriceHistoryStore(),
      offerStore: OfferStore(),
    );
    const oldProduct = Product(
      id: 'custom-milk',
      name: 'Milch',
      group: 'Molkerei',
      unit: 'l',
    );
    const updatedProduct = Product(
      id: 'custom-milk',
      name: 'Weidemilch',
      group: 'Molkerei',
      unit: 'l',
    );

    final result = await coordinator.save(
      product: updatedProduct,
      products: const [oldProduct],
      shoppingList: [ListItem(product: oldProduct, quantity: 2)],
    );

    expect(result.products, [updatedProduct]);
    expect(result.shoppingList.single.product, updatedProduct);
    expect(result.shoppingList.single.quantity, 2);
  });

  test('Löschen entfernt alle produktbezogenen Daten', () async {
    final coordinator = ShellCatalogCoordinator(
      productCatalogStore: ProductCatalogStore(),
      shoppingListStore: ShoppingListStore(),
      marketPriceStore: MarketPriceStore(),
      priceHistoryStore: PriceHistoryStore(),
      offerStore: OfferStore(),
    );
    const product = Product(
      id: 'custom-milk',
      name: 'Milch',
      group: 'Molkerei',
      unit: 'l',
    );
    final now = DateTime.now();

    final result = await coordinator.delete(
      product: product,
      products: const [product],
      prices: [
        MarketPrice(
          productId: product.id,
          storeName: 'Lidl',
          price: 1.19,
          updatedAt: now,
        ),
      ],
      priceHistory: [
        PricePoint(
          productId: product.id,
          storeName: 'Lidl',
          price: 1.19,
          date: now,
        ),
      ],
      offers: [
        Offer(
          id: 'milk-offer',
          productId: product.id,
          storeName: 'Lidl',
          originalPrice: 1.19,
          offerPrice: 0.99,
          validUntil: now,
        ),
      ],
      shoppingList: [ListItem(product: product)],
      preferredProductByGroup: {'Molkerei': product.id},
    );

    expect(result.products, isEmpty);
    expect(result.prices, isEmpty);
    expect(result.priceHistory, isEmpty);
    expect(result.offers, isEmpty);
    expect(result.shoppingList, isEmpty);
    expect(result.preferredProductByGroup, isEmpty);
  });
}
