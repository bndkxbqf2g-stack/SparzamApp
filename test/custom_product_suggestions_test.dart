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
