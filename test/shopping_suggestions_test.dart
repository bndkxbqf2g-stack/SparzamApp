import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/shopping_list/shopping_suggestions.dart';
import 'package:sparzamapp/features/offers/prospect_price_statistics.dart';
import 'package:sparzamapp/models/price_observation.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/offer.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/recent_purchase.dart';
import 'package:sparzamapp/models/receipt_price_stat.dart';

void main() {
  const regular = Product(
    id: 'milk-35',
    name: 'Vollmilch 3,5 %',
    unit: '1 l',
    group: 'milch',
    isFavorite: true,
  );
  const lowFat = Product(
    id: 'milk-15',
    name: 'Milch 1,5 %',
    unit: '1 l',
    group: 'milch',
  );
  final now = DateTime(2026, 9, 30);

  test('recommends current evidence but never a historical hint alone', () {
    const historical = ShoppingSuggestionPrice(
      price: 0.79,
      storeName: 'Lidl',
      sourceLabel: 'Früheres Angebot (Median)',
      isHistorical: true,
    );
    const current = ShoppingSuggestionPrice(
      price: 0.95,
      storeName: 'ALDI Süd',
      sourceLabel: 'Angebot',
      isOffer: true,
    );
    const historicalProduct = Product(
      id: 'historical',
      name: 'Milch 3,5 %',
      unit: '1 l',
      group: 'milch',
    );
    const currentProduct = Product(
      id: 'current',
      name: 'Milch 1,5 %',
      unit: '1 l',
      group: 'milch',
    );

    final prices = <String, ShoppingSuggestionPrice>{
      historicalProduct.id: historical,
      currentProduct.id: current,
    };
    expect(
      recommendedShoppingProductId(
        suggestions: [historicalProduct, currentProduct],
        priceFor: (product) => prices[product.id],
        hasAlternatives: true,
      ),
      currentProduct.id,
    );
    expect(
      recommendedShoppingProductId(
        suggestions: [historicalProduct],
        priceFor: (_) => historical,
        hasAlternatives: true,
      ),
      isNull,
    );
  });

  test('Enter does not silently choose a generic historical suggestion', () {
    const historicalProduct = Product(
      id: 'historical-milk',
      name: 'Milch 3,5 %',
      unit: '1 l',
      group: 'milch',
    );

    expect(
      shoppingProductForSubmit(
        query: 'Milch',
        suggestions: const [historicalProduct],
        recommendedProductId: null,
      ),
      isNull,
    );
  });

  test('Enter accepts an exact single catalog identity without a price', () {
    expect(
      shoppingProductForSubmit(
        query: 'Milch 3,5 %',
        suggestions: const [regular],
        recommendedProductId: null,
      ),
      regular,
    );
  });

  test('Enter accepts the current evidenced recommendation', () {
    expect(
      shoppingProductForSubmit(
        query: 'Milch',
        suggestions: const [regular, lowFat],
        recommendedProductId: lowFat.id,
      ),
      lowFat,
    );
  });

  test('generic staple suggestions rank the lowest current offer first', () {
    final results = buildSuggestions(
      query: 'Milch',
      knownItems: [
        RecentPurchase(
          id: 'milk-35',
          name: 'Vollmilch 3,5 %',
          unit: '1 l',
          group: 'milch',
          purchaseCount: 12,
        ),
      ],
      recentPurchases: const [],
      preferredProductByGroup: const {'milch': 'milk-35'},
      catalogProducts: [regular, lowFat],
      offers: [
        Offer(
          id: 'aldi-sale',
          productId: lowFat.id,
          storeName: 'ALDI Süd',
          originalPrice: 1.49,
          offerPrice: 0.95,
          validFrom: DateTime(2026, 9, 28),
          validUntil: DateTime(2026, 10, 2),
          source: 'leaflet',
          proofRef: 'https://example.test/aldi/milk',
        ),
      ],
      enabledStores: const ['ALDI Süd', 'Lidl'],
      now: now,
    );

    expect(results.map((product) => product.id), [lowFat.id, regular.id]);
    expect(
      shoppingSuggestionPriceForProduct(
        results.first,
        offers: [
          Offer(
            id: 'aldi-sale',
            productId: lowFat.id,
            storeName: 'ALDI Süd',
            originalPrice: 1.49,
            offerPrice: 0.95,
            validUntil: DateTime(2026, 10, 2),
          ),
        ],
        enabledStores: const ['ALDI Süd'],
        now: now,
      )?.displayLabel,
      contains('Angebot ALDI Süd 0,95 €'),
    );
  });

  test('does not show unrelated catalog matches for a one-character query', () {
    final results = buildSuggestions(
      query: 'J',
      knownItems: const [],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: const [
        Product(
          id: 'beer',
          name: 'Original Pils',
          unit: '0,5 l',
          group: 'bier',
        ),
      ],
    );

    expect(results, isEmpty);
  });

  test('Open Prices can provide a current suggestion with its source label', () {
    final hint = shoppingSuggestionPriceForProduct(
      regular,
      marketPrices: [
        MarketPrice(
          productId: regular.id,
          storeName: 'Lidl',
          price: 0.89,
          updatedAt: DateTime(2026, 9, 29),
          source: MarketPriceSource.openPrices,
        ),
      ],
      now: now,
    );

    expect(hint?.sourceLabel, 'Open Prices');
    expect(hint?.displayLabel, contains('Open Prices Lidl 0,89 €'));
  });

  test(
    'quality-adjusted ranking prefers a safer current price over a cheaper discounted receipt',
    () {
      final hint = shoppingSuggestionPriceForProduct(
        regular,
        marketPrices: [
          MarketPrice(
            productId: regular.id,
            storeName: 'Lidl',
            price: 0.50,
            updatedAt: now,
            source: MarketPriceSource.receipt,
            discounted: true,
          ),
          MarketPrice(
            productId: regular.id,
            storeName: 'ALDI Süd',
            price: 0.53,
            updatedAt: now,
            source: MarketPriceSource.openPrices,
          ),
        ],
        now: now,
      );

      expect(hint?.storeName, 'ALDI Süd');
      expect(hint?.price, 0.53);
      expect(hint?.sourceLabel, 'Open Prices');
    },
  );

  test('product search uses the same quality-adjusted ordering as its price hint', () {
    final results = buildSuggestions(
      query: 'Milch',
      knownItems: const [],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: [regular, lowFat],
      marketPrices: [
        MarketPrice(
          productId: regular.id,
          storeName: 'Lidl',
          price: 0.50,
          updatedAt: now,
          source: MarketPriceSource.receipt,
          discounted: true,
        ),
        MarketPrice(
          productId: lowFat.id,
          storeName: 'ALDI Süd',
          price: 0.53,
          updatedAt: now,
          source: MarketPriceSource.openPrices,
        ),
      ],
      now: now,
    );

    expect(results.map((product) => product.id), [lowFat.id, regular.id]);
  });

  test(
    'generic milk search ignores prospect products using milk as an ingredient',
    () {
      const prospectProducts = [
        Product(
          id: 'condensed',
          name: 'K-CLASSIC Kondensmilch XXL 4 % Fett je 500-g-Großpackg.',
          unit: '500 g',
          group: 'prospekt',
        ),
        Product(
          id: 'bar',
          name: 'K-CLASSIC Milch-Riegel je 100-g-Packg.',
          unit: '100 g',
          group: 'prospekt',
        ),
        Product(
          id: 'chocolate',
          name: 'K-CLASSIC Milch-Schokoladen-Bonbons je 210-g-Pack.',
          unit: '210 g',
          group: 'prospekt',
        ),
        Product(
          id: 'cheese',
          name: 'LINDENHOF Faire Milch Gouda jung je 125 g',
          unit: '125 g',
          group: 'prospekt',
        ),
        Product(
          id: 'fresh-milk',
          name: 'PENNY ZUKUNFTSBAUER Frische Vollmilch* je 1 l',
          unit: '1 l',
          group: 'prospekt',
        ),
      ];

      final results = buildSuggestions(
        query: 'Milch',
        knownItems: const [],
        recentPurchases: const [],
        preferredProductByGroup: const {},
        catalogProducts: prospectProducts,
      );

      expect(results.map((product) => product.id), ['fresh-milk']);
    },
  );

  test('generic milk search ignores buttermilk and plant milk drinks', () {
    const prospectProducts = [
      Product(
        id: 'buttermilk',
        name: 'MILRAM Buttermilch-Drink oder Kefir pur je 750-g-Fl.',
        unit: '750 g',
        group: 'prospekt',
      ),
      Product(
        id: 'coconut-milk',
        name: 'K-CLASSIC ASIA Kokosmilch fettreduziert je 400-ml-Dose',
        unit: '400 ml',
        group: 'prospekt',
      ),
      Product(
        id: 'fresh-milk',
        name: 'BÄRENMARKE Haltbare Milch je 1 l',
        unit: '1 l',
        group: 'prospekt',
      ),
    ];

    final results = buildSuggestions(
      query: 'Milch',
      knownItems: const [],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: prospectProducts,
    );

    expect(results.map((product) => product.id), ['fresh-milk']);
  });

  test('generic milk search ignores infant formula', () {
    const prospectProducts = [
      Product(
        id: 'formula',
        name: 'APTAMIL Folgemilch 2 oder 3 je 800-g-Packg.',
        unit: '800 g',
        group: 'prospekt',
      ),
      Product(
        id: 'fresh-milk',
        name: 'BÄRENMARKE Haltbare Milch je 1 l',
        unit: '1 l',
        group: 'prospekt',
      ),
    ];

    final results = buildSuggestions(
      query: 'Milch',
      knownItems: const [],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: prospectProducts,
    );

    expect(results.map((product) => product.id), ['fresh-milk']);
  });

  test('generic milk search finds a compound milk prospect offer', () {
    const prospectMilk = Product(
      id: 'prospect|berchtesgadener land haltbare berg alpenmilch je 1 l packg',
      name: 'BERCHTESGADENER LAND Haltbare Berg- & Alpenmilch je 1-l-Packg.',
      unit: '1 l',
      group: 'prospekt',
    );
    final offer = Offer(
      id: 'aldi-alpenmilch',
      productId: prospectMilk.id,
      storeName: 'ALDI Süd',
      originalPrice: 1.49,
      offerPrice: 0.95,
      validUntil: DateTime(2026, 10, 2),
      source: 'retailerWebsite',
      proofRef: 'https://example.test/aldi/alpenmilch',
    );
    final results = buildSuggestions(
      query: 'Milch',
      knownItems: const [],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: const [prospectMilk],
      offers: [offer],
      now: now,
    );

    expect(results.map((product) => product.id), [prospectMilk.id]);
    final hint = shoppingSuggestionPriceForProduct(
      results.single,
      offers: [offer],
      now: now,
    );
    expect(hint?.price, 0.95);
    expect(hint?.isOffer, isTrue);
  });

  test('generic sausage search finds a compound sausage prospect offer', () {
    const prospectSausage = Product(
      id: 'prospect|nothwang grobe bratwurst je 100 g',
      name: 'NOTHWANG Grobe Bratwurst je 100 g',
      unit: '100 g',
      group: 'prospekt',
    );
    final offer = Offer(
      id: 'aldi-bratwurst',
      productId: prospectSausage.id,
      storeName: 'ALDI Süd',
      originalPrice: 2.49,
      offerPrice: 1.99,
      validUntil: DateTime(2026, 10, 2),
      source: 'retailerWebsite',
      proofRef: 'https://example.test/aldi/bratwurst',
    );
    final results = buildSuggestions(
      query: 'Wurst',
      knownItems: const [],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: const [prospectSausage],
      offers: [offer],
      now: now,
    );

    expect(results.map((product) => product.id), [prospectSausage.id]);
    final hint = shoppingSuggestionPriceForProduct(
      results.single,
      offers: [offer],
      now: now,
    );
    expect(hint?.price, 1.99);
    expect(hint?.isOffer, isTrue);
  });

  test('generic milk search also filters learned ingredient products', () {
    final results = buildSuggestions(
      query: 'Milch',
      knownItems: const [
        RecentPurchase(
          id: 'learned-chocolate',
          name: 'Milch-Schokoladen-Bonbons',
          unit: '210 g',
          group: 'suessigkeit',
        ),
      ],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: const [regular],
    );

    expect(results.map((product) => product.id), [regular.id]);
  });

  test('generic milk search filters biscuit flavour offers', () {
    const biscuit = Product(
      id: 'milk-biscuit',
      name: "LEIBNIZ Keks'n Cream 190 g, Milch",
      unit: '190 g',
      group: 'suessigkeit',
    );
    final results = buildSuggestions(
      query: 'Milch',
      knownItems: const [],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: [regular, biscuit],
    );

    expect(results.map((product) => product.id), [regular.id]);
  });

  test('generic egg search filters chocolate egg offers', () {
    const confectionery = Product(
      id: 'chocolate-egg',
      name: 'Kinder Maxi Ei 100 g',
      unit: '100 g',
      group: 'suessigkeit',
    );
    const eggs = Product(
      id: 'eggs',
      name: 'Eier aus Bodenhaltung',
      unit: '10 Stück',
      group: 'eier',
    );
    final results = buildSuggestions(
      query: 'Eier',
      knownItems: const [],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: [confectionery, eggs],
    );

    expect(results.map((product) => product.id), [eggs.id]);
  });

  test('generic coffee search excludes pastry and machine offers', () {
    final results = buildSuggestions(
      query: 'Kaffee',
      knownItems: const [],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: const [
        Product(
          id: 'coffee-pastry',
          name: 'BRANDT Kaffee-Gebäck je 201 g',
          unit: '201 g',
          group: 'backwaren',
        ),
        Product(
          id: 'coffee-machine',
          name: 'KRUPS Dolce Gusto Piccolo XS',
          unit: 'Stück',
          group: 'haushalt',
        ),
        Product(
          id: 'coffee-capsules',
          name: 'JACOBS Kaffeekapseln je 20 Stück',
          unit: '20 Stück',
          group: 'kaffee',
        ),
        Product(
          id: 'coffee-beans',
          name: 'Kaffeebohnen',
          unit: '500 g',
          group: 'kaffee',
        ),
      ],
      now: now,
    );

    expect(
      results.map((product) => product.id),
      containsAll(<String>['coffee-capsules', 'coffee-beans']),
    );
    expect(
      results.map((product) => product.id),
      isNot(contains('coffee-pastry')),
    );
    expect(
      results.map((product) => product.id),
      isNot(contains('coffee-machine')),
    );
  });

  test(
    'generic cheese search excludes cheese sausage but keeps hard cheese',
    () {
      final results = buildSuggestions(
        query: 'Käse',
        knownItems: const [],
        recentPurchases: const [],
        preferredProductByGroup: const {},
        catalogProducts: const [
          Product(
            id: 'cheese-sausage',
            name: 'Mühlenhof Käse-Wiener je 600 g',
            unit: '600 g',
            group: 'wurst',
          ),
          Product(
            id: 'hard-cheese',
            name: 'OLD AMSTERDAM Holl. Hartkäse je 100 g',
            unit: '100 g',
            group: 'milch',
          ),
        ],
        now: now,
      );

      expect(results.map((product) => product.id), ['hard-cheese']);
    },
  );

  test('generic staple searches exclude compound ingredient products', () {
    const products = [
      Product(
        id: 'donut',
        name: 'BÄCKERKRÖNUNG Donut Franzbrötchen-Style je Stück',
        unit: 'Stück',
        group: 'backwaren',
      ),
      Product(
        id: 'rolls',
        name: 'K-CLASSIC Brötchen je 300 g',
        unit: '300 g',
        group: 'backwaren',
      ),
      Product(
        id: 'pasta-sauce',
        name: 'BARILLA Pasta-Sauce je 400-g-Glas',
        unit: '400 g',
        group: 'sauce',
      ),
      Product(
        id: 'pasta',
        name: 'BARILLA Classic Pasta je 500 g',
        unit: '500 g',
        group: 'nudeln',
      ),
      Product(
        id: 'snack-sticks',
        name: 'K-CLASSIC Käse- oder Salz-Stängli je 150 g',
        unit: '150 g',
        group: 'snacks',
      ),
      Product(
        id: 'salt',
        name: 'K-CLASSIC Speisesalz je 500 g',
        unit: '500 g',
        group: 'salz',
      ),
    ];

    final rolls = buildSuggestions(
      query: 'Brötchen',
      knownItems: const [],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: products,
      now: now,
    );
    final pasta = buildSuggestions(
      query: 'Nudeln',
      knownItems: const [],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: products,
      now: now,
    );
    final salt = buildSuggestions(
      query: 'Salz',
      knownItems: const [],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: products,
      now: now,
    );

    expect(rolls.map((product) => product.id), ['rolls']);
    expect(pasta.map((product) => product.id), ['pasta']);
    expect(salt.map((product) => product.id), ['salt']);
  });

  test('staple searches ignore beverage, household and food compounds', () {
    const products = [
      Product(
        id: 'spread',
        name: 'RAMA Brotaufstrich',
        unit: '225 g',
        group: 'aufstrich',
      ),
      Product(
        id: 'bread',
        name: 'Kastenweißbrot',
        unit: '750 g',
        group: 'brot',
      ),
      Product(id: 'toast', name: 'Sandwichtoast', unit: '500 g', group: 'brot'),
      Product(
        id: 'water-device',
        name: 'BRAUN Wasserkocher',
        unit: 'Stück',
        group: 'haushalt',
      ),
      Product(
        id: 'water',
        name: 'ADELHOLZENER Mineralwasser',
        unit: '1 l',
        group: 'getraenke',
      ),
      Product(
        id: 'juice-sausage',
        name: 'MEICA Saft-Bockwurst',
        unit: '380 g',
        group: 'wurst',
      ),
      Product(
        id: 'juice',
        name: 'K-CLASSIC Apfelsaft',
        unit: '1 l',
        group: 'getraenke',
      ),
      Product(
        id: 'tea-sausage',
        name: 'REINERT Teewurst',
        unit: '125 g',
        group: 'wurst',
      ),
      Product(
        id: 'tea',
        name: 'MAYFAIR Kamillentee',
        unit: '37,5 g',
        group: 'getraenke',
      ),
      Product(
        id: 'tea-drink',
        name: 'ARIZONA Teegetränk',
        unit: '1,5 l',
        group: 'getraenke',
      ),
      Product(
        id: 'tea-glasses',
        name: 'Tee-Gläser doppelwandig',
        unit: '2 Stück',
        group: 'haushalt',
      ),
      Product(
        id: 'coffee',
        name: 'Melitta Filterkaffee',
        unit: '500 g',
        group: 'kaffee',
      ),
      Product(
        id: 'toy-coffee',
        name: 'TOYLINO Holz-Gebäck-Set, Kaffee und Kuchen',
        unit: '1 Set',
        group: 'haushalt',
      ),
      Product(
        id: 'cheese',
        name: 'Käse',
        unit: '250 g',
        group: 'kaese',
      ),
      Product(
        id: 'chicken-cheese',
        name: 'Hähnchen-Käse-Ecken XXL',
        unit: '700 g',
        group: 'snacks',
      ),
      Product(
        id: 'rice',
        name: 'Basmatireis',
        unit: '1 kg',
        group: 'vorrat',
      ),
      Product(
        id: 'chocolate-rice',
        name: 'WAWI Schoko-Reis Tafel',
        unit: '200 g',
        group: 'suessigkeit',
      ),
      Product(
        id: 'roast',
        name: 'K-PURLAND Schinkenkrustenbraten vom Schwein',
        unit: '1 kg',
        group: 'fleisch',
      ),
      Product(
        id: 'wurst',
        name: 'Bratwurst',
        unit: '400 g',
        group: 'wurst',
      ),
      Product(
        id: 'pizza',
        name: 'Pizza Margherita',
        unit: '400 g',
        group: 'pizza',
      ),
      Product(
        id: 'piccolinis',
        name: 'WAGNER Piccolinis Salami',
        unit: '270 g',
        group: 'pizza',
      ),
      Product(
        id: 'iced-tea',
        name: 'Freeway Eistee',
        unit: '1,5 l',
        group: 'getraenke',
      ),
      Product(
        id: 'ice-cream',
        name: 'Eis am Stiel',
        unit: '4 Stück',
        group: 'tiefkuehl',
      ),
      Product(
        id: 'protein-ice',
        name: 'FROZEN Ice Cream Protein Bar',
        unit: '3 Stück',
        group: 'snacks',
      ),
      Product(
        id: 'calendar',
        name: 'EIS Erotischer Adventskalender DELUXE',
        unit: '1 Stück',
        group: 'haushalt',
      ),
      Product(
        id: 'antipasti-cream',
        name: 'Antipasti-Creme',
        unit: '100 g',
        group: 'feinkost',
      ),
      Product(
        id: 'skyr',
        name: 'EHRMANN High Protein Skyr',
        unit: '450 g',
        group: 'milch',
      ),
      Product(
        id: 'pet-food',
        name: 'K-CARINURA Hundenahrung Premium-Fleischgenuss',
        unit: '800 g',
        group: 'tierbedarf',
      ),
      Product(
        id: 'meat-salad',
        name: 'POPP Fleischsalat',
        unit: '300 g',
        group: 'salat',
      ),
      Product(
        id: 'mince',
        name: 'Hackfleisch gemischt',
        unit: '500 g',
        group: 'fleisch',
      ),
      Product(
        id: 'steak',
        name: 'Rindersteak',
        unit: '300 g',
        group: 'fleisch',
      ),
      Product(
        id: 'protein',
        name: 'IRONMAXX Sahne-Protein',
        unit: '500 g',
        group: 'sport',
      ),
      Product(
        id: 'cosmetics',
        name: 'NIVEA Creme',
        unit: '150 ml',
        group: 'kosmetik',
      ),
      Product(
        id: 'spread-sweet',
        name: 'NUTELLA Nuss-Nugat-Creme',
        unit: '450 g',
        group: 'suessigkeit',
      ),
      Product(id: 'cream', name: 'Schlagsahne', unit: '200 g', group: 'milch'),
      Product(
        id: 'chocolate-chips',
        name: 'NESTLÉ Choco Crossies Original oder Choclait Chips',
        unit: '150 g',
        group: 'suessigkeit',
      ),
      Product(
        id: 'potato-chips',
        name: 'Kartoffelchips',
        unit: '175 g',
        group: 'snacks',
      ),
    ];

    List<String> ids(String query) => buildSuggestions(
      query: query,
      knownItems: const [],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: products,
      now: now,
    ).map((product) => product.id).toList();

    final bread = ids('Brot');
    expect(bread, containsAll(<String>['bread', 'toast']));
    expect(bread, isNot(contains('spread')));

    final water = ids('Wasser');
    expect(water, ['water']);

    final juice = ids('Saft');
    expect(juice, ['juice']);

    final tea = ids('Tee');
    expect(tea, ['tea']);

    final ice = ids('Eis');
    expect(ice, ['ice-cream']);

    final coffee = ids('Kaffee');
    expect(coffee, ['coffee']);

    final yoghurt = ids('Joghurt');
    expect(yoghurt, ['skyr']);

    final cheese = ids('Käse');
    expect(cheese, ['cheese']);

    final rice = ids('Reis');
    expect(rice, ['rice']);

    final sausage = ids('Wurst');
    expect(sausage, contains('wurst'));
    expect(sausage, isNot(contains('roast')));

    final pizza = ids('Pizza');
    expect(pizza, containsAll(<String>['pizza', 'piccolinis']));

    final meat = ids('Fleisch');
    expect(meat, containsAll(<String>['mince', 'steak']));
    expect(meat, isNot(contains('pet-food')));
    expect(meat, isNot(contains('meat-salad')));

    final cream = ids('Sahne');
    expect(cream, ['cream']);

    final chips = ids('Chips');
    expect(chips, ['potato-chips']);
  });

  test('generic potato search keeps plain potatoes before wedges', () {
    final results = buildSuggestions(
      query: 'Kartoffeln 2,5Kg',
      knownItems: const [],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: const [
        Product(
          id: 'wedges',
          name: 'Kartoffel-Wedges',
          unit: '750 g',
          group: 'tiefkuehl',
          aliases: ['kartoffeln'],
        ),
        Product(
          id: 'plain',
          name: 'Kartoffeln',
          unit: '2 kg',
          group: 'obst_gemuese',
          aliases: ['kartoffel'],
        ),
      ],
      now: now,
    );

    expect(results.map((product) => product.id), ['plain', 'wedges']);
  });

  test(
    'ambiguous H-milk label offers both fat choices without merging them',
    () {
      final results = buildSuggestions(
        query: 'K.H-Milch',
        knownItems: const [],
        recentPurchases: const [],
        preferredProductByGroup: const {},
        catalogProducts: [regular, lowFat],
        offers: [
          Offer(
            id: 'synthetic-offer',
            productId: lowFat.id,
            storeName: 'ALDI Süd',
            originalPrice: 1.40,
            offerPrice: 0.95,
            validUntil: DateTime(2026, 10, 2),
          ),
        ],
        now: now,
      );
      expect(results.map((item) => item.id), [lowFat.id, regular.id]);
      expect(results.first.name, 'Milch 1,5 %');
    },
  );

  test('abbreviated H-milk search ranks ordinary milk offers first', () {
    const ordinary = Product(
      id: 'fresh-milk',
      name: 'Frische Vollmilch',
      unit: '1 l',
      group: 'milch',
    );
    final results = buildSuggestions(
      query: 'K.H-Milch',
      knownItems: const [],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: const [regular, lowFat, ordinary],
      offers: [
        Offer(
          id: 'fresh-milk-sale',
          productId: ordinary.id,
          storeName: 'PENNY',
          originalPrice: 1.19,
          offerPrice: 0.99,
          validFrom: DateTime(2026, 9, 28),
          validUntil: DateTime(2026, 10, 2),
        ),
      ],
      now: now,
    );

    expect(results.first.id, ordinary.id);
    expect(
      results.map((product) => product.id),
      containsAll([ordinary.id, lowFat.id, regular.id]),
    );
  });

  test('separator-free KH-milk search ranks ordinary milk offers first', () {
    const ordinary = Product(
      id: 'fresh-milk-kh',
      name: 'Frische Vollmilch',
      unit: '1 l',
      group: 'milch',
    );
    final results = buildSuggestions(
      query: 'KH-Milch',
      knownItems: const [],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: const [regular, lowFat, ordinary],
      offers: [
        Offer(
          id: 'fresh-milk-kh-sale',
          productId: ordinary.id,
          storeName: 'PENNY',
          originalPrice: 1.19,
          offerPrice: 0.99,
          validFrom: DateTime(2026, 9, 28),
          validUntil: DateTime(2026, 10, 2),
        ),
      ],
      now: now,
    );

    expect(results.first.id, ordinary.id);
    expect(
      results.map((product) => product.id),
      containsAll([ordinary.id, lowFat.id, regular.id]),
    );
  });

  test('beef mince query never suggests mixed mince as the same item', () {
    final results = buildSuggestions(
      query: 'XXL R.-Hackfleisch',
      knownItems: const [],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: const [
        Product(
          id: 'mixed',
          name: 'Hackfleisch gemischt',
          unit: '500 g',
          group: 'fleisch',
        ),
      ],
      now: now,
    );
    expect(results, isEmpty);
  });

  test(
    'recalled receipt label never receives a family median as its price',
    () {
      const recalled = Product(
        id: 'receipt_suggestion_milk',
        name: 'H-Milch',
        unit: 'Packung',
        group: 'milch',
        aliases: ['K.H-Milch'],
      );
      final hint = shoppingSuggestionPriceForProduct(
        recalled,
        receiptPriceStats: [
          ReceiptPriceStat(
            familyKey: 'milch',
            storeName: 'Kaufland',
            latestPrice: 0.85,
            latestAt: DateTime(2026, 9, 29),
            observationCount: 3,
            medianPrice: 0.85,
            comparable: true,
            priceBasis: 'Packung',
          ),
        ],
        now: now,
      );
      expect(hint, isNull);
    },
  );

  test(
    'provisional automatic receipt product never receives its own median',
    () {
      const provisional = Product(
        id: 'receipt_auto_specialitaet',
        name: 'Spezialität unbekannt',
        unit: 'Stück',
        group: 'sonstiges',
      );
      final hint = shoppingSuggestionPriceForProduct(
        provisional,
        receiptPriceStats: [
          ReceiptPriceStat(
            familyKey: 'sonstiges',
            productId: provisional.id,
            storeName: 'Kaufland',
            latestPrice: 1.29,
            latestAt: DateTime(2026, 9, 29),
            observationCount: 1,
            medianPrice: 1.29,
            comparable: true,
            priceBasis: 'Stück',
            identityConfirmed: false,
          ),
        ],
        now: now,
      );
      expect(hint, isNull);
    },
  );

  test('receipt median ranks known prices when no active offer exists', () {
    final results = buildSuggestions(
      query: 'Milch',
      knownItems: const [],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: [regular, lowFat],
      receiptPriceStats: [
        ReceiptPriceStat(
          familyKey: 'milch',
          productId: regular.id,
          storeName: 'Lidl',
          latestPrice: 1.49,
          latestAt: DateTime(2026, 9, 29),
          observationCount: 3,
          medianPrice: 1.39,
          comparable: true,
          priceBasis: '1 l',
        ),
        ReceiptPriceStat(
          familyKey: 'milch',
          productId: lowFat.id,
          storeName: 'ALDI Süd',
          latestPrice: 1.05,
          latestAt: DateTime(2026, 9, 29),
          observationCount: 4,
          medianPrice: 0.95,
          comparable: true,
          priceBasis: '1 l',
        ),
      ],
      now: now,
    );

    expect(results.map((product) => product.id), [lowFat.id, regular.id]);
    final hint = shoppingSuggestionPriceForProduct(
      results.first,
      receiptPriceStats: [
        ReceiptPriceStat(
          familyKey: 'milch',
          productId: lowFat.id,
          storeName: 'ALDI Süd',
          latestPrice: 1.05,
          latestAt: DateTime(2026, 9, 29),
          observationCount: 4,
          medianPrice: 0.95,
          comparable: true,
          priceBasis: '1 l',
        ),
      ],
      now: now,
    );
    expect(hint?.isHistorical, isTrue);
    expect(hint?.displayLabel, contains('Bon-Median ALDI Süd 0,95 €'));
    expect(hint?.displayLabel, contains('Stand 29.09.2026'));
  });

  test('stale receipts and disabled-market offers do not rank products', () {
    final hint = shoppingSuggestionPriceForProduct(
      lowFat,
      offers: [
        Offer(
          id: 'disabled',
          productId: lowFat.id,
          storeName: 'Netto',
          originalPrice: 1.49,
          offerPrice: 0.95,
          validUntil: DateTime(2026, 10, 2),
        ),
      ],
      marketPrices: [
        MarketPrice(
          productId: lowFat.id,
          storeName: 'Lidl',
          price: 0.79,
          updatedAt: DateTime(2026, 8, 1),
          source: MarketPriceSource.receipt,
        ),
      ],
      enabledStores: const ['ALDI Süd', 'Lidl'],
      now: now,
    );

    expect(hint, isNull);
  });

  test('receipt median on the history cutoff day remains a search hint', () {
    final hint = shoppingSuggestionPriceForProduct(
      lowFat,
      receiptPriceStats: [
        ReceiptPriceStat(
          familyKey: 'milch',
          productId: lowFat.id,
          storeName: 'ALDI Süd',
          latestPrice: 1.05,
          latestAt: DateTime(2026, 8, 1),
          observationCount: 2,
          medianPrice: 0.95,
          comparable: true,
          priceBasis: '1 l',
        ),
      ],
      now: now,
    );

    expect(hint?.isHistorical, isTrue);
    expect(hint?.price, 0.95);
  });

  test('future receipt median is never used as a search hint', () {
    final hint = shoppingSuggestionPriceForProduct(
      lowFat,
      receiptPriceStats: [
        ReceiptPriceStat(
          familyKey: 'milch',
          productId: lowFat.id,
          storeName: 'ALDI Süd',
          latestPrice: 1.05,
          latestAt: DateTime(2026, 10, 1),
          observationCount: 2,
          medianPrice: 0.95,
          comparable: true,
          priceBasis: '1 l',
        ),
      ],
      now: now,
    );

    expect(hint, isNull);
  });

  test('active offers outrank cheaper receipt prices for generic staples', () {
    const pastaOffer = Product(
      id: 'pasta-1kg',
      name: 'Penne Nudeln',
      unit: '1 kg',
      group: 'nudeln',
    );
    const pastaReceipt = Product(
      id: 'pasta-500g',
      name: 'Spaghetti',
      unit: '500 g',
      group: 'nudeln',
    );

    final results = buildSuggestions(
      query: 'Nudeln',
      knownItems: const [],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: const [pastaReceipt, pastaOffer],
      offers: [
        Offer(
          id: 'penne-sale',
          productId: pastaOffer.id,
          storeName: 'Lidl',
          originalPrice: 2.5,
          offerPrice: 2.0,
          validUntil: DateTime(2026, 10, 2),
        ),
      ],
      receiptPriceStats: [
        ReceiptPriceStat(
          familyKey: 'nudeln',
          productId: pastaReceipt.id,
          storeName: 'ALDI Süd',
          latestPrice: 0.5,
          latestAt: DateTime(2026, 9, 29),
          observationCount: 3,
          medianPrice: 0.5,
          comparable: true,
          priceBasis: '500 g',
        ),
      ],
      now: now,
    );

    expect(results.map((product) => product.id), [
      pastaOffer.id,
      pastaReceipt.id,
    ]);
  });

  test('offer suggestions compare normalized prices across package sizes', () {
    const pastaOneKg = Product(
      id: 'pasta-1kg',
      name: 'Penne Nudeln',
      unit: '1 kg',
      group: 'nudeln',
    );
    const pastaHalfKg = Product(
      id: 'pasta-500g',
      name: 'Spaghetti',
      unit: '500 g',
      group: 'nudeln',
    );

    final results = buildSuggestions(
      query: 'Nudeln',
      knownItems: const [],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: const [pastaHalfKg, pastaOneKg],
      offers: [
        Offer(
          id: 'penne-sale',
          productId: pastaOneKg.id,
          storeName: 'Lidl',
          originalPrice: 2.5,
          offerPrice: 2.0,
          validUntil: DateTime(2026, 10, 2),
        ),
        Offer(
          id: 'spaghetti-sale',
          productId: pastaHalfKg.id,
          storeName: 'ALDI Süd',
          originalPrice: 1.8,
          offerPrice: 1.25,
          validUntil: DateTime(2026, 10, 2),
        ),
      ],
      now: now,
    );

    expect(results.map((product) => product.id), [
      pastaOneKg.id,
      pastaHalfKg.id,
    ]);
  });

  test('unknown package basis does not outrank comparable offer prices', () {
    const knownPackage = Product(
      id: 'yoghurt-500g',
      name: 'Naturjoghurt',
      unit: '500 g',
      group: 'joghurt',
    );
    const unknownPackage = Product(
      id: 'yoghurt-pack',
      name: 'Rahmjoghurt',
      unit: 'Packung',
      group: 'joghurt',
    );
    const expensiveUnknownPackage = Product(
      id: 'yoghurt-multipack',
      name: 'Mix-in Joghurt XXL',
      unit: '6 x 115',
      group: 'joghurt',
    );

    final results = buildSuggestions(
      query: 'Joghurt',
      knownItems: const [],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: const [
        expensiveUnknownPackage,
        unknownPackage,
        knownPackage,
      ],
      offers: [
        Offer(
          id: 'known-offer',
          productId: knownPackage.id,
          storeName: 'PENNY',
          originalPrice: 1.09,
          offerPrice: 0.89,
          validUntil: DateTime(2026, 10, 3),
        ),
        Offer(
          id: 'unknown-offer',
          productId: unknownPackage.id,
          storeName: 'Kaufland',
          originalPrice: 0.69,
          offerPrice: 0.44,
          validUntil: DateTime(2026, 10, 7),
        ),
        Offer(
          id: 'expensive-unknown-offer',
          productId: expensiveUnknownPackage.id,
          storeName: 'Kaufland',
          originalPrice: 4.99,
          offerPrice: 3.99,
          validUntil: DateTime(2026, 10, 7),
        ),
      ],
      now: now,
    );

    expect(results.map((product) => product.id), [
      knownPackage.id,
      unknownPackage.id,
      expensiveUnknownPackage.id,
    ]);
  });

  test(
    'past prospect price is visible as history and does not beat an offer',
    () {
      final history = {
        regular.id: ProspectPriceHistorySummary(
          productId: regular.id,
          storeName: 'Netto',
          medianPrice: 0.49,
          latestValidUntil: DateTime(2026, 9, 27),
          kind: PriceObservationKind.offer,
          observationCount: 3,
        ),
      };
      final results = buildSuggestions(
        query: 'Milch',
        knownItems: const [],
        recentPurchases: const [],
        preferredProductByGroup: const {},
        catalogProducts: const [regular, lowFat],
        prospectPriceHistory: history,
        offers: [
          Offer(
            id: 'current-milk',
            productId: lowFat.id,
            storeName: 'ALDI Süd',
            originalPrice: 1.29,
            offerPrice: 0.95,
            validUntil: DateTime(2026, 10, 3),
          ),
        ],
        now: now,
      );

      expect(results.first.id, lowFat.id);
      expect(
        shoppingSuggestionPriceForProduct(
          regular,
          prospectPriceHistory: history,
          now: now,
        )?.displayLabel,
        contains('Früheres Angebot (Median) Netto 0,49 € · Stand 27.09.2026'),
      );
    },
  );

  test('cheapest enabled historical prospect market is used as the hint', () {
    final history = prospectPriceHistorySummaries([
      PriceObservation(
        id: 'netto-history',
        productId: regular.id,
        storeName: 'Netto',
        price: 1.19,
        quantity: 1,
        unit: 'l',
        observedAt: DateTime(2026, 9, 1),
        source: PriceObservationSource.leaflet,
        kind: PriceObservationKind.offer,
        validUntil: DateTime(2026, 9, 10),
        proofRef: 'https://example.test/netto-history',
      ),
      PriceObservation(
        id: 'lidl-history',
        productId: regular.id,
        storeName: 'Lidl',
        price: 0.89,
        quantity: 1,
        unit: 'l',
        observedAt: DateTime(2026, 9, 1),
        source: PriceObservationSource.leaflet,
        kind: PriceObservationKind.offer,
        validUntil: DateTime(2026, 9, 10),
        proofRef: 'https://example.test/lidl-history',
      ),
    ], now: DateTime(2026, 9, 30));

    final hint = shoppingSuggestionPriceForProduct(
      regular,
      prospectPriceHistory: history,
      enabledStores: const ['Lidl'],
      now: DateTime(2026, 9, 30),
    );

    expect(hint?.storeName, 'Lidl');
    expect(hint?.price, 0.89);
    expect(hint?.isHistorical, isTrue);
  });
  test('generic bread search includes current compound prospect labels', () {
    final products = <Product>[
      Product(
        id: 'wheat-bread',
        name: 'Weizenmischbrot je 1-kg-Stück',
        unit: '1 kg',
        group: 'brot',
      ),
      Product(
        id: 'marzipan-bread',
        name: 'K-WINTER EDITION Marzipanbrot',
        unit: '175 g',
        group: 'süßigkeiten',
      ),
    ];

    final suggestions = buildSuggestions(
      query: 'Brot',
      knownItems: const [],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: products,
      now: DateTime(2026, 10, 9),
    );

    expect(suggestions.map((product) => product.id), ['wheat-bread']);
  });

  test('generic salad search includes current fresh prospect labels', () {
    final products = <Product>[
      Product(
        id: 'field-salad',
        name: 'Feldsalat* je 150-g-Schale',
        unit: '150 g',
        group: 'salat',
      ),
      Product(
        id: 'prepared-salad',
        name: 'FRANK ROSIN Feinkostsalat',
        unit: '200 g',
        group: 'feinkost',
      ),
    ];

    final suggestions = buildSuggestions(
      query: 'Salat',
      knownItems: const [],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: products,
      now: DateTime(2026, 10, 9),
    );

    expect(suggestions.map((product) => product.id), ['field-salad']);
  });

  test('generic yoghurt search includes compound current prospect labels', () {
    final products = <Product>[
      Product(
        id: 'almighurt',
        name: 'Ehrmann Almighurt Je 150 g',
        unit: '150 g',
        group: 'prospekt',
      ),
      Product(
        id: 'obstgarten',
        name: 'EHRMANN Obstgarten* je 125 g',
        unit: '125 g',
        group: 'prospekt',
      ),
      Product(
        id: 'fruit-crunch',
        name: 'BERCHTESGADENER LAND Frucht & Knusper je 150-g-Becher',
        unit: '150 g',
        group: 'prospekt',
      ),
      Product(
        id: 'fresh-cheese',
        name: 'K-CLASSIC Frischkäsezubereitung light oder mit Joghurt',
        unit: '200 g',
        group: 'prospekt',
      ),
      Product(
        id: 'fruit-gruetze',
        name: 'DR. OETKER Löffelglück Fruchtgrütze',
        unit: '400 g',
        group: 'prospekt',
      ),
    ];

    final suggestions = buildSuggestions(
      query: 'Joghurt',
      knownItems: const [],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: products,
      now: DateTime(2026, 10, 9),
    );

    expect(
      suggestions.map((product) => product.id),
      ['obstgarten', 'almighurt', 'fruit-crunch'],
    );
  });

  test('generic butter search excludes cheese and vegetable compounds', () {
    final products = <Product>[
      Product(
        id: 'butter',
        name: 'Landliebe Butter oder Die Streichzarte',
        unit: '250 g',
        group: 'prospekt',
      ),
      Product(
        id: 'butter-cheese',
        name: 'AMMERLÄNDER Butterkäse',
        unit: '100 g',
        group: 'prospekt',
      ),
      Product(
        id: 'butter-vegetables',
        name: 'K-BIO Bio-Buttergemüse',
        unit: '300 g',
        group: 'prospekt',
      ),
    ];

    final suggestions = buildSuggestions(
      query: 'Butter',
      knownItems: const [],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: products,
      now: DateTime(2026, 10, 9),
    );

    expect(suggestions.map((product) => product.id), ['butter']);
  });

  test('generic current prospect searches use compound food identities', () {
    final products = <Product>[
      Product(
        id: 'steinofen-pizza',
        name: 'Gustavo Gusto Steinofenpizza je 480 g',
        unit: '480 g',
        group: 'prospekt',
      ),
      Product(
        id: 'pizza-cheese',
        name: 'KERRYGOLD Pizzakäse je 150 g',
        unit: '150 g',
        group: 'prospekt',
      ),
      Product(
        id: 'frozen-vegetables',
        name: 'FROSTA Gemüse-Pfanne* je 480 g',
        unit: '480 g',
        group: 'prospekt',
      ),
    ];

    final pizzaSuggestions = buildSuggestions(
      query: 'Pizza',
      knownItems: const [],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: products,
      now: DateTime(2026, 10, 9),
    );
    final vegetableSuggestions = buildSuggestions(
      query: 'Gemüse',
      knownItems: const [],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: products,
      now: DateTime(2026, 10, 9),
    );

    expect(
      pizzaSuggestions.map((product) => product.id),
      ['steinofen-pizza'],
    );
    expect(
      vegetableSuggestions.map((product) => product.id),
      ['frozen-vegetables'],
    );
  });

  test('fresh and pantry prospect families are searchable', () {
    final products = <Product>[
      Product(
        id: 'dorade',
        name: 'FISH FROM EVIA BAY Dorade je kg',
        unit: 'kg',
        group: 'prospekt',
      ),
      Product(
        id: 'pumpkin',
        name: 'Dtsch. Kürbis, lose je kg',
        unit: 'kg',
        group: 'prospekt',
      ),
      Product(
        id: 'decor-pumpkin',
        name: 'Dtsch. Zierkürbis bemalt, lose je Stück',
        unit: 'Stück',
        group: 'prospekt',
      ),
      Product(
        id: 'hummus',
        name: 'FOOD FOR FUTURE Hummus* je 200 g',
        unit: '200 g',
        group: 'prospekt',
      ),
    ];

    List<String> ids(String query) => buildSuggestions(
          query: query,
          knownItems: const [],
          recentPurchases: const [],
          preferredProductByGroup: const {},
          catalogProducts: products,
          now: DateTime(2026, 10, 9),
        ).map((product) => product.id).toList();

    expect(ids('Fisch'), ['dorade']);
    expect(ids('Kürbis'), ['pumpkin']);
    expect(ids('Hummus'), ['hummus']);
  });
}
