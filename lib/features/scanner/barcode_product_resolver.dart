import '../../data/products.dart';
import '../../models/product.dart';

Product? productForBarcode(String code, [Iterable<Product> learned = const []]) {
  final normalizedCode = code.trim();
  if (normalizedCode.isEmpty) return null;
  for (final product in [...learned, ...products]) {
    if (product.ean?.trim() == normalizedCode) return product;
  }
  return null;
}
