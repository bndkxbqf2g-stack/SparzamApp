import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/offers/price_evaluator.dart';
import 'package:sparzamapp/models/offer.dart';
import 'package:sparzamapp/models/price_point.dart';

void main() {
  test('Preisampel nutzt 90-Tage-Historie statt sehr alter Bestpreise', () {
    final now = DateTime(2026, 9, 22);
    final offer = Offer(
      id: 'offer',
      productId: 'milk',
      storeName: 'Lidl',
      originalPrice: 1.49,
      offerPrice: 1.09,
      validUntil: DateTime(2026, 9, 30),
    );
    final history = [
      PricePoint(
        productId: 'milk',
        storeName: 'Lidl',
        price: 0.79,
        date: now.subtract(const Duration(days: 200)),
      ),
      PricePoint(
        productId: 'milk',
        storeName: 'Lidl',
        price: 1.29,
        date: now.subtract(const Duration(days: 20)),
      ),
      PricePoint(
        productId: 'milk',
        storeName: 'Lidl',
        price: 1.39,
        date: now.subtract(const Duration(days: 10)),
      ),
    ];

    final evaluation = evaluatePrice(
      offer,
      history,
      now: now,
    );

    expect(evaluation.best90Price, 1.29);
    expect(evaluation.bestPrice, 1.29);
    expect(evaluation.normalPrice, closeTo(1.34, 0.001));
    expect(evaluation.level, PriceLevel.great);
  });
}
