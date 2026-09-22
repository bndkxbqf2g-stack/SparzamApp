import '../../data/products.dart' as base_catalog;
import '../../models/product.dart';

List<Product> buildCatalogProducts(List<Product> customProducts) => [
      ...base_catalog.products,
      ...customProducts,
    ];

Product? catalogProductById(String id, List<Product> customProducts) {
  for (final product in buildCatalogProducts(customProducts)) {
    if (product.id == id) return product;
  }
  return null;
}

bool isBaseCatalogProduct(String id) =>
    base_catalog.products.any((product) => product.id == id);
