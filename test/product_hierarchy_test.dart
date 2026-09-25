import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/catalog/product_hierarchy.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  test('fresh tomato variants expose family and variant separately', () {
    const rispe = Product(
      id: 'tomate_rispe',
      name: 'Rispentomaten',
      unit: '500 g',
      group: 'obst_gemuese',
    );
    const party = Product(
      id: 'tomate_party',
      name: 'Partytomaten',
      unit: '250 g',
      group: 'obst_gemuese',
    );

    expect(productHierarchyLabel(rispe).path, 'Tomaten › Rispe');
    expect(productHierarchyLabel(party).path, 'Tomaten › Party');
  });

  test('milk hierarchy keeps type and fat percentage as variant details', () {
    const milk = Product(
      id: 'milk',
      name: 'H-Milch 3,5 %',
      unit: '1 l',
      group: 'milch',
    );

    expect(productHierarchyLabel(milk).path, 'Milch › H-Milch · 3,5 %');
  });

  test('unknown identities fall back to catalog group without creating identity', () {
    const coffee = Product(
      id: 'coffee',
      name: 'Espresso Bohnen',
      unit: '500 g',
      group: 'kaffee_spezialitaeten',
    );

    expect(
      productHierarchyLabel(coffee).path,
      'Kaffee Spezialitaeten',
    );
  });
}
