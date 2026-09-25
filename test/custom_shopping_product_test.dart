import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/shopping_list/custom_shopping_product.dart';

void main() {
  test('eigener Artikel erhält stabile lokale ID', () {
    final product = customShoppingProduct('  Hafer Drink  ');

    expect(product.id, 'custom_hafer_drink');
    expect(product.name, 'Hafer Drink');
    expect(product.group, 'custom');
  });

  test('bekannte freie Eingabe behält ihre Produktfamilie', () {
    expect(customShoppingProduct('Schmand').group, 'schmand');
    expect(customShoppingProduct('Tomate').group, 'tomaten');
    expect(customShoppingProduct('Tomatenmark').group, 'tomatenmark');
  });

  test('Sonderzeichen verwenden sichere Ersatz-ID', () {
    expect(customShoppingProduct('ÄÖÜ').id, 'custom_artikel');
  });
}
