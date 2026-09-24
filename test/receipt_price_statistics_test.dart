import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/receipt/receipt_price_statistics.dart';
import 'package:sparzamapp/models/receipt_observation.dart';

ReceiptObservation obs({
  required String id,
  required double price,
  double? unitPrice,
  bool discounted = false,
  String store = 'Kaufland',
  String family = 'hackfleisch',
  int day = 20,
}) =>
    ReceiptObservation(
      id: id,
      receiptFingerprint: 'bon$id',
      rowLine: 1,
      rawLabel: 'Hackfleisch',
      familyKey: family,
      storeName: store,
      observedAt: DateTime(2026, 9, day),
      totalPrice: price,
      quantity: null,
      quantityUnit: 'Stück',
      unitPrice: unitPrice,
      discounted: discounted,
    );

void main() {
  test('uses robust median and ignores discounted observations', () {
    final stats = buildReceiptPriceStats([
      obs(id: '1', price: 4.49),
      obs(id: '2', price: 4.79, day: 21),
      obs(id: '3', price: 9.99, discounted: true, day: 22),
    ], now: DateTime(2026, 9, 24));

    expect(stats.single.medianPrice, 4.64);
    expect(stats.single.observationCount, 2);
    expect(stats.single.comparable, isFalse);
  });

  test('unit prices are comparable when every observation has one', () {
    final stats = buildReceiptPriceStats([
      obs(id: '1', price: 2, unitPrice: 4),
      obs(id: '2', price: 2.5, unitPrice: 5, day: 21),
      obs(id: '3', price: 3, unitPrice: 6, day: 22),
    ], now: DateTime(2026, 9, 24));

    expect(stats.single.medianPrice, 5);
    expect(stats.single.latestPrice, 6);
    expect(stats.single.comparable, isTrue);
  });

  test('drops stale observations', () {
    final stats = buildReceiptPriceStats([
      obs(id: 'old', price: 4.79, day: 1),
    ], now: DateTime(2027, 1, 24));
    expect(stats, isEmpty);
  });


  test('repairs stale family keys from raw labels for every product', () {
    final stats = buildReceiptPriceStats([
      ReceiptObservation(
        id: 'legacy-schmand',
        receiptFingerprint: 'bon-schmand',
        rowLine: 7,
        rawLabel: 'Schmand',
        familyKey: 'receipt_auto_old_id',
        storeName: 'Kaufland',
        observedAt: DateTime(2026, 9, 23),
        totalPrice: 0.99,
        quantity: null,
        quantityUnit: 'Stück',
        unitPrice: null,
        discounted: false,
        productId: 'receipt_auto_old_id',
      ),
    ], now: DateTime(2026, 9, 24));

    expect(stats.single.familyKey, 'schmand');
    expect(stats.single.productId, 'receipt_auto_old_id');
    expect(stats.single.medianPrice, 0.99);
  });

  test('keeps assigned variants in separate price histories', () {
    ReceiptObservation assigned(String id, String productId, double price) =>
        ReceiptObservation(
          id: id,
          receiptFingerprint: 'bon$id',
          rowLine: 1,
          rawLabel: 'K.H-Milch',
          familyKey: 'milch',
          storeName: 'Kaufland',
          observedAt: DateTime(2026, 9, 23),
          totalPrice: price,
          quantity: null,
          quantityUnit: 'Stück',
          unitPrice: null,
          discounted: false,
          productId: productId,
        );

    final stats = buildReceiptPriceStats([
      assigned('1', 'milch_15', 0.85),
      assigned('2', 'milch_35', 0.95),
    ], now: DateTime(2026, 9, 24));

    expect(stats, hasLength(2));
    expect(stats.map((item) => item.productId).toSet(),
        {'milch_15', 'milch_35'});
  });
}