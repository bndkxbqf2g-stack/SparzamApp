import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/catalog/product_family.dart';
import 'package:sparzamapp/features/receipt/receipt_observation_builder.dart';

void main() {
  test('cheese subtypes share a broad family', () {
    expect(broadProductFamily('Bergkäse'), 'kaese');
    expect(broadProductFamily('Gouda jung'), 'kaese');
    expect(inferReceiptFamily('GOUDA 48% 400G'), 'kaese');
  });

  test('sausage subtypes share a broad family', () {
    expect(broadProductFamily('Salami'), 'wurst');
    expect(broadProductFamily('Lyoner'), 'wurst');
    expect(inferReceiptFamily('SALAMI 200G'), 'wurst');
  });

  test('only broad labels are generic requests', () {
    expect(isGenericFamilyRequest('Käse'), isTrue);
    expect(isGenericFamilyRequest('Wurst'), isTrue);
    expect(isGenericFamilyRequest('Bergkäse'), isFalse);
    expect(isGenericFamilyRequest('Salami'), isFalse);
  });

  test('unrelated compound words are not matched by a family substring', () {
    expect(broadProductFamily('Milchreis'), isNull);
  });

  test('whole family terms still match inside descriptive labels', () {
    expect(broadProductFamily('Naturjoghurt'), 'joghurt');
  });
}
