import '../../models/offer.dart';

double? couponPrice(Offer offer) {
  if (!offer.hasCoupon) return null;

  var price = offer.offerPrice;
  if (offer.couponPercent != null) {
    price *= 1 - offer.couponPercent!.clamp(0, 100).toDouble() / 100;
  }
  if (offer.couponAmount != null) {
    price -= offer.couponAmount!.clamp(0, price).toDouble();
  }

  return double.parse(price.toStringAsFixed(2));
}

String couponLabel(Offer offer) {
  if (offer.couponPercent != null) {
    return '${_number(offer.couponPercent!)} % Coupon';
  }
  if (offer.couponAmount != null) {
    return '${offer.couponAmount!.toStringAsFixed(2)} € Coupon';
  }
  return 'Coupon';
}

String _number(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);
