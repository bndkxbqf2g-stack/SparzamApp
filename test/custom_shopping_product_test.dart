import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/shopping_list/custom_shopping_product.dart';

void main() {
  test('eigener Artikel erhält stabile lokale ID', () {
    final product = customShoppingProduct('  Hafer Drink  ');

    expect(product.id, 'custom_hafer_drink');
    expect(product.name, 'Hafer Drink');
    expect(product.group, 'custom');
  });

  test('Sonderzeichen verwenden sichere Ersatz-ID', () {
    expect(customShoppingProduct('ÄÖÜ').id, 'custom_artikel');
  });
}
