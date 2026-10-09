import '../../models/list_item.dart';
import '../../models/market_price.dart';
import '../../models/offer.dart';
import '../../models/store.dart';
import '../../models/product.dart';
import '../offers/effective_price.dart';
import '../shopping_list/shopping_intent.dart';
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

  /// Legacy marker kept for callers that distinguish estimated quotes. Missing
  /// evidence now returns `null`, so the resolver never creates a synthetic
  /// category estimate.
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
         marketPrices,
         now ?? DateTime.now(),
       );

  final List<Offer> offers;
  final DateTime? now;
  final Map<String, MarketPrice> marketPrices;

  RoutePriceQuote? quote(Store store, ListItem item) {
    if (isGenericShoppingIntent(item.product)) return null;
    final offer = _bestOffer(store, item.product, item.quantity);
    final customPrice = marketPrices['${store.name}|${item.product.id}'];
    final observed =
        customPrice?.price ??
        store.prices[item.product.id] ??
        (offer == null
            ? null
            : offer.originalPriceVerified
            ? offer.originalPrice
            : offer.offerPrice);
    // A missing market-specific observation is a data gap. Do not create a
    // category fallback price here: it would look like evidence and could be
    // displayed next to real prices even though no source supports it.
    if (observed == null || !observed.isFinite || observed <= 0) return null;
    final regular = observed;
    if (offer == null) {
      return RoutePriceQuote(
        unitPrice: regular,
        total: regular * item.quantity,
        regularTotal: regular * item.quantity,
        observation: customPrice,
      );
    }

    final effective = effectivePrice(offer).finalPrice;
    final paidUnits = _paidUnits(item.quantity, offer);
    final offerTotal = effective * paidUnits;
    final regularTotal = regular * item.quantity;

    // A current market observation is still the comparison basis when the
    // offer's regular price is unverified. Never route to an active offer
    // that would cost more than the price we can actually substantiate.
    if (offerTotal >= regularTotal) {
      return RoutePriceQuote(
        unitPrice: regular,
        total: regularTotal,
        regularTotal: regularTotal,
        observation: customPrice,
      );
    }

    return RoutePriceQuote(
      unitPrice: effective,
      total: offerTotal,
      regularTotal: regularTotal,
      offer: offer,
      observation: customPrice,
    );
  }

  Offer? _bestOffer(Store store, Product product, int quantity) {
    final today = now ?? DateTime.now();
    final matches = offers.where(
      (offer) =>
          offer.productId == product.id &&
          offer.storeName == store.name &&
          (offer.validFrom == null ||
              !DateTime(today.year, today.month, today.day).isBefore(
                DateTime(
                  offer.validFrom!.year,
                  offer.validFrom!.month,
                  offer.validFrom!.day,
                ),
              )) &&
          !offer.validUntil.isBefore(
            DateTime(today.year, today.month, today.day),
          ),
    );

    Offer? best;
    var bestPrice = double.infinity;
    for (final offer in matches) {
      final price =
          effectivePrice(offer).finalPrice * _paidUnits(quantity, offer);
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
    if (!offer.hasMultiBuy || buy == null || pay == null) {
      return quantity;
    }
    return (quantity ~/ buy) * pay + quantity % buy;
  }
}
