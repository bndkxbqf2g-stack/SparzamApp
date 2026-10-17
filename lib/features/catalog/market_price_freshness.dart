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
            price.isProspectRegularBasis &&
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
    required this.unclassifiedProspectEvidence,
    required this.prospectOfferEvidence,
    required this.currentReceipt,
    required this.currentManual,
    required this.currentOpenPrices,
    required this.currentByStore,
    required this.currentByStoreLocation,
    required this.futureEvidence,
    required this.staleEvidence,
    required this.identityUncertainEvidence,
    required this.incomparableEvidence,
    required this.invalidAmountEvidence,
    required this.lowConfidenceEvidence,
  });

  final int total;
  final int current;
  final int notRouteReady;
  final int currentProspectRegular;

  /// Prospect rows without an explicit price role remain visible as evidence
  /// gaps and never count as current regular prices.
  final int unclassifiedProspectEvidence;

  /// Legacy or manually imported prospect offer evidence. It is reported
  /// separately so an offer amount cannot be mistaken for a regular price.
  final int prospectOfferEvidence;

  final int currentReceipt;
  final int currentManual;
  final int currentOpenPrices;
  final Map<String, int> currentByStore;

  /// Current evidence split by the exact branch when the source supplied one.
  /// A missing branch remains grouped under the store label only.
  final Map<String, int> currentByStoreLocation;

  /// Primary data-gap reason counts. Each non-current row is counted once so
  /// the sum remains explainable alongside [notRouteReady].
  final int futureEvidence;
  final int staleEvidence;
  final int identityUncertainEvidence;
  final int incomparableEvidence;
  final int invalidAmountEvidence;
  final int lowConfidenceEvidence;

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
  var unclassifiedProspectEvidence = 0;
  var prospectOfferEvidence = 0;
  var currentReceipt = 0;
  var currentManual = 0;
  var currentOpenPrices = 0;
  var futureEvidence = 0;
  var staleEvidence = 0;
  var identityUncertainEvidence = 0;
  var incomparableEvidence = 0;
  var invalidAmountEvidence = 0;
  var lowConfidenceEvidence = 0;
  final currentByStore = <String, int>{};
  final currentByStoreLocation = <String, int>{};

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
    // Unknown prospect rows are evidence gaps, never current regular prices.
    if (!price.isProspectRegularBasis) {
      unclassifiedProspectEvidence++;
      continue;
    }

    // Keep one primary reason per rejected observation. This makes the UI
    // explainable without changing the route's central eligibility checks.
    if (!price.price.isFinite || price.price <= 0) {
      invalidAmountEvidence++;
      continue;
    }
    final today = DateTime(reference.year, reference.month, reference.day);
    final observed = DateTime(
      price.updatedAt.year,
      price.updatedAt.month,
      price.updatedAt.day,
    );
    if (observed.isAfter(today)) {
      futureEvidence++;
      continue;
    }
    if (!price.identityConfidence.isFinite || price.identityConfidence < 1) {
      identityUncertainEvidence++;
      continue;
    }
    if (!price.hasComparableBasis) {
      incomparableEvidence++;
      continue;
    }
    if (price.evidenceConfidence == EvidenceConfidence.probable ||
        price.evidenceConfidence == EvidenceConfidence.uncertain) {
      lowConfidenceEvidence++;
      continue;
    }
    if (!price.isUsable(
      now: reference,
      openPricesMaxAgeDays: openPricesMaxAgeDays,
    )) {
      staleEvidence++;
      continue;
    }

    current++;
    currentByStore.update(
      price.storeName,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    final locationId = price.sourceLocationId?.trim();
    final storeLocation = locationId == null || locationId.isEmpty
        ? price.storeName
        : price.storeName + ' · ' + locationId;
    currentByStoreLocation.update(
      storeLocation,
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
    unclassifiedProspectEvidence: unclassifiedProspectEvidence,
    prospectOfferEvidence: prospectOfferEvidence,
    currentReceipt: currentReceipt,
    currentManual: currentManual,
    currentOpenPrices: currentOpenPrices,
    currentByStore: Map.unmodifiable(currentByStore),
    currentByStoreLocation: Map.unmodifiable(currentByStoreLocation),
    futureEvidence: futureEvidence,
    staleEvidence: staleEvidence,
    identityUncertainEvidence: identityUncertainEvidence,
    incomparableEvidence: incomparableEvidence,
    invalidAmountEvidence: invalidAmountEvidence,
    lowConfidenceEvidence: lowConfidenceEvidence,
  );
}
