import '../../models/offer.dart';

double cashbackValue(Offer offer, double price) {
  if (!offer.hasCashback) return 0;

  var value = 0.0;
  if (offer.cashbackPercent != null) {
    value += price * offer.cashbackPercent!.clamp(0, 100).toDouble() / 100;
  }
  if (offer.cashbackAmount != null) value += offer.cashbackAmount!;

  return double.parse(value.clamp(0, price).toStringAsFixed(2));
}

String cashbackLabel(Offer offer) {
  if (offer.cashbackPercent != null) {
    return '${_number(offer.cashbackPercent!)} % Cashback';
  }
  if (offer.cashbackAmount != null) {
    return '${offer.cashbackAmount!.toStringAsFixed(2)} € Cashback';
  }
  return 'Cashback';
}

String _number(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);
