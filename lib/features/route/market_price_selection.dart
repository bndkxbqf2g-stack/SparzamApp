import '../../models/market_price.dart';
import '../../services/branch_identity.dart';
import '../../services/market_price_source_priority.dart';
import 'market_price_quality.dart';

/// Provides a stable choice when two usable prices have the same quality
/// score and observation timestamp.
///
/// The price and freshness rules remain the primary ranking. This comparator
/// only resolves an otherwise arbitrary input-order dependency and therefore
/// never makes an older or less usable observation routable.
int compareMarketPriceTieBreakers(
  MarketPrice candidate,
  MarketPrice previous,
) {
  final source = marketPriceSourcePriority(candidate.source)
      .compareTo(marketPriceSourcePriority(previous.source));
  if (source != 0) return source;

  final adapter = _compareOptionalText(
    candidate.sourceAdapter,
    previous.sourceAdapter,
  );
  if (adapter != 0) return adapter;

  final locationId = _compareOptionalText(
    candidate.sourceLocationId,
    previous.sourceLocationId,
  );
  if (locationId != 0) return locationId;

  final externalId =
      _compareOptionalInt(candidate.externalId, previous.externalId);
  if (externalId != 0) return externalId;

  final proof = _compareOptionalText(candidate.proofRef, previous.proofRef);
  if (proof != 0) return proof;

  final locationName = _compareOptionalText(
    candidate.sourceLocationName,
    previous.sourceLocationName,
  );
  if (locationName != 0) return locationName;

  final quantity =
      _compareOptionalDouble(candidate.quantity, previous.quantity);
  if (quantity != 0) return quantity;
  final unit = _compareOptionalText(candidate.unit, previous.unit);
  if (unit != 0) return unit;
  final unitPrice =
      _compareOptionalDouble(candidate.unitPrice, previous.unitPrice);
  if (unitPrice != 0) return unitPrice;
  return candidate.discounted == previous.discounted
      ? 0
      : candidate.discounted
      ? 1
      : -1;
}

int _compareOptionalText(String? candidate, String? previous) {
  if (candidate == null && previous == null) return 0;
  if (candidate == null) return 1;
  if (previous == null) return -1;
  return candidate.trim().toLowerCase().compareTo(previous.trim().toLowerCase());
}

int _compareOptionalInt(int? candidate, int? previous) {
  if (candidate == null && previous == null) return 0;
  if (candidate == null) return 1;
  if (previous == null) return -1;
  return candidate.compareTo(previous);
}

int _compareOptionalDouble(double? candidate, double? previous) {
  if (candidate == null && previous == null) return 0;
  if (candidate == null) return 1;
  if (previous == null) return -1;
  return candidate.compareTo(previous);
}

/// Compares two already validated market-price observations.
///
/// A lower quality-adjusted amount wins first. When the adjusted amounts tie,
/// the newer observation wins. Only an exact amount-and-age tie reaches the
/// source precedence and deterministic metadata tie-breakers.
int compareMarketPriceEvidence(
  MarketPrice candidate,
  MarketPrice previous,
  DateTime now,
) {
  final candidateScore = candidate.price *
      (1 + marketPriceQuality(candidate, now).uncertaintyRate);
  final previousScore = previous.price *
      (1 + marketPriceQuality(previous, now).uncertaintyRate);
  final byScore = candidateScore.compareTo(previousScore);
  if (byScore != 0) return byScore;

  final byFreshness = previous.updatedAt.compareTo(candidate.updatedAt);
  if (byFreshness != 0) return byFreshness;

  return compareMarketPriceTieBreakers(candidate, previous);
}

/// Selects one route-usable price per store/product key using the same
/// quality-adjusted score everywhere the planning projection needs to collapse
/// exact history. Source-specific freshness, including the configured
/// Open Prices age, is enforced before ranking.
Map<String, MarketPrice> preferredMarketPricesByKey(
  Iterable<MarketPrice> input,
  DateTime now, {
  int openPricesMaxAgeDays = 60,
}) =>
    _preferredMarketPrices(
      input,
      now,
      openPricesMaxAgeDays: openPricesMaxAgeDays,
      keyOf: (price) => price.key,
    );

/// Keeps separate exact branch observations available for route resolution.
///
/// The legacy projection collapses to one store/product value for screens
/// that do not select a branch. Planning must retain source locations so a
/// cheaper price from another filial cannot leak into the selected market.
Map<String, MarketPrice> preferredMarketPricesByKeyAndLocation(
  Iterable<MarketPrice> input,
  DateTime now, {
  int openPricesMaxAgeDays = 60,
}) =>
    _preferredMarketPrices(
      input,
      now,
      openPricesMaxAgeDays: openPricesMaxAgeDays,
      keyOf: (price) =>
          '${price.key}|${canonicalBranchId(price.sourceLocationId) ?? ''}',
    );

Map<String, MarketPrice> _preferredMarketPrices(
  Iterable<MarketPrice> input,
  DateTime now, {
  required int openPricesMaxAgeDays,
  required String Function(MarketPrice price) keyOf,
}) {
  final selected = <String, MarketPrice>{};
  for (final price in input) {
    if (price.isProspectOffer || !price.isProspectRegularBasis) continue;
    if (!price.price.isFinite || price.price <= 0) continue;
    if (!price.isUsable(
      now: now,
      openPricesMaxAgeDays: openPricesMaxAgeDays,
    )) {
      continue;
    }

    final key = keyOf(price);
    final previous = selected[key];
    if (previous == null ||
        compareMarketPriceEvidence(price, previous, now) < 0) {
      selected[key] = price;
    }
  }
  return selected;
}
