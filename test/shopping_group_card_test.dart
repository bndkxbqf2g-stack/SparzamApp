import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/shopping_list/shopping_group_card.dart';

void main() {
  test('Produktgruppen erhalten stabile sichtbare Bezeichnungen', () {
    expect(shoppingGroupLabel('milch'), 'Milch & Käse');
    expect(shoppingGroupLabel('butter'), 'Milch & Käse');
    expect(shoppingGroupLabel('obst'), 'Obst & Gemüse');
    expect(shoppingGroupLabel('fleisch'), 'Fleisch');
    expect(shoppingGroupLabel('nudeln'), 'Nudeln & Beilagen');
    expect(shoppingGroupLabel('custom'), 'Weitere Produkte');
  });
}
