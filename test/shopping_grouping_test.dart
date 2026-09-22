import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/shopping_list/shopping_grouping.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  test('Artikel werden stabil nach Produktgruppe zusammengefasst', () {
    const milk = Product(
      id: 'milk',
      name: 'Milch',
      unit: '1 l',
      group: 'milch',
    );
    const cheese = Product(
      id: 'cheese',
      name: 'Käse',
      unit: '200 g',
      group: 'milch',
    );
    const apple = Product(
      id: 'apple',
      name: 'Apfel',
      unit: '1 kg',
      group: 'obst',
    );

    final grouped = groupShoppingItems(
      [ListItem(product: milk), ListItem(product: apple), ListItem(product: cheese)],
      const [],
    );

    expect(grouped.keys, ['milch', 'obst']);
    expect(grouped['milch']!.map((item) => item.product.id), ['milk', 'cheese']);
  });
}
