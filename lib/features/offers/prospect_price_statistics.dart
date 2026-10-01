import '../../models/price_observation.dart';
import '../../services/quantity_normalizer.dart';

class ProspectPriceHistorySummary {
  const ProspectPriceHistorySummary({
    required this.productId,
    required this.storeName,
    required this.medianPrice,
    required this.latestValidUntil,
    required this.kind,
    required this.observationCount,
    this.alternatives = const <ProspectPriceHistorySummary>[],
  });

  final String productId;
  final String storeName;
  final double medianPrice;
  final DateTime latestValidUntil;
  final PriceObservationKind kind;
  final int observationCount;

  /// Other store/kind summaries for the same product. They remain historical
  /// hints and are never promoted to current route prices.
  final List<ProspectPriceHistorySummary> alternatives;

  List<ProspectPriceHistorySummary> get allSummaries => [this, ...alternatives];
}

/// Historical context for search only. These amounts are never promoted to
/// route prices or presented as currently available offers.
Map<String, ProspectPriceHistorySummary> prospectPriceHistorySummaries(
  Iterable<PriceObservation> observations, {
  DateTime? now,
  int maxAgeDays = 90,
  Iterable<String> enabledStores = const <String>[],
}) {
  final today = _day(now ?? DateTime.now());
  final cutoff = today.subtract(Duration(days: maxAgeDays));
  final enabled = enabledStores.toSet();
  final groups =
      <(String, String, PriceObservationKind), List<PriceObservation>>{};
  for (final entry in observations) {
    final end = entry.validUntil;
    if (!entry.isValid ||
        entry.productId?.isNotEmpty != true ||
        entry.quantity == null ||
        entry.unit == null ||
        normalizeQuantity(entry.quantity!, entry.unit!) == null ||
        entry.proofRef?.trim().isNotEmpty != true ||
        (enabled.isNotEmpty && !enabled.contains(entry.storeName)) ||
        !_isProspectSource(entry.source) ||
        (entry.kind != PriceObservationKind.offer &&
            entry.kind != PriceObservationKind.regular) ||
        end == null ||
        !_day(end).isBefore(today) ||
        _day(end).isBefore(cutoff)) {
      continue;
    }
    groups
        .putIfAbsent((entry.productId!, entry.storeName, entry.kind), () => [])
        .add(entry);
  }

  final summariesByProduct = <String, List<ProspectPriceHistorySummary>>{};
  for (final group in groups.entries) {
    final entries = group.value;
    final sortedPrices = entries.map((entry) => entry.price).toList()..sort();
    final middle = sortedPrices.length ~/ 2;
    final median = sortedPrices.length.isOdd
        ? sortedPrices[middle]
        : (sortedPrices[middle - 1] + sortedPrices[middle]) / 2;
    final latest = entries
        .map((entry) => entry.validUntil!)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final summary = ProspectPriceHistorySummary(
      productId: group.key.$1,
      storeName: group.key.$2,
      medianPrice: median,
      latestValidUntil: latest,
      kind: group.key.$3,
      observationCount: entries.length,
    );
    summariesByProduct
        .putIfAbsent(summary.productId, () => <ProspectPriceHistorySummary>[])
        .add(summary);
  }

  final byProduct = <String, ProspectPriceHistorySummary>{};
  for (final entry in summariesByProduct.entries) {
    final sorted = [...entry.value]..sort(_compareSummaries);
    final primary = sorted.first;
    byProduct[entry.key] = ProspectPriceHistorySummary(
      productId: primary.productId,
      storeName: primary.storeName,
      medianPrice: primary.medianPrice,
      latestValidUntil: primary.latestValidUntil,
      kind: primary.kind,
      observationCount: primary.observationCount,
      alternatives: sorted.skip(1).toList(growable: false),
    );
  }
  return byProduct;
}

int _compareSummaries(
  ProspectPriceHistorySummary candidate,
  ProspectPriceHistorySummary previous,
) {
  if (candidate.kind != previous.kind) {
    return candidate.kind == PriceObservationKind.offer ? -1 : 1;
  }
  final byPrice = candidate.medianPrice.compareTo(previous.medianPrice);
  if (byPrice != 0) return byPrice;
  final byDate = previous.latestValidUntil.compareTo(
    candidate.latestValidUntil,
  );
  if (byDate != 0) return byDate;
  final byCount = previous.observationCount.compareTo(
    candidate.observationCount,
  );
  if (byCount != 0) return byCount;
  return candidate.storeName.compareTo(previous.storeName);
}

bool _isProspectSource(PriceObservationSource source) =>
    source == PriceObservationSource.leaflet ||
    source == PriceObservationSource.retailer ||
    source == PriceObservationSource.retailerWebsite;

DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);
