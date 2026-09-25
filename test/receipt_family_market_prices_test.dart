import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/receipt/receipt_observation_builder.dart';
import 'package:sparzamapp/features/shopping_list/receipt_family_market_prices.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/receipt_observation.dart';

void main() {
  test('generic Schmand receives latest known family price for planning', () {
    const product = Product(
      id: 'shopping_schmand',
      name: 'Schmand',
      unit: 'Stück',
      group: 'sonstiges',
      packageAmount: 1,
      packageUnit: 'Stück',
    );
    final prices = receiptFamilyMarketPrices(
      items: [ListItem(product: product)],
      observations: [
        ReceiptObservation(
          id: 'receipt-schmand',
          receiptFingerprint: 'receipt',
          rowLine: 34,
          rawLabel: 'K.Frischer Schmand',
          familyKey: 'legacy-wrong-family',
          storeName: 'Kaufland',
          observedAt: DateTime(2026, 7, 23),
          totalPrice: 0.79,
          quantity: 1,
          quantityUnit: 'Stück',
          unitPrice: null,
          discounted: true,
          productId: 'receipt_auto_schmand',
        ),
      ],
      now: DateTime(2026, 9, 24),
    );

    expect(prices, hasLength(1));
    expect(prices.single.productId, 'shopping_schmand');
    expect(prices.single.storeName, 'Kaufland');
    expect(prices.single.price, 0.79);
    expect(prices.single.discounted, isTrue);
  });

  test('specific milk variant does not consume ambiguous family history', () {
    const product = Product(
      id: 'milch_15',
      name: 'H-Milch 1,5%',
      unit: '1 l',
      group: 'milch',
    );
    final prices = receiptFamilyMarketPrices(
      items: [ListItem(product: product)],
      observations: [
        ReceiptObservation(
          id: 'ambiguous-milk',
          receiptFingerprint: 'receipt',
          rowLine: 1,
          rawLabel: 'K.H-Milch',
          familyKey: 'milch',
          storeName: 'Kaufland',
          observedAt: DateTime(2026, 9, 1),
          totalPrice: 0.95,
          quantity: null,
          quantityUnit: 'Stück',
          unitPrice: null,
          discounted: false,
        ),
      ],
      now: DateTime(2026, 9, 24),
    );

    expect(prices, isEmpty);
  });

  test('generic Schmand can reuse a receipt unit price without package metadata', () {
    const product = Product(
      id: 'shopping_schmand_generic',
      name: 'Schmand',
      unit: 'Stück',
      group: 'sonstiges',
    );
    final prices = receiptFamilyMarketPrices(
      items: [ListItem(product: product)],
      observations: [
        ReceiptObservation(
          id: 'receipt-schmand-unit',
          receiptFingerprint: 'receipt-unit',
          rowLine: 2,
          rawLabel: 'Schmand',
          familyKey: 'schmand',
          storeName: 'Lidl',
          observedAt: DateTime(2026, 9, 20),
          totalPrice: 0.69,
          quantity: null,
          quantityUnit: '',
          unitPrice: null,
          discounted: false,
        ),
      ],
      now: DateTime(2026, 9, 24),
    );

    expect(prices, hasLength(1));
    expect(prices.single.storeName, 'Lidl');
    expect(prices.single.price, 0.69);
  });

  test('store-brand and abbreviated Schmand labels resolve to one family', () {
    expect(inferReceiptFamily('K-Schmand 24% 200g'), 'schmand');
    expect(inferReceiptFamily('G&G Schmand 200 G'), 'schmand');
    expect(inferReceiptFamily('Milbona Schmand'), 'schmand');
    expect(inferReceiptFamily('Schmand'), 'schmand');
    expect(inferReceiptFamily('KLC Geh. Tomaten'), 'tomaten');
    expect(inferReceiptFamily('Passata 500g'), 'tomaten');
    expect(inferReceiptFamily('Tomaten'), 'tomaten');
  });

  test('generic Schmand collects comparable prices from multiple stores', () {
    const product = Product(
      id: 'shopping_schmand_multi',
      name: 'Schmand',
      unit: 'Stück',
      group: 'sonstiges',
    );
    final prices = receiptFamilyMarketPrices(
      items: [ListItem(product: product)],
      observations: [
        for (final entry in [
          ('Lidl', 0.69),
          ('Kaufland', 0.79),
          ('EDEKA', 0.89),
        ])
          ReceiptObservation(
            id: 'schmand-${entry.$1}',
            receiptFingerprint: 'receipt-${entry.$1}',
            rowLine: 1,
            rawLabel: entry.$1 == 'Kaufland' ? 'K-Schmand 24% 200g' : entry.$1 == 'EDEKA' ? 'G&G Schmand 200 G' : 'Milbona Schmand',
            familyKey: 'schmand',
            storeName: entry.$1,
            observedAt: DateTime(2026, 9, 20),
            totalPrice: entry.$2,
            quantity: null,
            quantityUnit: '',
            unitPrice: null,
            discounted: false,
          ),
      ],
      now: DateTime(2026, 9, 24),
    );

    expect(prices, hasLength(3));
    expect({for (final price in prices) price.storeName: price.price}, {
      'Lidl': 0.69,
      'Kaufland': 0.79,
      'EDEKA': 0.89,
    });
  });


  test('normalizes repeated whitespace before exact receipt identity matching', () {
    const product = Product(
      id: 'schmand-200',
      name: 'Schmand 200 g',
      unit: '200 g',
      group: 'milchprodukte',
    );
    final prices = receiptFamilyMarketPrices(
      items: [ListItem(product: product)],
      observations: [
        ReceiptObservation(
          id: 'spaced-schmand',
          receiptFingerprint: 'receipt',
          rowLine: 1,
          rawLabel: 'Schmand   200 g',
          familyKey: 'schmand',
          storeName: 'Lidl',
          observedAt: DateTime(2026, 9, 24),
          totalPrice: 0.69,
          quantity: null,
          quantityUnit: '',
          unitPrice: null,
          discounted: false,
        ),
      ],
      now: DateTime(2026, 9, 25),
    );

    expect(prices, hasLength(1));
    expect(prices.single.price, 0.69);
  });
  test('unrelated families are never bridged', () {
    const product = Product(
      id: 'shopping_schmand',
      name: 'Schmand',
      unit: 'Stück',
      group: 'sonstiges',
    );
    final prices = receiptFamilyMarketPrices(
      items: [ListItem(product: product)],
      observations: [
        ReceiptObservation(
          id: 'receipt-milk',
          receiptFingerprint: 'receipt',
          rowLine: 1,
          rawLabel: 'K.H-Milch',
          familyKey: 'milch',
          storeName: 'Kaufland',
          observedAt: DateTime(2026, 9, 1),
          totalPrice: 0.95,
          quantity: null,
          quantityUnit: 'Stück',
          unitPrice: null,
          discounted: false,
        ),
      ],
      now: DateTime(2026, 9, 24),
    );

    expect(prices, isEmpty);
  });
  test('normalizes different receipt package sizes to requested package', () {
    const product = Product(
      id: 'gouda-200',
      name: 'Gouda',
      unit: 'Packung',
      group: 'kaese',
      packageAmount: 200,
      packageUnit: 'g',
    );
    final prices = receiptFamilyMarketPrices(
      items: [ListItem(product: product)],
      observations: [
        ReceiptObservation(
          id: 'gouda-400',
          receiptFingerprint: 'receipt',
          rowLine: 1,
          rawLabel: 'Gouda',
          familyKey: 'kaese',
          storeName: 'Lidl',
          observedAt: DateTime(2026, 9, 20),
          totalPrice: 3.98,
          quantity: 400,
          quantityUnit: 'g',
          unitPrice: null,
          discounted: false,
        ),
      ],
      now: DateTime(2026, 9, 24),
    );
    expect(prices, hasLength(1));
    expect(prices.single.price, closeTo(1.99, 0.0001));
  });

  test('does not route generic family evidence without package basis', () {
    const product = Product(
      id: 'generic-kaese',
      name: 'Käse',
      unit: 'Packung',
      group: 'kaese',
    );
    final prices = receiptFamilyMarketPrices(
      items: [ListItem(product: product)],
      observations: [
        ReceiptObservation(
          id: 'gouda-400',
          receiptFingerprint: 'receipt',
          rowLine: 1,
          rawLabel: 'Gouda',
          familyKey: 'kaese',
          storeName: 'Lidl',
          observedAt: DateTime(2026, 9, 20),
          totalPrice: 3.98,
          quantity: 400,
          quantityUnit: 'g',
          unitPrice: null,
          discounted: false,
        ),
      ],
      now: DateTime(2026, 9, 24),
    );
    expect(prices, isEmpty);
  });  test('generic tomato request builds prices for each observed market', () {
    const product = Product(id: 'tomaten-generic', name: 'Tomaten', unit: 'Stück', group: 'obst');
    final prices = receiptFamilyMarketPrices(
      items: [ListItem(product: product)],
      observations: [
        for (final entry in [('Kaufland', 'KLC Geh. Tomaten', 0.59), ('Lidl', 'Passata', 0.79)])
          ReceiptObservation(
            id: 'tomato-${entry.$1}',
            receiptFingerprint: 'r-${entry.$1}',
            rowLine: 1,
            rawLabel: entry.$2,
            familyKey: 'tomaten',
            storeName: entry.$1,
            observedAt: DateTime(2026, 9, 20),
            totalPrice: entry.$3,
            quantity: null,
            quantityUnit: '',
            unitPrice: null,
            discounted: false,
          ),
      ],
      now: DateTime(2026, 9, 24),
    );
    expect({for (final price in prices) price.storeName: price.price},
        {'Kaufland': 0.59, 'Lidl': 0.79});
  });

  test('does not route receipt family prices older than the receipt freshness window', () {
    final now = DateTime(2026, 9, 25);
    final prices = receiptFamilyMarketPrices(
      now: now,
      items: [
        ListItem(
          product: const Product(
            id: 'schmand',
            name: 'Schmand',
            unit: 'Becher',
            group: 'milchprodukte',
          ),
        ),
      ],
      observations: [
        ReceiptObservation(
          id: 'old-schmand',
          receiptFingerprint: 'old-receipt',
          rowLine: 1,
          rawLabel: 'Schmand',
          familyKey: 'schmand',
          storeName: 'Lidl',
          observedAt: now.subtract(const Duration(days: 31)),
          totalPrice: 0.69,
          quantity: null,
          quantityUnit: '',
          unitPrice: null,
          discounted: false,
        ),
      ],
    );

    expect(prices, isEmpty);
  });
  test('generic yoghurt aliases create separate market prices', () {
    const product = Product(id: 'joghurt-generic', name: 'Joghurt', unit: 'Stück', group: 'milch');
    final prices = receiptFamilyMarketPrices(
      items: [ListItem(product: product)],
      observations: [
        for (final entry in [('Netto', 'Naturjoghurt', 0.79), ('Lidl', 'Joghurt natur', 0.69)])
          ReceiptObservation(
            id: 'joghurt-${entry.$1}',
            receiptFingerprint: 'j-${entry.$1}',
            rowLine: 1,
            rawLabel: entry.$2,
            familyKey: 'joghurt',
            storeName: entry.$1,
            observedAt: DateTime(2026, 9, 20),
            totalPrice: entry.$3,
            quantity: null,
            quantityUnit: '',
            unitPrice: null,
            discounted: false,
          ),
      ],
      now: DateTime(2026, 9, 24),
    );
    expect(prices.map((price) => price.storeName).toSet(), {'Netto', 'Lidl'});
  });
  test('generic Hackfleisch resolves retailer labels across markets', () {
    const product = Product(id: 'hack-generic', name: 'Hackfleisch', unit: 'Stück', group: 'fleisch');
    final prices = receiptFamilyMarketPrices(
      items: [ListItem(product: product)],
      observations: [
        for (final entry in [('Netto', 'Hackfl. gem.', 4.49), ('Kaufland', 'R-Hackfleisch', 4.99)])
          ReceiptObservation(
            id: 'hack-${entry.$1}',
            receiptFingerprint: 'h-${entry.$1}',
            rowLine: 1,
            rawLabel: entry.$2,
            familyKey: 'hackfleisch',
            storeName: entry.$1,
            observedAt: DateTime(2026, 9, 20),
            totalPrice: entry.$3,
            quantity: null,
            quantityUnit: '',
            unitPrice: null,
            discounted: false,
          ),
      ],
      now: DateTime(2026, 9, 24),
    );
    expect({for (final price in prices) price.storeName: price.price},
        {'Netto': 4.49, 'Kaufland': 4.99});
  });

}
