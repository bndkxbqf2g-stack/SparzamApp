import '../../models/product.dart';

Product customShoppingProduct(String rawName) {
  final name = rawName.trim();
  final slug = name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  return Product(
    id: 'custom_${slug.isEmpty ? 'artikel' : slug}',
    name: name,
    unit: 'Artikel',
    group: 'custom',
  );
}
