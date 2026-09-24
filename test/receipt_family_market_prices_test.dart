import 'package:flutter_test/flutter_test.dart';
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
  });
}
