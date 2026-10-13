import '../../data/products.dart';
import '../../models/product.dart';
import '../../services/barcode_normalizer.dart';

export '../../services/barcode_normalizer.dart';

Product? productForBarcode(String code, [Iterable<Product> learned = const []]) {
  final normalizedCode = normalizeBarcode(code);
  if (normalizedCode == null) return null;
  for (final product in [...learned, ...products]) {
    final productCode = product.ean == null
        ? null
        : normalizeBarcode(product.ean!);
    if (productCode == normalizedCode) return product;
  }
  return null;
}
