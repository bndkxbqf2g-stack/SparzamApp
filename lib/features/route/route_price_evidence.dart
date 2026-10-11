import '../../models/market_price.dart';
import '../../models/offer.dart';
import '../../models/route_plan.dart';
import 'market_price_quality.dart';
import 'route_price_resolver.dart';

/// A short, user-facing explanation of the evidence behind one route price.
///
/// The label deliberately keeps active offers, observed market prices and
/// prices without a stored source separate. It is display-only; it never
/// changes route eligibility or ranking.
String routePriceEvidenceLabel(RoutePriceQuote quote, {required DateTime now}) {
  if (quote.isEstimated) {
    return 'Schätzpreis · nicht für die Route verwendet';
  }

  final offer = quote.offer;
  if (offer != null) {
    final effective = offer.hasCoupon || offer.hasCashback
        ? 'Angebot, effektiv'
        : 'Angebot';
    final proof = offer.proofRef?.trim();
    final proofLabel = proof == null || proof.isEmpty
        ? 'Nachweis fehlt'
        : 'Nachweis vorhanden';
    return '$effective · ${_offerSourceLabel(offer.source)} · '
        '$proofLabel · ${_offerValidityLabel(offer)}';
  }

  final observation = quote.observation;
  if (observation == null) {
    return 'Hinterlegter Marktpreis · Quellenstand nicht dokumentiert';
  }

  final quality = marketPriceQuality(observation, now);
  final age = _dayDifference(now, observation.updatedAt);
  final ageLabel = age == 0
      ? 'heute'
      : age == 1
      ? 'vor 1 Tag'
      : 'vor $age Tagen';
  return '${observation.sourceLabel} · Stand ${_date(observation.updatedAt)} '
      '($ageLabel) · Preisqualität ${_qualityLabel(quality.confidence)}';
}

/// Counts the provenance classes used by the priced positions of a route.
/// Missing positions are intentionally not counted as estimates: they remain
/// visible through the route's data-gap card and must not look like evidence.
RoutePriceEvidenceSummary summarizeRoutePriceEvidence(
  RoutePlan plan,
  RoutePriceResolver prices,
) {
  var offers = 0;
  var receipts = 0;
  var ownPrices = 0;
  var openPrices = 0;
  var undocumented = 0;
  DateTime? oldestObservation;

  for (final entry in plan.assignments.entries) {
    for (final item in entry.value) {
      final quote = prices.quote(entry.key, item);
      if (quote == null || quote.isEstimated) continue;
      if (quote.usesOffer) {
        offers++;
        continue;
      }
      final observation = quote.observation;
      if (observation == null) {
        undocumented++;
        continue;
      }
      switch (observation.source) {
        case MarketPriceSource.receipt:
          receipts++;
        case MarketPriceSource.manual:
          ownPrices++;
        case MarketPriceSource.openPrices:
          openPrices++;
      }
      if (oldestObservation == null ||
          observation.updatedAt.isBefore(oldestObservation)) {
        oldestObservation = observation.updatedAt;
      }
    }
  }

  return RoutePriceEvidenceSummary(
    pricedPositions: offers + receipts + ownPrices + openPrices + undocumented,
    offers: offers,
    receipts: receipts,
    ownPrices: ownPrices,
    openPrices: openPrices,
    undocumented: undocumented,
    oldestObservation: oldestObservation,
  );
}

class RoutePriceEvidenceSummary {
  const RoutePriceEvidenceSummary({
    required this.pricedPositions,
    required this.offers,
    required this.receipts,
    required this.ownPrices,
    required this.openPrices,
    required this.undocumented,
    required this.oldestObservation,
  });

  final int pricedPositions;
  final int offers;
  final int receipts;
  final int ownPrices;
  final int openPrices;
  final int undocumented;
  final DateTime? oldestObservation;

  bool get hasEvidence => pricedPositions > 0;
}

String _offerSourceLabel(String source) =>
    switch (source.trim().toLowerCase()) {
      'leaflet' => 'Prospekt',
      'retailer' => 'Händler',
      'retailerwebsite' || 'retailer_website' => 'Händler-Website',
      'receipt' => 'Kassenbon',
      'manual' => 'manuell',
      'openprices' || 'open_prices' => 'Open Prices',
      _ => source.trim().isEmpty ? 'Quelle unbekannt' : source.trim(),
    };

String _offerValidityLabel(Offer offer) {
  final from = offer.validFrom;
  if (from == null) return 'gültig bis ${_date(offer.validUntil)}';
  return 'gültig ${_date(from)}–${_date(offer.validUntil)}';
}

String _qualityLabel(double confidence) {
  if (confidence >= 0.9) return 'hoch';
  if (confidence >= 0.75) return 'mittel';
  return 'vorsichtig';
}

int _dayDifference(DateTime now, DateTime observed) {
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(observed.year, observed.month, observed.day);
  return today.difference(date).inDays.clamp(0, 36500).toInt();
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
