import '../../models/list_item.dart';
import '../../models/market_price.dart';
import '../../models/offer.dart';
import '../../models/store.dart';
import '../../models/product.dart';
import '../offers/effective_price.dart';

class RoutePriceQuote {
  const RoutePriceQuote({
    required this.unitPrice,
    required this.total,
    required this.regularTotal,
    this.offer,
    this.isEstimated = false,
  });

  final double unitPrice;
  final double total;
  final double regularTotal;
  final Offer? offer;
  /// True when no observed/store price was available and a category estimate
  /// was used. Estimates are deliberately exposed to the UI.
  final bool isEstimated;

  bool get usesOffer => offer != null;
  double get savings => regularTotal - total;
}

class RoutePriceResolver {
  RoutePriceResolver(
    this.offers, {
    this.now,
    List<MarketPrice> marketPrices = const <MarketPrice>[],
  }) : marketPrices = {
          for (final price in marketPrices) price.key: price.price,
        },
        observedProductPrices = {
          for (final price in marketPrices)
            price.productId: [
              ...marketPrices
                  .where((candidate) => candidate.productId == price.productId)
                  .map((candidate) => candidate.price),
            ],
        };

  final List<Offer> offers;
  final DateTime? now;
  final Map<String, double> marketPrices;
  final Map<String, List<double>> observedProductPrices;

  RoutePriceQuote? quote(Store store, ListItem item) {
    final offer = _bestOffer(store, item.product, item.quantity);
    final customPrice = marketPrices['${store.name}|${item.product.id}'];
    final observed =
        customPrice ?? store.prices[item.product.id] ?? offer?.originalPrice;
    final regular = observed ?? _estimate(item.product);
    final isEstimated = observed == null;
    if (offer == null) {
      return RoutePriceQuote(
        unitPrice: regular,
        total: regular * item.quantity,
        regularTotal: regular * item.quantity,
        isEstimated: isEstimated,
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
        isEstimated: isEstimated,
      );
    }

    return RoutePriceQuote(
      unitPrice: effective,
      total: offerTotal,
      regularTotal: regularTotal,
      offer: offer,
      isEstimated: isEstimated,
    );
  }

  double _estimate(Product product) {
    final observed = observedProductPrices[product.id];
    if (observed != null && observed.isNotEmpty) {
      final sorted = [...observed]..sort();
      final middle = sorted.length ~/ 2;
      return sorted.length.isOdd
          ? sorted[middle]
          : (sorted[middle - 1] + sorted[middle]) / 2;
    }
    return switch (product.group) {
        'butter' => 1.89,
        'milch' => 1.29,
        'obst' => 1.59,
        'fleisch' => 4.99,
        'nudeln' => 0.89,
        _ => 2.49,
      };
  }

  Offer? _bestOffer(Store store, Product product, int quantity) {
    final today = now ?? DateTime.now();
    final matches = offers.where(
      (offer) =>
          _matchesProduct(offer, product) &&
          offer.storeName == store.name &&
          !offer.validUntil.isBefore(DateTime(today.year, today.month, today.day)),
    );

    Offer? best;
    var bestPrice = double.infinity;
    for (final offer in matches) {
      final price = effectivePrice(offer).finalPrice *
          _paidUnits(quantity, offer);
      if (price < bestPrice) {
        best = offer;
        bestPrice = price;
      }
    }
    return best;
  }

  bool _matchesProduct(Offer offer, Product product) {
    if (offer.productId == product.id) return true;
    final productWords = _words('${product.name} ${product.aliases.join(' ')}');
    final offerWords = _words(offer.productId);
    return productWords.any(offerWords.contains);
  }

  Set<String> _words(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9äöüß ]'), ' ')
      .split(RegExp(r'\s+|_'))
      .where((word) => word.length >= 4)
      .toSet();

  int _paidUnits(int quantity, Offer offer) {
    final buy = offer.buyQuantity;
    final pay = offer.payQuantity;
    if (buy == null || pay == null || buy <= 0 || pay < 0 || pay >= buy) {
      return quantity;
    }
    return (quantity ~/ buy) * pay + quantity % buy;
  }
}
