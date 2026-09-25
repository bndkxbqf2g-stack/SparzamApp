import '../../models/offer.dart';
import 'cashback_calculator.dart';
import 'coupon_calculator.dart';

class EffectivePrice {
  const EffectivePrice({
    required this.checkout,
    required this.cashback,
    required this.finalPrice,
  });

  final double checkout;
  final double cashback;
  final double finalPrice;
}

EffectivePrice effectivePrice(Offer offer) {
  final checkout = couponPrice(offer) ?? offer.offerPrice;
  final cashback = cashbackValue(offer, checkout);
  final finalPrice = double.parse((checkout - cashback).toStringAsFixed(2));
  return EffectivePrice(
    checkout: checkout,
    cashback: cashback,
    finalPrice: finalPrice,
  );
}
