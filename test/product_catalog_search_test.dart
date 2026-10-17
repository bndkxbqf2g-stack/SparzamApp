import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/catalog/product_catalog_search.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  const freshTomatoes = [
    Product(
      id: 'tomate_rispe',
      name: 'Rispentomaten',
      unit: '500 g',
      group: 'obst_gemuese',
      aliases: ['tomate', 'tomaten', 'rispe'],
    ),
    Product(
      id: 'tomate_party',
      name: 'Partytomaten',
      unit: '250 g',
      group: 'obst_gemuese',
      aliases: ['tomate', 'tomaten', 'party'],
    ),
  ];
  const passata = Product(
    id: 'tomaten_passata',
    name: 'Passierte Tomaten',
    unit: '500 g',
    group: 'vorrat',
    aliases: ['passata'],
  );

  test('generic tomato search keeps fresh variants in the primary catalog', () {
    final results = buildProductCatalogSearchResults(
      query: 'Tomate',
      products: [...freshTomatoes, passata],
    );

    expect(results.map((product) => product.id), [
      'tomate_party',
      'tomate_rispe',
    ]);
  });

  test('specific preserved tomato search does not fall back to fresh variants', () {
    final results = buildProductCatalogSearchResults(
      query: 'Passata',
      products: [...freshTomatoes, passata],
    );

    expect(results.single.id, 'tomaten_passata');
  });

  test('EAN remains searchable when no product identity is known', () {
    const product = Product(
      id: 'coffee',
      name: 'Kaffee Crema',
      unit: '500 g',
      group: 'kaffee',
      ean: '4006381333931',
    );

    final results = buildProductCatalogSearchResults(
      query: '4006381333931',
      products: [product],
    );

    expect(results.single.id, 'coffee');
  });

  test('known variant query ranks the exact identity before siblings', () {
    const products = [
      Product(
        id: 'milk-35',
        name: 'H-Milch 3,5 %',
        unit: '1 l',
        group: 'milch',
      ),
      Product(
        id: 'milk-15',
        name: 'H-Milch 1,5 %',
        unit: '1 l',
        group: 'milch',
      ),
    ];

    final results = buildProductCatalogSearchResults(
      query: 'Vollmilch 3,5 %',
      products: products,
    );

    expect(results.map((product) => product.id), ['milk-35']);
  });
}
