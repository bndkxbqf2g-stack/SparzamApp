import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/shopping_list/receipt_product_price_match.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/receipt_price_stat.dart';

void main() {
  const mixedMince = Product(
    id: 'hackfleisch_gemischt',
    name: 'Hackfleisch gemischt',
    unit: 'Packung',
    group: 'fleisch',
  );

  ReceiptPriceStat stat({
    required String family,
    String? productId,
    required double price,
    required DateTime date,
    bool comparable = false,
  }) =>
      ReceiptPriceStat(
        familyKey: family,
        productId: productId,
        storeName: 'Kaufland',
        latestPrice: price,
        latestAt: date,
        observationCount: 1,
        medianPrice: price,
        comparable: comparable,
        priceBasis: comparable ? 'kg' : 'Packung',
      );

  test('specific variant does not inherit sibling family history', () {
    const bergkaese = Product(
      id: 'bergkaese', name: 'Bergkäse', unit: '200 g', group: 'kaese',
    );
    final result = receiptStatsForProduct(bergkaese, [
      stat(
        family: 'kaese',
        productId: 'gouda',
        price: 1.99,
        date: DateTime(2026, 9, 20),
      ),
    ]);

    expect(result, isEmpty);
  });

  test('generic family may use sibling family history as a hint', () {
    const cheese = Product(
      id: 'kaese', name: 'Käse', unit: 'Packung', group: 'kaese',
    );
    final result = receiptStatsForProduct(cheese, [
      stat(
        family: 'kaese',
        productId: 'gouda',
        price: 1.99,
        date: DateTime(2026, 9, 20),
      ),
    ]);

    expect(result, hasLength(1));
    expect(result.single.productId, 'gouda');
  });

  test('specific mince variant does not inherit unknown sibling history', () {
    final result = receiptStatsForProduct(mixedMince, [
      stat(
        family: 'hackfleisch',
        productId: 'receipt_auto_old',
        price: 4.79,
        date: DateTime(2026, 7, 23),
      ),
    ]);

    expect(result, isEmpty);
  });

  test('exact product history still wins over family fallback', () {
    final result = receiptStatsForProduct(mixedMince, [
      stat(
        family: 'hackfleisch',
        productId: 'receipt_auto_old',
        price: 4.79,
        date: DateTime(2026, 7, 23),
      ),
      stat(
        family: 'hackfleisch',
        productId: 'hackfleisch_gemischt',
        price: 4.99,
        date: DateTime(2026, 8, 1),
      ),
    ]);

    expect(result, hasLength(1));
    expect(result.single.productId, 'hackfleisch_gemischt');
  });

  test('non-comparable family prices prefer newest, not cheapest', () {
    final result = preferredReceiptStatForProduct(mixedMince, [
      stat(
        family: 'hackfleisch',
        productId: 'old_a',
        price: 4.79,
        date: DateTime(2026, 7, 23),
      ),
      stat(
        family: 'hackfleisch',
        productId: 'new_b',
        price: 9.99,
        date: DateTime(2026, 8, 23),
      ),
    ]);

    expect(result?.medianPrice, 9.99);
  });
  test('generic family includes exact and provisional receipt identities', () {
    const eggs = Product(
      id: 'eggs',
      name: 'Eier',
      unit: 'Artikel',
      group: 'eier',
    );
    final result = receiptStatsForProduct(eggs, [
      stat(
        family: 'eier',
        productId: 'eggs',
        price: 2.49,
        date: DateTime(2026, 9, 20),
      ),
      stat(
        family: 'eier',
        productId: 'receipt_auto_bodenhaltung',
        price: 2.29,
        date: DateTime(2026, 9, 21),
      ),
      stat(
        family: 'eier',
        productId: null,
        price: 2.19,
        date: DateTime(2026, 9, 22),
      ),
    ]);

    expect(result, hasLength(3));
    expect(result.map((item) => item.medianPrice).toSet(), {2.49, 2.29, 2.19});
  });


}
