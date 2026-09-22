import '../../models/list_item.dart';
import '../../models/product.dart';
import '../../services/product_catalog_store.dart';
import '../../services/shopping_list_store.dart';

class CatalogSaveResult {
  const CatalogSaveResult({
    required this.products,
    required this.shoppingList,
  });

  final List<Product> products;
  final List<ListItem> shoppingList;
}

class ShellCatalogCoordinator {
  const ShellCatalogCoordinator({
    required this.productCatalogStore,
    required this.shoppingListStore,
  });

  final ProductCatalogStore productCatalogStore;
  final ShoppingListStore shoppingListStore;

  Future<CatalogSaveResult> save({
    required Product product,
    required List<Product> products,
    required List<ListItem> shoppingList,
  }) async {
    final nextProducts = await productCatalogStore.upsert(product, products);
    final nextShoppingList = [...shoppingList];
    final listIndex = nextShoppingList.indexWhere(
      (item) => item.product.id == product.id,
    );
    if (listIndex >= 0) {
      nextShoppingList[listIndex] = ListItem(
        product: product,
        quantity: nextShoppingList[listIndex].quantity,
      );
      await shoppingListStore.save(nextShoppingList);
    }
    await shoppingListStore.saveKnownItem(product);
    return CatalogSaveResult(
      products: nextProducts,
      shoppingList: nextShoppingList,
    );
  }
}
