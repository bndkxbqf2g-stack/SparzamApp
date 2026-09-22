import '../../models/list_item.dart';
import '../../models/offer.dart';
import '../../models/store.dart';
import '../offers/effective_price.dart';

class RoutePriceQuote {
  const RoutePriceQuote({
    required this.unitPrice,
    required this.total,
    required this.regularTotal,
    this.offer,
  });

  final double unitPrice;
  final double total;
  final double regularTotal;
  final Offer? offer;

  bool get usesOffer => offer != null;
  double get savings => regularTotal - total;
}

class RoutePriceResolver {
  const RoutePriceResolver(this.offers, {this.now});

  final List<Offer> offers;
  final DateTime? now;

  RoutePriceQuote? quote(Store store, ListItem item) {
    final regular = store.prices[item.product.id];
    if (regular == null) return null;

    final offer = _bestOffer(store, item.product.id);
    if (offer == null) {
      return RoutePriceQuote(
        unitPrice: regular,
        total: regular * item.quantity,
        regularTotal: regular * item.quantity,
      );
    }

    final effective = effectivePrice(offer).finalPrice;
    final paidUnits = _paidUnits(item.quantity, offer);
    final offerTotal = effective * paidUnits;
    final regularTotal = regular * item.quantity;

    if (offerTotal >= regularTotal) {
      return RoutePriceQuote(
        unitPrice: regular,
        total: regularTotal,
        regularTotal: regularTotal,
      );
    }

    return RoutePriceQuote(
      unitPrice: effective,
      total: offerTotal,
      regularTotal: regularTotal,
      offer: offer,
    );
  }

  Offer? _bestOffer(Store store, String productId) {
    final today = now ?? DateTime.now();
    final matches = offers.where(
      (offer) =>
          offer.productId == productId &&
          offer.storeName == store.name &&
          !offer.validUntil.isBefore(DateTime(today.year, today.month, today.day)),
    );

    Offer? best;
    var bestPrice = double.infinity;
    for (final offer in matches) {
      final price = effectivePrice(offer).finalPrice;
      if (price < bestPrice) {
        best = offer;
        bestPrice = price;
      }
    }
    return best;
  }

  int _paidUnits(int quantity, Offer offer) {
    final buy = offer.buyQuantity;
    final pay = offer.payQuantity;
    if (buy == null || pay == null || buy <= 0 || pay < 0 || pay >= buy) {
      return quantity;
    }
    return (quantity ~/ buy) * pay + quantity % buy;
  }
}
