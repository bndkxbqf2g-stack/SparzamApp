import '../../models/market_price.dart';
import '../../models/price_observation.dart';

List<MarketPrice> usableMarketPrices(
  List<MarketPrice> prices, {
  required int openPricesMaxAgeDays,
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  return prices
      .where(
        (price) =>
            !price.isProspectOffer &&
            price.isUsable(
              now: today,
              openPricesMaxAgeDays: openPricesMaxAgeDays,
            ),
      )
      .toList(growable: false);
}

/// Aggregated, route-safe view of locally stored market-price evidence.
///
/// Only [MarketPrice.isUsable] prices count as current. Old, future,
/// incomplete or identity-uncertain observations remain visible as gaps and
/// never inflate route coverage.
class PriceDataQuality {
  const PriceDataQuality({
    required this.total,
    required this.current,
    required this.notRouteReady,
    required this.currentProspectRegular,
    required this.prospectOfferEvidence,
    required this.currentReceipt,
    required this.currentManual,
    required this.currentOpenPrices,
    required this.currentByStore,
  });

  final int total;
  final int current;
  final int notRouteReady;
  final int currentProspectRegular;

  /// Legacy or manually imported prospect offer evidence. It is reported
  /// separately so an offer amount cannot be mistaken for a regular price.
  final int prospectOfferEvidence;

  final int currentReceipt;
  final int currentManual;
  final int currentOpenPrices;
  final Map<String, int> currentByStore;

  bool get hasData => total > 0;
}

PriceDataQuality calculatePriceDataQuality(
  Iterable<MarketPrice> prices, {
  required int openPricesMaxAgeDays,
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  var total = 0;
  var current = 0;
  var currentProspectRegular = 0;
  var prospectOfferEvidence = 0;
  var currentReceipt = 0;
  var currentManual = 0;
  var currentOpenPrices = 0;
  final currentByStore = <String, int>{};

  for (final price in prices) {
    total++;
    if (price.isProspectOffer) {
      // Covers both current records with kind=offer and legacy rows whose
      // discounted flag is the only available offer marker.
      prospectOfferEvidence++;
    }

    // Offer evidence remains visible in the quality breakdown, but it is
    // never a current route-ready price. Keep it out of both the current
    // count and the per-store coverage just like usableMarketPrices().
    if (price.isProspectOffer) {
      continue;
    }

    if (!price.isUsable(
      now: reference,
      openPricesMaxAgeDays: openPricesMaxAgeDays,
    )) {
      continue;
    }

    current++;
    currentByStore.update(
      price.storeName,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    switch (price.source) {
      case MarketPriceSource.prospect:
        if (price.kind == PriceObservationKind.regular) {
          currentProspectRegular++;
        }
      case MarketPriceSource.receipt:
        currentReceipt++;
      case MarketPriceSource.manual:
        currentManual++;
      case MarketPriceSource.openPrices:
        currentOpenPrices++;
    }
  }

  return PriceDataQuality(
    total: total,
    current: current,
    notRouteReady: total - current,
    currentProspectRegular: currentProspectRegular,
    prospectOfferEvidence: prospectOfferEvidence,
    currentReceipt: currentReceipt,
    currentManual: currentManual,
    currentOpenPrices: currentOpenPrices,
    currentByStore: Map.unmodifiable(currentByStore),
  );
}
