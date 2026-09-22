import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/offers/effective_price.dart';
import 'package:sparzamapp/models/offer.dart';

void main() {
  test('Coupon und Cashback werden in richtiger Reihenfolge berechnet', () {
    final offer = Offer(
      id: 'test',
      productId: 'test',
      storeName: 'Testmarkt',
      originalPrice: 10,
      offerPrice: 8,
      validUntil: DateTime(2026, 12, 31),
      couponPercent: 10,
      cashbackPercent: 25,
    );

    final price = effectivePrice(offer);

    expect(price.checkout, 7.20);
    expect(price.cashback, 1.80);
    expect(price.finalPrice, 5.40);
  });

  test('Cashback kann den Kassenpreis nicht unterschreiten', () {
    final offer = Offer(
      id: 'test',
      productId: 'test',
      storeName: 'Testmarkt',
      originalPrice: 5,
      offerPrice: 4,
      validUntil: DateTime(2026, 12, 31),
      cashbackAmount: 10,
    );

    final price = effectivePrice(offer);

    expect(price.cashback, 4);
    expect(price.finalPrice, 0);
  });
}
