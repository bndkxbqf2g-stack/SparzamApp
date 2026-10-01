import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/data/products.dart';
import 'package:sparzamapp/features/shopping_list/shopping_suggestions.dart';
import 'package:sparzamapp/models/offer.dart';
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

  test(
    'generische Tomate findet frische Varianten aber keine Tomatenprodukte',
    () {
      const catalog = [
        Product(
          id: 'tomate_rispe',
          name: 'Rispentomaten',
          unit: '500 g',
          group: 'obst_gemuese',
        ),
        Product(
          id: 'tomate_party',
          name: 'Partytomaten',
          unit: '250 g',
          group: 'obst_gemuese',
        ),
        Product(
          id: 'tomatenmark',
          name: 'Tomatenmark',
          unit: '200 g',
          group: 'vorrat',
        ),
        Product(id: 'passata', name: 'Passata', unit: '500 g', group: 'vorrat'),
      ];

      final result = buildSuggestions(
        query: 'Tomate',
        knownItems: const [],
        recentPurchases: const [],
        preferredProductByGroup: const {},
        catalogProducts: catalog,
      );

      expect(
        result.map((product) => product.id),
        containsAll(['tomate_rispe', 'tomate_party']),
      );
      expect(
        result.map((product) => product.id),
        isNot(contains('tomatenmark')),
      );
      expect(result.map((product) => product.id), isNot(contains('passata')));
    },
  );

  test('Basiskatalog liefert frische Tomatenvarianten für die Suche', () {
    final result = buildSuggestions(
      query: 'Tomate',
      knownItems: const [],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: products,
    );

    expect(
      result.map((product) => product.id),
      containsAll(['tomate_rispe', 'tomate_party', 'tomate_cherry']),
    );
  });

  test(
    'Tomate exposes processed tomato products only as related interpretations',
    () {
      const catalog = [
        Product(
          id: 'tomate_rispe',
          name: 'Rispentomaten',
          unit: '500 g',
          group: 'obst_gemuese',
        ),
        Product(
          id: 'tomate_party',
          name: 'Partytomaten',
          unit: '250 g',
          group: 'obst_gemuese',
        ),
        Product(
          id: 'tomatenmark',
          name: 'Tomatenmark',
          unit: '200 g',
          group: 'vorrat',
        ),
        Product(id: 'passata', name: 'Passata', unit: '500 g', group: 'vorrat'),
      ];
      final primary = buildSuggestions(
        query: 'Tomate',
        knownItems: const [],
        recentPurchases: const [],
        preferredProductByGroup: const {},
        catalogProducts: catalog,
      );
      final related = buildRelatedProductInterpretations(
        query: 'Tomate',
        primarySuggestions: primary,
        catalogProducts: catalog,
      );

      expect(
        primary.map((product) => product.id),
        containsAll(['tomate_rispe', 'tomate_party']),
      );
      expect(
        related.map((product) => product.id),
        containsAll(['tomatenmark', 'passata']),
      );
      expect(
        related.map((product) => product.id),
        isNot(contains('tomate_rispe')),
      );
    },
  );

  test('related milk interpretations prioritize current offer prices', () {
    const primary = Product(
      id: 'h-milk',
      name: 'H-Milch',
      unit: '1 l',
      group: 'milch',
    );
    const cheap = Product(
      id: 'fresh-milk',
      name: 'Frische Vollmilch',
      unit: '1 l',
      group: 'milch',
    );
    const expensive = Product(
      id: 'premium-milk',
      name: 'Vollmilch 3,5 %',
      unit: '1 l',
      group: 'milch',
    );
    final offers = [
      Offer(
        id: 'cheap-offer',
        productId: cheap.id,
        storeName: 'PENNY',
        originalPrice: 1.19,
        offerPrice: 0.99,
        validFrom: DateTime(2026, 9, 28),
        validUntil: DateTime(2026, 10, 3),
      ),
      Offer(
        id: 'expensive-offer',
        productId: expensive.id,
        storeName: 'Kaufland',
        originalPrice: 2.49,
        offerPrice: 1.49,
        validFrom: DateTime(2026, 9, 28),
        validUntil: DateTime(2026, 10, 3),
      ),
    ];

    final related = buildRelatedProductInterpretations(
      query: 'K.H-Milch',
      primarySuggestions: const [primary],
      catalogProducts: const [primary, expensive, cheap],
      priceFor: (product) => shoppingSuggestionPriceForProduct(
        product,
        offers: offers,
        now: DateTime(2026, 10, 1),
      ),
    );

    expect(related.map((product) => product.id), [
      'fresh-milk',
      'premium-milk',
    ]);
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

  test('Grundbedarf ist auf einer frischen Liste direkt auswählbar', () {
    final result = buildQuickProducts(const {}, catalogProducts: products);

    expect(
      result.map((product) => product.id),
      containsAll([
        'milch_35',
        'milch_15',
        'eier_10',
        'joghurt_natur',
        'wurst_aufschnitt',
        'broetchen_aufback',
        'marmelade',
        'kaffee_filter',
        'kaese_gouda',
        'nudeln',
      ]),
    );
    expect(result.every((product) => product.isStaple), isTrue);

    for (final query in [
      'Eier',
      'Milch',
      'Wurst',
      'Käse',
      'Joghurt',
      'Brötchen',
      'Marmelade',
      'Nudeln',
      'Kaffee',
    ]) {
      expect(
        buildSuggestions(
          query: query,
          knownItems: const [],
          recentPurchases: const [],
          preferredProductByGroup: const {},
          catalogProducts: products,
        ),
        isNotEmpty,
        reason: 'Grundbedarf muss über "$query" auffindbar sein',
      );
    }
  });

  test('Grundvorrat findet konkrete Varianten über die gemeinsame Familie', () {
    for (final query in [
      'Reis',
      'Basmati Reis',
      'Öl',
      'Rapsöl',
      'Mehl',
      'Puderzucker',
      'Salz',
      'Ketchup',
      'Passata',
    ]) {
      expect(
        buildSuggestions(
          query: query,
          knownItems: const [],
          recentPurchases: const [],
          preferredProductByGroup: const {},
          catalogProducts: products,
        ),
        isNotEmpty,
        reason: 'Grundvorrat muss über "$query" auffindbar sein',
      );
    }

    final rice = buildSuggestions(
      query: 'Basmati Reis',
      knownItems: const [],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: products,
    );
    expect(rice.first.id, 'reis_basmati');

    final freshTomatoes = buildSuggestions(
      query: 'Tomate',
      knownItems: const [],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: products,
    );
    expect(
      freshTomatoes.map((product) => product.id),
      isNot(contains('tomaten_passata')),
    );
    expect(
      freshTomatoes.map((product) => product.id),
      isNot(contains('tomatenmark')),
    );
  });
}
