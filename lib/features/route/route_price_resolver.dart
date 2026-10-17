import '../../models/list_item.dart';
import '../../models/market_price.dart';
import '../../models/offer.dart';
import '../../models/store.dart';
import '../../models/product.dart';
import '../offers/effective_price.dart';
import '../offers/offer_import.dart';
import '../offers/offer_filter.dart';
import '../shopping_list/shopping_intent.dart';
import '../../services/branch_identity.dart';
import '../../services/store_identity.dart';
import '../../services/market_price_comparability.dart';
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
    this.openPricesMaxAgeDays = 60,
  }) : marketPrices = preferredMarketPricesByKey(
         marketPrices,
         now ?? DateTime.now(),
         openPricesMaxAgeDays: openPricesMaxAgeDays,
       ),
       _marketPriceCandidates = _usableMarketPriceCandidates(
         marketPrices,
         now ?? DateTime.now(),
         openPricesMaxAgeDays,
       );

  final List<Offer> offers;
  final DateTime? now;
  final int openPricesMaxAgeDays;
  final Map<String, MarketPrice> marketPrices;
  final List<MarketPrice> _marketPriceCandidates;

  // The optimizer evaluates each market/product/quantity combination more
  // than once while building alternatives. Quotes are immutable for one
  // resolver instance, including null results for missing evidence.
  final Map<String, RoutePriceQuote?> _quoteCache =
      <String, RoutePriceQuote?>{};

  RoutePriceQuote? quote(Store store, ListItem item) {
    final key = _quoteCacheKey(store, item);
    if (_quoteCache.containsKey(key)) return _quoteCache[key];
    final result = _resolveQuote(store, item);
    _quoteCache[key] = result;
    return result;
  }

  RoutePriceQuote? _resolveQuote(Store store, ListItem item) {
    if (isGenericShoppingIntent(item.product)) return null;
    final offer = _bestOffer(store, item.product, item.quantity);
    final customPrice = _bestMarketPrice(store, item.product);
    final catalogPrice = store.prices[item.product.id];
    final observed =
        customPrice?.price ??
        catalogPrice ??
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
    if (offerTotal >= regularTotal &&
        (offer.originalPriceVerified ||
            customPrice != null ||
            catalogPrice != null)) {
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
          _sameRouteStoreLabel(offer.storeName, store.name) &&
          offerMatchesProduct(offer, product) &&
          _offerBelongsToStore(offer, store) &&
          hasExactOfferBranch(offer) &&
          hasTrustedOfferEvidence(offer) &&
          !isSampleOffer(offer) &&
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
      if (price < bestPrice ||
          (price == bestPrice &&
              (best == null || _compareOfferTie(offer, best) < 0))) {
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

  MarketPrice? _bestMarketPrice(Store store, Product product) {
    final candidates = _marketPriceCandidates.where(
      (price) =>
          price.productId == product.id &&
          _sameRouteStoreLabel(price.storeName, store.name) &&
          marketPriceMatchesProduct(price, product),
    );
    final branchId = canonicalBranchId(store.branchId);
    final exact = branchId == null
        ? candidates.where((price) => !_hasSourceLocation(price))
        : candidates.where(
            (price) => canonicalBranchId(price.sourceLocationId) == branchId,
          );
    final scoped = exact.isNotEmpty
        ? exact
        : candidates.where((price) => !_hasSourceLocation(price));
    MarketPrice? best;
    final reference = now ?? DateTime.now();
    for (final price in scoped) {
      final previous = best;
      if (previous == null ||
          compareMarketPriceEvidence(price, previous, reference) < 0) {
        best = price;
      }
    }
    return best;
  }
}

String _quoteCacheKey(Store store, ListItem item) => [
  store.name,
  canonicalBranchId(store.branchId) ?? '',
  store.location,
  store.address,
  store.prices[item.product.id]?.toString() ?? '',
  item.product.id,
  item.quantity.toString(),
].join('\\u0000');

List<MarketPrice> _usableMarketPriceCandidates(
  Iterable<MarketPrice> prices,
  DateTime now,
  int openPricesMaxAgeDays,
) => prices
    .where(
      (price) =>
          !price.isProspectOffer &&
          price.price.isFinite &&
          price.price > 0 &&
          price.isUsable(
            now: now,
            openPricesMaxAgeDays: openPricesMaxAgeDays,
          ),
    )
    .toList(growable: false);

bool _hasSourceLocation(MarketPrice price) =>
    canonicalBranchId(price.sourceLocationId) != null;

bool _offerBelongsToStore(Offer offer, Store store) {
  final offerBranch = canonicalBranchId(offer.locationId);
  if (offerBranch == null) return true;
  final storeBranch = canonicalBranchId(store.branchId);
  return storeBranch != null && offerBranch == storeBranch;
}

int _compareOfferTie(Offer candidate, Offer previous) {
  final candidateVerification = candidate.originalPriceVerified ? 0 : 1;
  final previousVerification = previous.originalPriceVerified ? 0 : 1;
  final verification = candidateVerification.compareTo(previousVerification);
  if (verification != 0) return verification;

  for (final comparison in [
    _compareOfferText(candidate.sourceAdapter, previous.sourceAdapter),
    _compareOfferText(candidate.source, previous.source),
    _compareOfferText(candidate.proofRef, previous.proofRef),
    candidate.id.compareTo(previous.id),
  ]) {
    if (comparison != 0) return comparison;
  }
  return 0;
}

int _compareOfferText(String? candidate, String? previous) {
  if (candidate == null && previous == null) return 0;
  if (candidate == null) return 1;
  if (previous == null) return -1;
  return candidate.trim().toLowerCase().compareTo(previous.trim().toLowerCase());
}




/// Matches only presentation-level retailer spelling differences.
///
/// Store branches remain protected by the exact branch comparison in
/// [_offerBelongsToStore] and [_bestMarketPrice]. This helper does not merge
/// arbitrary aliases or substrings; it only aligns case, punctuation,
/// diacritics, and the common ae/oe/ue transliterations used by public feeds.
bool _sameRouteStoreLabel(String candidate, String configured) {
  String key(String value) => normalizeStoreIdentityText(value)
      .replaceAll('ae', 'a')
      .replaceAll('oe', 'o')
      .replaceAll('ue', 'u');
  final candidateKey = key(candidate);
  final configuredKey = key(configured);
  return candidateKey.isNotEmpty && candidateKey == configuredKey;
}
