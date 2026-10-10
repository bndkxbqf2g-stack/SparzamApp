import '../../data/offers.dart';
import '../../data/stores.dart';
import '../../models/list_item.dart';
import '../../models/market_price.dart';
import '../../models/offer.dart';
import '../../models/price_observation.dart';
import '../offers/effective_price.dart';
import '../offers/offer_filter.dart';
import '../offers/prospect_price_statistics.dart';
import '../route/market_price_quality.dart';

bool isSampleOffer(Offer offer) => sampleOffers.any(
  (sample) =>
      sample.id == offer.id &&
      sample.productId == offer.productId &&
      sample.storeName == offer.storeName &&
      sample.offerPrice == offer.offerPrice,
);

enum ShoppingQuoteKind { receipt, ownPrice, openPrices, offer, prospectHistory }

class ShoppingQuote {
  const ShoppingQuote({
    required this.storeName,
    required this.unitPrice,
    required this.kind,
    this.observedAt,
    this.offer,
    this.comparisonPrice,
    this.historical = false,
  });

  final String storeName;
  final double unitPrice;
  final ShoppingQuoteKind kind;
  final DateTime? observedAt;
  final Offer? offer;
  /// Quality-adjusted value used only to choose the visible quote in a market.
  /// The displayed amount remains the observed checkout or offer amount.
  final double? comparisonPrice;
  final bool historical;

  double get rankingPrice => comparisonPrice ?? unitPrice;

  String get sourceLabel => switch (kind) {
    ShoppingQuoteKind.receipt =>
      '${isHistorical ? 'Historischer ' : ''}Bonpreis vom ${_date(observedAt!)}',
    ShoppingQuoteKind.ownPrice => 'Eigener Preis vom ${_date(observedAt!)}',
    ShoppingQuoteKind.openPrices =>
      'Open-Prices-Preis vom ${_date(observedAt!)}',
    ShoppingQuoteKind.offer =>
      'Angebot${(offer!.hasCoupon || offer!.hasCashback) ? ', effektiv' : ''} '
          'bis ${_date(offer!.validUntil)}',
    ShoppingQuoteKind.prospectHistory =>
      'Prospekt-Median (historisch, bis ${_date(observedAt!)})',
  };

  /// Keeps the evidence class visible in the detail view without changing
  /// the ranking label or treating a missing proof reference as a valid one.
  String get evidenceLabel {
    if (kind != ShoppingQuoteKind.offer || offer == null) return sourceLabel;
    return '${offerEvidenceLabel(offer!)} · $sourceLabel';
  }

  String get displayPrefix => switch (kind) {
    ShoppingQuoteKind.receipt =>
      isHistorical ? 'Historischer Bonpreis' : 'Bonpreis',
    ShoppingQuoteKind.ownPrice => 'Eigener Preis',
    ShoppingQuoteKind.openPrices => 'Open Prices',
    ShoppingQuoteKind.offer =>
      'Angebot${(offer!.hasCoupon || offer!.hasCashback) ? ', effektiv' : ''}',
    ShoppingQuoteKind.prospectHistory => 'Prospekt-Median',
  };

  bool get isHistorical =>
      historical || kind == ShoppingQuoteKind.prospectHistory;

  String get amountLabel =>
      '${unitPrice.toStringAsFixed(2).replaceAll('.', ',')} €';

  /// The visible saving is only trustworthy when the imported or entered
  /// normal price was explicitly verified. Effective offer prices already
  /// include deterministic coupon and cashback adjustments.
  double? get savings {
    final sourceOffer = offer;
    if (kind != ShoppingQuoteKind.offer ||
        sourceOffer == null ||
        !sourceOffer.originalPriceVerified ||
        !sourceOffer.originalPrice.isFinite ||
        sourceOffer.originalPrice <= unitPrice) {
      return null;
    }
    final value = double.parse(
      (sourceOffer.originalPrice - unitPrice).toStringAsFixed(2),
    );
    return value > 0 ? value : null;
  }

  String? get savingsLabel {
    final value = savings;
    if (value == null) return null;
    return 'Ersparnis ${value.toStringAsFixed(2).replaceAll('.', ',')} €';
  }

  static String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}.${date.year}';
}

/// One row of the product × market view shown from the shopping list.
///
/// A missing quote is intentional information: the market is enabled (or is
/// one of the six configured markets), but no current, comparable evidence is
/// available for this exact product identity.
class ShoppingPriceMatrixEntry {
  const ShoppingPriceMatrixEntry({required this.storeName, this.quote});

  final String storeName;
  final ShoppingQuote? quote;

  bool get hasQuote => quote != null;

  bool get hasCurrentQuote => quote != null && !quote!.isHistorical;

  bool get hasHistoricalQuote => quote?.isHistorical == true;
}

/// Exact product identity only. Receipts are observations of a purchase,
/// never a guarantee that a shelf price still applies today.
List<ShoppingQuote> shoppingQuotes(
  ListItem item, {
  required List<MarketPrice> prices,
  required List<Offer> offers,
  Map<String, ProspectPriceHistorySummary> prospectPriceHistory = const {},
  List<String> enabledStores = const [],
  int openPricesMaxAgeDays = 60,
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final candidates = <ShoppingQuote>[];

  for (final price in prices) {
    if (price.productId != item.product.id ||
        _isFutureObservation(price.updatedAt, today) ||
        (price.source == MarketPriceSource.openPrices &&
            !price.isUsable(
              now: today,
              openPricesMaxAgeDays: openPricesMaxAgeDays,
            )) ||
        !price.price.isFinite ||
        price.price <= 0 ||
        (enabledStores.isNotEmpty &&
            !enabledStores.contains(price.storeName))) {
      continue;
    }
    candidates.add(
      ShoppingQuote(
        storeName: price.storeName,
        unitPrice: price.price,
        kind: price.source == MarketPriceSource.receipt
            ? ShoppingQuoteKind.receipt
            : price.source == MarketPriceSource.openPrices
            ? ShoppingQuoteKind.openPrices
            : ShoppingQuoteKind.ownPrice,
        observedAt: price.updatedAt,
        comparisonPrice: price.price *
            (1 + marketPriceQuality(price, today).uncertaintyRate),
        historical: price.source == MarketPriceSource.receipt &&
            !price.isUsable(now: today, openPricesMaxAgeDays: 36500),
      ),
    );
  }

  for (final offer in offers) {
    if (offer.productId != item.product.id ||
        (enabledStores.isNotEmpty &&
            !enabledStores.contains(offer.storeName)) ||
        !isOfferDateRangeActive(
          validFrom: offer.validFrom,
          validUntil: offer.validUntil,
          now: today,
        ) ||
        isSampleOffer(offer)) {
      continue;
    }
    // Coupon and cashback are deterministic price adjustments and therefore
    // belong in the visible saving price. Multi-buy remains quantity
    // dependent and is calculated by the route resolver.
    final effective = effectivePrice(offer);
    candidates.add(
      ShoppingQuote(
        storeName: offer.storeName,
        unitPrice: effective.finalPrice,
        kind: ShoppingQuoteKind.offer,
        offer: offer,
        comparisonPrice: effective.finalPrice,
      ),
    );
  }

  // Historical prospect medians provide context when a market has no current
  // quote. They remain explicitly historical and never become route prices.
  final storesWithCurrentQuote = candidates
      .where((quote) => !quote.isHistorical)
      .map((quote) => quote.storeName)
      .toSet();
  final historicalByStore = <String, ProspectPriceHistorySummary>{};
  for (final summary
      in prospectPriceHistory[item.product.id]?.allSummaries ??
          const <ProspectPriceHistorySummary>[]) {
    if (summary.storeName.trim().isEmpty ||
        storesWithCurrentQuote.contains(summary.storeName) ||
        (enabledStores.isNotEmpty &&
            !enabledStores.contains(summary.storeName)) ||
        !summary.medianPrice.isFinite ||
        summary.medianPrice <= 0 ||
        !summary.latestValidUntil.isBefore(today)) {
      continue;
    }
    final previous = historicalByStore[summary.storeName];
    if (previous == null ||
        _compareHistoricalSummaries(summary, previous) < 0) {
      historicalByStore[summary.storeName] = summary;
    }
  }
  for (final summary in historicalByStore.values) {
    candidates.add(
      ShoppingQuote(
        storeName: summary.storeName,
        unitPrice: summary.medianPrice,
        kind: ShoppingQuoteKind.prospectHistory,
        observedAt: summary.latestValidUntil,
      ),
    );
  }

  candidates.sort((a, b) {
    final sourceOrder = _quoteSourceOrder(a).compareTo(_quoteSourceOrder(b));
    if (sourceOrder != 0) return sourceOrder;
    final storeOrder = a.storeName.compareTo(b.storeName);
    if (storeOrder != 0) return storeOrder;
    return b.observedAt?.compareTo(a.observedAt ?? today) ?? 0;
  });
  return candidates;
}

bool _isFutureObservation(DateTime observedAt, DateTime now) {
  final observed = DateTime(
    observedAt.year,
    observedAt.month,
    observedAt.day,
  );
  final today = DateTime(now.year, now.month, now.day);
  return observed.isAfter(today);
}

/// Resolves one best visible quote per enabled market while retaining markets
/// without evidence. Offers are preferred over non-offer observations, and
/// the cheapest active offer wins within a market. For non-offer evidence the
/// newest observation wins; a lower price is only a deterministic tie-breaker.
List<ShoppingPriceMatrixEntry> shoppingPriceMatrix(
  ListItem item, {
  required List<MarketPrice> prices,
  required List<Offer> offers,
  Map<String, ProspectPriceHistorySummary> prospectPriceHistory = const {},
  List<String> enabledStores = const [],
  int openPricesMaxAgeDays = 60,
  DateTime? now,
}) {
  final quotes = shoppingQuotes(
    item,
    prices: prices,
    offers: offers,
    prospectPriceHistory: prospectPriceHistory,
    enabledStores: enabledStores,
    openPricesMaxAgeDays: openPricesMaxAgeDays,
    now: now,
  );
  final configuredNames = enabledStores.isEmpty
      ? stores.map((store) => store.name).toList(growable: false)
      : enabledStores;
  final names = <String>{
    ...configuredNames,
    ...quotes.map((quote) => quote.storeName),
  };
  final configuredOrder = <String, int>{
    for (var index = 0; index < configuredNames.length; index++)
      configuredNames[index]: index,
  };

  final result = names.map((storeName) {
    final storeQuotes = quotes
        .where((quote) => quote.storeName == storeName)
        .toList(growable: false);
    if (storeQuotes.isEmpty) {
      return ShoppingPriceMatrixEntry(storeName: storeName);
    }
    final sorted = [...storeQuotes]..sort(_compareMatrixQuotes);
    return ShoppingPriceMatrixEntry(storeName: storeName, quote: sorted.first);
  }).toList();

  result.sort((a, b) {
    final aOrder = configuredOrder[a.storeName];
    final bOrder = configuredOrder[b.storeName];
    if (aOrder != null || bOrder != null) {
      if (aOrder == null) return 1;
      if (bOrder == null) return -1;
      if (aOrder != bOrder) return aOrder.compareTo(bOrder);
    }
    return a.storeName.compareTo(b.storeName);
  });
  return result;
}

int _compareMatrixQuotes(ShoppingQuote a, ShoppingQuote b) {
  final sourceOrder = _quoteSourceOrder(a).compareTo(_quoteSourceOrder(b));
  if (sourceOrder != 0) return sourceOrder;
  if (a.isHistorical != b.isHistorical) {
    return a.isHistorical ? 1 : -1;
  }
  if (a.kind == ShoppingQuoteKind.offer || !a.isHistorical) {
    final byQualityAdjustedPrice = a.rankingPrice.compareTo(b.rankingPrice);
    if (byQualityAdjustedPrice != 0) return byQualityAdjustedPrice;
  }
  final aDate = a.observedAt;
  final bDate = b.observedAt;
  if (aDate != null || bDate != null) {
    if (aDate == null) return 1;
    if (bDate == null) return -1;
    final byDate = bDate.compareTo(aDate);
    if (byDate != 0) return byDate;
  }
  final byPrice = a.unitPrice.compareTo(b.unitPrice);
  if (byPrice != 0) return byPrice;
  return a.sourceLabel.compareTo(b.sourceLabel);
}

/// Orders visible quotes with the same evidence and quality rules used by the
/// product × market matrix. Callers can use this for a single highlighted
/// quote without falling back to a source-specific shortcut.
int compareShoppingQuotes(ShoppingQuote a, ShoppingQuote b) =>
    _compareMatrixQuotes(a, b);

int _quoteSourceOrder(ShoppingQuote quote) => switch (quote.kind) {
  ShoppingQuoteKind.offer => 0,
  ShoppingQuoteKind.receipt ||
  ShoppingQuoteKind.ownPrice ||
  ShoppingQuoteKind.openPrices => 1,
  ShoppingQuoteKind.prospectHistory => 2,
};

String offerEvidenceLabel(Offer offer) {
  final proof = offer.proofRef?.trim();
  return '${_offerSourceLabel(offer.source)} · '
      '${proof == null || proof.isEmpty ? 'Nachweis fehlt' : 'Nachweis vorhanden'}';
}

String _offerSourceLabel(String source) =>
    switch (source.trim().toLowerCase()) {
      'leaflet' => 'Prospekt',
      'retailer' => 'Händler',
      'retailerwebsite' || 'retailer_website' => 'Händler-Website',
      'receipt' => 'Kassenbon',
      'manual' => 'Manuell',
      'openprices' || 'open_prices' => 'Open Prices',
      _ => source.trim().isEmpty ? 'Quelle unbekannt' : source.trim(),
    };

int _compareHistoricalSummaries(
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
  return previous.observationCount.compareTo(candidate.observationCount);
}
