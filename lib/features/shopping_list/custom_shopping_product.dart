import '../../models/product.dart';
import '../catalog/product_identity.dart';

Product customShoppingProduct(String rawName) {
  final name = rawName.trim();
  final slug = name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  final identity = identifyProduct(name);

  return Product(
    id: 'custom_${slug.isEmpty ? 'artikel' : slug}',
    name: name,
    unit: 'Artikel',
    group: identity.familyKey ?? 'custom',
  );
}
