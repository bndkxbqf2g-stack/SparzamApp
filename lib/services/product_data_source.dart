import '../models/product.dart';

/// Contract for an external product-data provider.
///
/// Providers enrich a local product; they do not confirm a price or a
/// product-family match. The caller remains responsible for explicit identity
/// confirmation before a product can enter route planning.
abstract interface class ProductDataSource {
  bool get enabled;

  Future<Product?> fetchProductByEan(
    String ean, {
    Product? existing,
  });

  void close();
}
