import '../../data/stores.dart';
import '../../models/list_item.dart';
import '../../models/market_price.dart';
import '../../models/offer.dart';
import '../../models/price_observation.dart';
import '../../models/product.dart';
import '../offers/effective_price.dart';
import '../offers/offer_import.dart';
import '../offers/offer_filter.dart';
import '../offers/prospect_price_statistics.dart';
import '../catalog/product_family.dart';
import '../receipt/receipt_observation_builder.dart';
import '../route/market_price_quality.dart';
import '../../services/branch_identity.dart';
import '../../services/market_price_comparability.dart';
import '../../services/quantity_normalizer.dart';

enum ShoppingQuoteKind {
  receipt,
  ownPrice,
  prospect,
  openPrices,
  offer,
  prospectHistory,
}

class ShoppingQuote {
  const ShoppingQuote({
    required this.storeName,
    required this.unitPrice,
    required this.kind,
    this.observedAt,
    this.offer,
    this.comparisonPrice,
    this.quantity,
    this.unit,
    this.baseUnitPrice,
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
  /// Package basis retained for the price matrix and its detail view.
  final double? quantity;
  final String? unit;
  /// Normalized price for [unit], for example €/kg or €/l.
  final double? baseUnitPrice;
  final bool historical;

  double get rankingPrice => comparisonPrice ?? unitPrice;

  String? get packageLabel {
    final amount = quantity;
    final packageUnit = unit?.trim();
    if (amount == null ||
        !amount.isFinite ||
        amount <= 0 ||
        packageUnit == null ||
        packageUnit.isEmpty) {
      return null;
    }
    return '${_number(amount)} $packageUnit';
  }

  String? get baseUnitPriceLabel {
    final price = baseUnitPrice;
    final normalized = normalizeQuantity(quantity, unit);
    if (price == null ||
        !price.isFinite ||
        price <= 0 ||
        normalized == null) {
      return null;
    }
    return 'Grundpreis ${_money(price)} €/${normalized.baseUnit}';
  }

  /// Describes whether the visible price has an explicit package basis.
  /// Legacy observations may still be usable for the exact product identity,
  /// but they must not look fully unit-comparable when that basis is absent.
  String get comparabilityLabel {
    if (isHistorical) return 'Vergleichbarkeit: historische Orientierung';
    if (packageLabel != null) return 'Vergleichbarkeit: Packungsbasis belegt';
    return 'Vergleichbarkeit: Mengenbasis nicht dokumentiert';
  }

  /// Gives the visible quote an explicit observation age without implying
  /// that a historical value is still a valid route price.
  String freshnessLabel({DateTime? now}) {
    if (isHistorical) return 'Preisalter: historisch';
    final observed = observedAt?.toLocal();
    if (observed == null) return 'Preisalter: unbekannt';
    final reference = now ?? DateTime.now();
    final observedDay = DateTime(observed.year, observed.month, observed.day);
    final referenceDay = DateTime(
      reference.year,
      reference.month,
      reference.day,
    );
    if (observedDay.isAfter(referenceDay)) {
      return 'Preisalter: Zeitpunkt in Zukunft';
    }
    final ageDays = referenceDay.difference(observedDay).inDays;
    if (ageDays == 0) return 'Preisalter: heute';
    if (ageDays == 1) return 'Preisalter: vor 1 Tag';
    return 'Preisalter: vor $ageDays Tagen';
  }

  String get sourceLabel => switch (kind) {
    ShoppingQuoteKind.receipt =>
      '${isHistorical ? 'Historischer ' : ''}Bonpreis vom ${_date(observedAt!)}',
    ShoppingQuoteKind.ownPrice => 'Eigener Preis vom ${_date(observedAt!)}',
    ShoppingQuoteKind.prospect => 'Prospektpreis vom ${_date(observedAt!)}',
    ShoppingQuoteKind.openPrices =>
      'Open-Prices-Preis vom ${_date(observedAt!)}',
    ShoppingQuoteKind.offer =>
      'Angebot${(offer!.hasCoupon || offer!.hasCashback) ? ', effektiv' : ''} '
          'bis ${_date(offer!.validUntil)}${_capturedSuffix(offer!.capturedAt)}',
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
    ShoppingQuoteKind.prospect => 'Prospektpreis',
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

  static String _capturedSuffix(DateTime? value) {
    if (value == null) return '';
    final local = value.toLocal();
    return ' · erfasst ${_date(local)} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')} Uhr';
  }
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

/// Reuses one resolved quote/matrix snapshot for all widgets that render the
/// same shopping-list products during a build.
///
/// The snapshot is deliberately keyed by product identity. Quantity changes
/// affect the route total, but not the market evidence shown for one product.
class ShoppingPriceQuoteSnapshot {
  const ShoppingPriceQuoteSnapshot._({
    required this._quotesByProductId,
    required this._matrixByProductId,
  });

  final Map<String, List<ShoppingQuote>> _quotesByProductId;
  final Map<String, List<ShoppingPriceMatrixEntry>> _matrixByProductId;

  List<ShoppingQuote> quotesFor(ListItem item) =>
      _quotesByProductId[item.product.id] ?? const <ShoppingQuote>[];

  List<ShoppingPriceMatrixEntry> matrixFor(ListItem item) =>
      _matrixByProductId[item.product.id] ??
      const <ShoppingPriceMatrixEntry>[];
}

/// Resolves each distinct product at most once for a shopping-list render.
///
/// This keeps the existing [shoppingQuotes] and matrix rules as the single
/// source of truth while avoiding duplicate scans from the summary card and
/// each product row.
ShoppingPriceQuoteSnapshot shoppingPriceQuoteSnapshot(
  Iterable<ListItem> items, {
  required List<MarketPrice> prices,
  required List<Offer> offers,
  List<Product> catalogProducts = const <Product>[],
  Map<String, ProspectPriceHistorySummary> prospectPriceHistory = const {},
  List<String> enabledStores = const [],
  int openPricesMaxAgeDays = 60,
  DateTime? now,
}) {
  final uniqueItems = <String, ListItem>{};
  for (final item in items) {
    uniqueItems.putIfAbsent(item.product.id, () => item);
  }

  final quotesByProductId = <String, List<ShoppingQuote>>{};
  final matrixByProductId = <String, List<ShoppingPriceMatrixEntry>>{};
  for (final entry in uniqueItems.entries) {
    final quotes = shoppingQuotes(
      entry.value,
      prices: prices,
      offers: offers,
      catalogProducts: catalogProducts,
      prospectPriceHistory: prospectPriceHistory,
      enabledStores: enabledStores,
      openPricesMaxAgeDays: openPricesMaxAgeDays,
      now: now,
    );
    quotesByProductId[entry.key] = List<ShoppingQuote>.unmodifiable(quotes);
    matrixByProductId[entry.key] =
        List<ShoppingPriceMatrixEntry>.unmodifiable(
          shoppingPriceMatrixFromQuotes(
            quotes,
            enabledStores: enabledStores,
          ),
        );
  }

  return ShoppingPriceQuoteSnapshot._(
    quotesByProductId: Map<String, List<ShoppingQuote>>.unmodifiable(
      quotesByProductId,
    ),
    matrixByProductId:
        Map<String, List<ShoppingPriceMatrixEntry>>.unmodifiable(
          matrixByProductId,
        ),
  );
}

/// Exact product identity only. Receipts are observations of a purchase,
/// never a guarantee that a shelf price still applies today.
List<ShoppingQuote> shoppingQuotes(
  ListItem item, {
  required List<MarketPrice> prices,
  required List<Offer> offers,
  List<Product> catalogProducts = const <Product>[],
  Map<String, ProspectPriceHistorySummary> prospectPriceHistory = const {},
  List<String> enabledStores = const [],
  int openPricesMaxAgeDays = 60,
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final candidates = <ShoppingQuote>[];

  for (final price in prices) {
    final usable = price.isUsable(
      now: today,
      openPricesMaxAgeDays: openPricesMaxAgeDays,
    );
    if (price.productId != item.product.id ||
        !marketPriceMatchesProduct(price, item.product) ||
        !matchesConfiguredBranch(price.storeName, price.sourceLocationId) ||
        _isFutureObservation(price.updatedAt, today) ||
        price.identityConfidence < 1 ||
        !price.hasComparableBasis ||
        (!usable && price.source != MarketPriceSource.receipt) ||
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
            : price.source == MarketPriceSource.prospect
            ? ShoppingQuoteKind.prospect
            : price.source == MarketPriceSource.openPrices
            ? ShoppingQuoteKind.openPrices
            : ShoppingQuoteKind.ownPrice,
        observedAt: price.updatedAt,
        quantity: price.quantity,
        unit: price.unit,
        baseUnitPrice: price.unitPrice,
        comparisonPrice: price.price *
            (1 + marketPriceQuality(price, today).uncertaintyRate),
        historical: price.source == MarketPriceSource.receipt && !usable,
      ),
    );
  }

  for (final offer in offers) {
    if (!_offerMatchesShoppingItem(
          offer,
          item.product,
          catalogProducts,
        ) ||
        !matchesConfiguredBranch(offer.storeName, offer.locationId) ||
        !hasExactOfferBranch(offer) ||
        (enabledStores.isNotEmpty &&
            !enabledStores.contains(offer.storeName)) ||
        !isOfferDateRangeActive(
          validFrom: offer.validFrom,
          validUntil: offer.validUntil,
          now: today,
        ) ||
        !hasTrustedOfferEvidence(offer) ||
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
        observedAt: offer.capturedAt,
        offer: offer,
        quantity: offer.packageAmount,
        unit: offer.packageUnit,
        baseUnitPrice: normalizedUnitPrice(
              price: effective.finalPrice,
              amount: offer.packageAmount,
              unit: offer.packageUnit,
            ) ??
            offer.unitPrice,
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
    if (a.isHistorical != b.isHistorical) {
      return a.isHistorical ? 1 : -1;
    }
    // Compare the actual quality-adjusted amount before source kind. A
    // prospect offer wins for a market only when it is cheaper; the source
    // label remains the tie-breaker and stays visible in the UI.
    final byPrice = a.rankingPrice.compareTo(b.rankingPrice);
    if (byPrice != 0) return byPrice;
    final sourceOrder = _quoteSourceOrder(a).compareTo(_quoteSourceOrder(b));
    if (sourceOrder != 0) return sourceOrder;
    final storeOrder = a.storeName.compareTo(b.storeName);
    if (storeOrder != 0) return storeOrder;
    return b.observedAt?.compareTo(a.observedAt ?? today) ?? 0;
  });
  return candidates;
}

bool _offerMatchesShoppingItem(
  Offer offer,
  Product item,
  List<Product> catalogProducts,
) {
  if (offer.productId == item.id) {
    return offerMatchesProduct(offer, item);
  }

  // Generic requests such as "Milch" may show a current, exact-package
  // prospect offer for a known family member. This is display evidence only;
  // route resolution keeps its exact product-ID rule.
  if (!isGenericFamilyRequest(item.name)) return false;
  final candidate = catalogProducts
      .where((product) => product.id == offer.productId)
      .firstOrNull;
  if (candidate == null) return false;
  if (inferReceiptFamily(candidate.name) != inferReceiptFamily(item.name)) {
    return false;
  }
  return offerMatchesProduct(offer, candidate);
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
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
  List<Product> catalogProducts = const <Product>[],
  Map<String, ProspectPriceHistorySummary> prospectPriceHistory = const {},
  List<String> enabledStores = const [],
  int openPricesMaxAgeDays = 60,
  DateTime? now,
}) {
  final quotes = shoppingQuotes(
    item,
    prices: prices,
    offers: offers,
    catalogProducts: catalogProducts,
    prospectPriceHistory: prospectPriceHistory,
    enabledStores: enabledStores,
    openPricesMaxAgeDays: openPricesMaxAgeDays,
    now: now,
  );
  return shoppingPriceMatrixFromQuotes(
    quotes,
    enabledStores: enabledStores,
  );
}

/// Builds the product × market matrix from an already resolved quote list.
///
/// Shopping list rows often need both a highlighted quote and the complete
/// market matrix. Keeping this second step separate prevents resolving the
/// same prices and offers twice during one widget build.
List<ShoppingPriceMatrixEntry> shoppingPriceMatrixFromQuotes(
  Iterable<ShoppingQuote> inputQuotes, {
  List<String> enabledStores = const [],
}) {
  final quotes = inputQuotes.toList(growable: false);
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
  if (a.isHistorical != b.isHistorical) {
    return a.isHistorical ? 1 : -1;
  }
  if (!a.isHistorical && !b.isHistorical) {
    final byQualityAdjustedPrice = a.rankingPrice.compareTo(b.rankingPrice);
    if (byQualityAdjustedPrice != 0) return byQualityAdjustedPrice;
  }
  final sourceOrder = _quoteSourceOrder(a).compareTo(_quoteSourceOrder(b));
  if (sourceOrder != 0) return sourceOrder;
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
  ShoppingQuoteKind.prospect ||
  ShoppingQuoteKind.openPrices => 1,
  ShoppingQuoteKind.prospectHistory => 2,
};

String _money(double value) => value.toStringAsFixed(2).replaceAll('.', ',');

String _number(double value) {
  final text = value.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '');
  return text.replaceFirst(RegExp(r'\.$'), '').replaceAll('.', ',');
}
String offerEvidenceLabel(Offer offer) {
  final proof = offer.proofRef?.trim();
  return '${_offerSourceLabel(offer.sourceAdapter ?? offer.source)} · '
      '${proof == null || proof.isEmpty ? 'Nachweis fehlt' : 'Nachweis vorhanden'}';
}

String _offerSourceLabel(String source) =>
    switch (source.trim().toLowerCase()) {
      'leaflet' => 'Prospekt',
      'kaufda' => 'KaufDA',
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
