import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/shell/shell_catalog.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  const custom = Product(
    id: 'custom_coffee',
    name: 'Kaffee',
    unit: '500 g',
    group: 'custom',
  );

  test('Basiskatalog und eigene Produkte werden gemeinsam bereitgestellt', () {
    final products = buildCatalogProducts(const [custom]);

    expect(products, contains(custom));
    expect(products.length, greaterThan(1));
  });

  test('Produktsuche und Basiserkennung bleiben getrennt', () {
    expect(catalogProductById(custom.id, const [custom]), custom);
    expect(isBaseCatalogProduct(custom.id), isFalse);
    expect(catalogProductById('missing', const [custom]), isNull);
  });
}
