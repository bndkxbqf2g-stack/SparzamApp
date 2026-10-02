import '../../models/price_observation.dart';
import '../../models/product.dart';

/// A compact, UI-ready view of the exact price evidence for one list item.
///
/// The list is deliberately derived from confirmed product observations only.
/// Family-only or provisional observations remain available to the existing
/// history hints, but must not look like an exact product price timeline.
class ShoppingPriceHistoryEntry {
  const ShoppingPriceHistoryEntry({
    required this.storeName,
    required this.price,
    required this.observedAt,
    required this.sourceLabel,
    required this.kindLabel,
    this.quantity,
    this.unit,
    this.unitPrice,
    required this.hasProof,
    this.validUntil,
  });

  final String storeName;
  final double price;
  final DateTime observedAt;
  final String sourceLabel;
  final String kindLabel;
  final double? quantity;
  final String? unit;
  final double? unitPrice;
  final bool hasProof;
  final DateTime? validUntil;
}

List<ShoppingPriceHistoryEntry> shoppingPriceHistory({
  required Product product,
  required Iterable<PriceObservation> observations,
  DateTime? now,
  int maxEntries = 24,
}) {
  if (maxEntries <= 0) return const <ShoppingPriceHistoryEntry>[];
  final current = now ?? DateTime.now();
  final seen = <String>{};
  final entries =
      observations
          .where(
            (observation) =>
                _isEligible(observation, product: product, current: current),
          )
          .where((observation) => seen.add(observation.id))
          .map(
            (observation) => ShoppingPriceHistoryEntry(
              storeName: observation.storeName,
              price: observation.price,
              observedAt: observation.observedAt,
              sourceLabel: _sourceLabel(observation.source),
              kindLabel: _kindLabel(observation.kind),
              quantity: observation.quantity,
              unit: observation.unit,
              unitPrice: observation.unitPrice,
              hasProof: observation.proofRef?.trim().isNotEmpty == true,
              validUntil: observation.validUntil,
            ),
          )
          .toList()
        ..sort((a, b) {
          final byDate = b.observedAt.compareTo(a.observedAt);
          if (byDate != 0) return byDate;
          final byStore = a.storeName.compareTo(b.storeName);
          if (byStore != 0) return byStore;
          return a.price.compareTo(b.price);
        });
  return entries.take(maxEntries).toList(growable: false);
}

bool _isEligible(
  PriceObservation observation, {
  required Product product,
  required DateTime current,
}) =>
    observation.isValid &&
    observation.productId == product.id &&
    observation.identityConfidence >= 1 &&
    observation.storeName.trim().isNotEmpty &&
    !observation.observedAt.isAfter(current);

String _sourceLabel(PriceObservationSource source) => switch (source) {
  PriceObservationSource.receipt => 'Kassenbon',
  PriceObservationSource.manual => 'Eigener Preis',
  PriceObservationSource.openPrices => 'Open Prices',
  PriceObservationSource.retailer => 'Händler',
  PriceObservationSource.retailerWebsite => 'Händler-Website',
  PriceObservationSource.leaflet => 'Prospekt',
  PriceObservationSource.shelfImage => 'Regalfoto',
  PriceObservationSource.shelfVideo => 'Regalvideo',
  PriceObservationSource.community => 'Community',
  PriceObservationSource.estimate => 'Schätzung',
};

String _kindLabel(PriceObservationKind kind) => switch (kind) {
  PriceObservationKind.offer => 'Angebot',
  PriceObservationKind.regular => 'Normalpreis',
  PriceObservationKind.unknown => 'Preisbeobachtung',
};
