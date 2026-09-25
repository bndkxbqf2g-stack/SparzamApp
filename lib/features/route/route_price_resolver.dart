import '../../models/list_item.dart';
import '../../models/market_price.dart';
import '../../models/offer.dart';
import '../../models/store.dart';
import '../../models/product.dart';
import '../offers/effective_price.dart';
import 'market_price_selection.dart';

class RoutePriceQuote {
  const RoutePriceQuote({
    required this.unitPrice,
    required this.total,
    required this.regularTotal,
    this.offer,
    this.isEstimated = false,
    this.observation,
  });

  final double unitPrice;
  final double total;
  final double regularTotal;
  final Offer? offer;
  /// True when no observed/store price was available and a category estimate
  /// was used. Estimates are deliberately exposed to the UI.
  final bool isEstimated;
  /// Source of the selected market-specific price, if available.
  final MarketPrice? observation;

  bool get usesOffer => offer != null;
  double get savings => regularTotal - total;
}

class RoutePriceResolver {
  RoutePriceResolver(
    this.offers, {
    this.now,
    List<MarketPrice> marketPrices = const <MarketPrice>[],
  }) : marketPrices = preferredMarketPricesByKey(
            marketPrices, now ?? DateTime.now()),
        observedProductPrices =
            _observedPrices(marketPrices, now ?? DateTime.now());

  final List<Offer> offers;
  final DateTime? now;
  final Map<String, MarketPrice> marketPrices;
  final Map<String, List<double>> observedProductPrices;

  RoutePriceQuote? quote(Store store, ListItem item) {
    final offer = _bestOffer(store, item.product, item.quantity);
    final customPrice = marketPrices['${store.name}|${item.product.id}'];
    final observed = customPrice?.price ??
        store.prices[item.product.id] ??
        (offer == null
            ? null
            : offer.originalPriceVerified
                ? offer.originalPrice
                : offer.offerPrice);
    final regular = observed ?? _estimate(item.product);
    final isEstimated = observed == null;
    if (offer == null) {
      return RoutePriceQuote(
        unitPrice: regular,
        total: regular * item.quantity,
        regularTotal: regular * item.quantity,
        isEstimated: isEstimated,
        observation: customPrice,
      );
    }

    final effective = effectivePrice(offer).finalPrice;
    final paidUnits = _paidUnits(item.quantity, offer);
    final offerTotal = effective * paidUnits;
    final regularTotal = regular * item.quantity;

    if (offerTotal >= regularTotal && offer.originalPriceVerified) {
      return RoutePriceQuote(
        unitPrice: regular,
        total: regularTotal,
        regularTotal: regularTotal,
        isEstimated: isEstimated,
        observation: customPrice,
      );
    }

    return RoutePriceQuote(
      unitPrice: effective,
      total: offerTotal,
      regularTotal: regularTotal,
      offer: offer,
      isEstimated: isEstimated,
      observation: customPrice,
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
          offer.productId == product.id &&
          offer.storeName == store.name &&
          (offer.validFrom == null ||
              !DateTime(today.year, today.month, today.day)
                  .isBefore(DateTime(offer.validFrom!.year,
                      offer.validFrom!.month, offer.validFrom!.day))) &&
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

  static Map<String, List<double>> _observedPrices(
      List<MarketPrice> input, DateTime now) {
    final eligible = input.where((price) {
      if (!price.price.isFinite || price.price <= 0) return false;
      if (price.source == MarketPriceSource.receipt &&
          !price.isUsable(now: now, openPricesMaxAgeDays: 36500)) {
        return false;
      }
      return true;
    }).toList();
    return {
      for (final price in eligible)
        price.productId: [
          ...eligible
              .where((candidate) => candidate.productId == price.productId)
              .map((candidate) => candidate.price),
        ],
    };
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
