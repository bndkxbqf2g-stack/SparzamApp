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
        id: 'iced-tea',
        name: 'Freeway Eistee',
        unit: '1,5 l',
        group: 'getraenke',
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
}
