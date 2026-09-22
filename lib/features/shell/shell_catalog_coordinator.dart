import '../../models/list_item.dart';
import '../../models/market_price.dart';
import '../../models/offer.dart';
import '../../models/price_point.dart';
import '../../models/product.dart';
import '../../services/market_price_store.dart';
import '../../services/offer_store.dart';
import '../../services/price_history_store.dart';
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

class CatalogDeleteResult {
  const CatalogDeleteResult({
    required this.products,
    required this.prices,
    required this.priceHistory,
    required this.offers,
    required this.shoppingList,
    required this.preferredProductByGroup,
  });

  final List<Product> products;
  final List<MarketPrice> prices;
  final List<PricePoint> priceHistory;
  final List<Offer> offers;
  final List<ListItem> shoppingList;
  final Map<String, String> preferredProductByGroup;
}

class ShellCatalogCoordinator {
  const ShellCatalogCoordinator({
    required this.productCatalogStore,
    required this.shoppingListStore,
    required this.marketPriceStore,
    required this.priceHistoryStore,
    required this.offerStore,
  });

  final ProductCatalogStore productCatalogStore;
  final ShoppingListStore shoppingListStore;
  final MarketPriceStore marketPriceStore;
  final PriceHistoryStore priceHistoryStore;
  final OfferStore offerStore;

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

  Future<CatalogDeleteResult> delete({
    required Product product,
    required List<Product> products,
    required List<MarketPrice> prices,
    required List<PricePoint> priceHistory,
    required List<Offer> offers,
    required List<ListItem> shoppingList,
    required Map<String, String> preferredProductByGroup,
  }) async {
    final nextProducts = await productCatalogStore.remove(product.id, products);
    final nextPrices = await marketPriceStore.removeProduct(product.id, prices);
    final nextPriceHistory = await priceHistoryStore.removeProduct(
      product.id,
      priceHistory,
    );
    var nextOffers = offers;
    for (final offer
        in offers.where((item) => item.productId == product.id).toList()) {
      nextOffers = await offerStore.remove(offer.id, nextOffers);
    }
    final nextShoppingList = shoppingList
        .where((item) => item.product.id != product.id)
        .toList();
    final nextPreferredProductByGroup = {...preferredProductByGroup}
      ..removeWhere((_, id) => id == product.id);
    await shoppingListStore.save(nextShoppingList);
    await shoppingListStore.removeKnownItem(product.id);
    await shoppingListStore.removePreferredProduct(product.group, product.id);
    return CatalogDeleteResult(
      products: nextProducts,
      prices: nextPrices,
      priceHistory: nextPriceHistory,
      offers: nextOffers,
      shoppingList: nextShoppingList,
      preferredProductByGroup: nextPreferredProductByGroup,
    );
  }
}
