import '../../data/products.dart';
import '../../models/product.dart';

Product? productForBarcode(String code, [Iterable<Product> learned = const []]) {
  for (final product in [...learned, ...products]) {
    if (product.ean == code) return product;
  }
  return null;
}
