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
  test('groups sharing one visible section do not create duplicate headings', () {
    const butter = Product(
      id: 'butter',
      name: 'Butter',
      unit: '250 g',
      group: 'butter',
    );
    const milk = Product(
      id: 'milk-2',
      name: 'Milch',
      unit: '1 l',
      group: 'milch',
    );
    const paprika = Product(
      id: 'paprika',
      name: 'Paprika',
      unit: 'Stück',
      group: 'Paprika',
    );
    const receiptMilk = Product(
      id: 'receipt-milk',
      name: 'GL H-Milch 3,5% 1 L',
      unit: 'Stück',
      group: 'Milch',
    );

    final grouped = groupShoppingItems(
      [
        ListItem(product: butter),
        ListItem(product: milk),
        ListItem(product: paprika),
        ListItem(product: receiptMilk),
      ],
      const [],
    );

    expect(grouped.keys.toSet(), {'milch', 'other'});
    expect(grouped['milch']!.map((item) => item.product.id).toSet(),
        {'butter', 'milk-2'});
    expect(grouped['other']!.map((item) => item.product.id).toSet(),
        {'paprika', 'receipt-milk'});
  });


}
