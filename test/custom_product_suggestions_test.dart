import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/shopping_list/shopping_suggestions.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  test('eigene Produkte und Aliase werden in der Suche gefunden', () {
    const custom = Product(
      id: 'custom_coffee',
      name: 'Espresso Bohnen',
      brand: 'Rösterei',
      unit: '500 g',
      group: 'kaffee',
      aliases: ['kaffee', 'bohnen'],
      isFavorite: true,
    );

    final result = buildSuggestions(
      query: 'bohnen',
      knownItems: const [],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: const [custom],
    );

    expect(result, hasLength(1));
    expect(result.single.id, 'custom_coffee');
  });

  test('generische Tomate findet frische Varianten aber keine Tomatenprodukte', () {
    const catalog = [
      Product(id: 'tomate_rispe', name: 'Rispentomaten', unit: '500 g', group: 'obst_gemuese'),
      Product(id: 'tomate_party', name: 'Partytomaten', unit: '250 g', group: 'obst_gemuese'),
      Product(id: 'tomatenmark', name: 'Tomatenmark', unit: '200 g', group: 'vorrat'),
      Product(id: 'passata', name: 'Passata', unit: '500 g', group: 'vorrat'),
    ];

    final result = buildSuggestions(
      query: 'Tomate',
      knownItems: const [],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: catalog,
    );

    expect(result.map((product) => product.id), containsAll(['tomate_rispe', 'tomate_party']));
    expect(result.map((product) => product.id), isNot(contains('tomatenmark')));
    expect(result.map((product) => product.id), isNot(contains('passata')));
  });

  test('eigene Favoriten erscheinen beim Schnellhinzufügen', () {
    const custom = Product(
      id: 'custom_coffee',
      name: 'Espresso Bohnen',
      unit: '500 g',
      group: 'kaffee',
      isFavorite: true,
    );

    final result = buildQuickProducts(
      const {},
      catalogProducts: const [custom],
    );

    expect(result.single.id, 'custom_coffee');
  });
}
