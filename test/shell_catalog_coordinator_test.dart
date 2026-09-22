import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/features/shell/shell_catalog_coordinator.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/services/product_catalog_store.dart';
import 'package:sparzamapp/services/shopping_list_store.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  tearDown(() => SharedPreferencesAsyncPlatform.instance = null);

  test('Speichern aktualisiert Katalog und vorhandenen Listeneintrag', () async {
    final coordinator = ShellCatalogCoordinator(
      productCatalogStore: ProductCatalogStore(),
      shoppingListStore: ShoppingListStore(),
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
      shoppingList: const [ListItem(product: oldProduct, quantity: 2)],
    );

    expect(result.products, [updatedProduct]);
    expect(result.shoppingList.single.product, updatedProduct);
    expect(result.shoppingList.single.quantity, 2);
  });
}
