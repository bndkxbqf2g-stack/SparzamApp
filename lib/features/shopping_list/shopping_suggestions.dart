import '../../data/products.dart';
import '../../models/product.dart';
import '../../models/recent_purchase.dart';
import '../../models/offer.dart';
import '../../models/price_observation.dart';
import '../../models/market_price.dart';
import '../../models/receipt_price_stat.dart';
import '../offers/effective_price.dart';
import '../offers/offer_filter.dart';
import '../offers/prospect_price_statistics.dart';
import '../catalog/product_identity.dart';
import '../catalog/product_hierarchy.dart';
import 'receipt_product_price_match.dart';
import 'shopping_price_quotes.dart';
import '../../services/quantity_normalizer.dart';

class ShoppingSuggestionPrice {
  const ShoppingSuggestionPrice({
    required this.price,
    required this.storeName,
    required this.sourceLabel,
    this.validUntil,
    this.observedAt,
    this.isOffer = false,
    this.isHistorical = false,
  });

  final double price;
  final String storeName;
  final String sourceLabel;
  final DateTime? validUntil;
  final DateTime? observedAt;
  final bool isOffer;
  final bool isHistorical;

  String get displayLabel =>
      '$sourceLabel $storeName ${price.toStringAsFixed(2).replaceAll('.', ',')} €'
      '${validUntil == null ? '' : ' · bis ${_date(validUntil!)}'}'
      '${isHistorical && observedAt != null ? ' · Stand ${_date(observedAt!)}' : ''}';

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.'
      '${value.year}';
}

List<Product> buildSuggestions({
  required String query,
  required List<RecentPurchase> knownItems,
  required List<RecentPurchase> recentPurchases,
  required Map<String, String> preferredProductByGroup,
  List<Product> catalogProducts = products,
  Iterable<Offer> offers = const <Offer>[],
  Iterable<MarketPrice> marketPrices = const <MarketPrice>[],
  Iterable<ReceiptPriceStat> receiptPriceStats = const <ReceiptPriceStat>[],
  Map<String, ProspectPriceHistorySummary> prospectPriceHistory = const {},
  Iterable<String> enabledStores = const <String>[],
  DateTime? now,
}) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return const <Product>[];

  final queryIdentity = identifyProduct(query);
  final learnedMatches = knownItems
      .map((item) => item.toProduct())
      .where((product) => _matchesProductQuery(product, query, queryIdentity));
  final catalogMatches = catalogProducts.where(
    (product) => _matchesProductQuery(product, query, queryIdentity),
  );

  final seen = <String>{};
  final matches = <Product>[
    ...catalogMatches,
    ...learnedMatches,
  ].where((product) => seen.add(product.id)).toList();

  final suggestionPrices = <String, ShoppingSuggestionPrice?>{
    for (final product in matches)
      product.id: shoppingSuggestionPriceForProduct(
        product,
        offers: offers,
        marketPrices: marketPrices,
        receiptPriceStats: receiptPriceStats,
        prospectPriceHistory: prospectPriceHistory,
        enabledStores: enabledStores,
        now: now,
      ),
  };

  matches.sort((a, b) {
    final aPrice = suggestionPrices[a.id];
    final bPrice = suggestionPrices[b.id];
    if (aPrice != null || bPrice != null) {
      if (aPrice == null) return 1;
      if (bPrice == null) return -1;
      if (aPrice.isHistorical != bPrice.isHistorical) {
        return aPrice.isHistorical ? 1 : -1;
      }
      if (aPrice.isOffer != bPrice.isOffer) return aPrice.isOffer ? -1 : 1;
      // Offers/current observations still outrank historical values above.
      // Within the same evidence bucket, keep the cheapest comparable item
      // first so historical receipt medians remain useful for staple searches.
      final aComparable = _comparisonPrice(a, aPrice.price);
      final bComparable = _comparisonPrice(b, bPrice.price);
      if (aComparable != null && bComparable != null) {
        if (aComparable.dimension == bComparable.dimension) {
          final byUnitPrice = aComparable.price.compareTo(bComparable.price);
          if (byUnitPrice != 0) return byUnitPrice;
        }
      } else if (aComparable == null && bComparable != null) {
        // A package without a reliable quantity must not outrank a product
        // whose price can be compared on the same request. Keep that item
        // visible, but make the missing package basis explicit through its
        // unchanged unit label instead of pretending that its raw package
        // price is a unit price.
        return 1;
      } else if (aComparable != null && bComparable == null) {
        return -1;
      } else {
        // Both prices are package-only observations. A raw price is still a
        // useful deterministic fallback within that evidence bucket, while
        // the UI continues to show the original package labels.
        final byPackagePrice = aPrice.price.compareTo(bPrice.price);
        if (byPackagePrice != 0) return byPackagePrice;
      }
    }

    // A generic request should keep a generic catalog identity ahead of a
    // more specific sibling when both have no stronger evidence. For example,
    // "Kartoffeln 2,5 kg" must not default to frozen wedges merely because
    // both share the potato family and the sibling sorts first by name.
    final aIdentity = identifyProduct(a.name);
    final bIdentity = identifyProduct(b.name);
    if (queryIdentity.isGeneric &&
        aIdentity.familyKey == queryIdentity.familyKey &&
        bIdentity.familyKey == queryIdentity.familyKey) {
      final bySpecificity = _identitySpecificity(aIdentity)
          .compareTo(_identitySpecificity(bIdentity));
      if (bySpecificity != 0) return bySpecificity;
    }

    final aExact = _matchesExactSearchLabel(a, query);
    final bExact = _matchesExactSearchLabel(b, query);
    if (aExact != bExact) return aExact ? -1 : 1;

    final aLearned = knownItems.any((item) => item.id == a.id);
    final bLearned = knownItems.any((item) => item.id == b.id);
    if (aLearned != bLearned) return aLearned ? -1 : 1;

    final aPurchase = recentPurchases
        .where((item) => item.id == a.id)
        .firstOrNull;
    final bPurchase = recentPurchases
        .where((item) => item.id == b.id)
        .firstOrNull;
    if (aPurchase != null || bPurchase != null) {
      if (aPurchase == null) return 1;
      if (bPurchase == null) return -1;
      if (aPurchase.purchaseCount != bPurchase.purchaseCount) {
        return bPurchase.purchaseCount.compareTo(aPurchase.purchaseCount);
      }
    }

    final aPreferred = preferredProductByGroup[a.group] == a.id;
    final bPreferred = preferredProductByGroup[b.group] == b.id;
    if (aPreferred != bPreferred) return aPreferred ? -1 : 1;
    if (a.isFavorite != b.isFavorite) return a.isFavorite ? -1 : 1;
    final aTextMatch = _queryLabelScore(a, query);
    final bTextMatch = _queryLabelScore(b, query);
    if (aTextMatch != bTextMatch) {
      return bTextMatch.compareTo(aTextMatch);
    }
    return a.name.compareTo(b.name);
  });

  return matches;
}

/// Chooses the first currently evidenced suggestion for a query with real
/// alternatives. The list is already ranked by offer/current-price evidence,
/// so this helper exposes that decision without promoting a historical hint
/// into a silent product choice.
String? recommendedShoppingProductId({
  required Iterable<Product> suggestions,
  required ShoppingSuggestionPrice? Function(Product product) priceFor,
  required bool hasAlternatives,
}) {
  if (!hasAlternatives) return null;
  for (final product in suggestions) {
    final price = priceFor(product);
    if (price != null && !price.isHistorical) return product.id;
  }
  return null;
}

bool _matchesProductQuery(
  Product product,
  String query,
  ProductIdentity queryIdentity,
) {
  final normalized = query.trim().toLowerCase();
  final values = [product.name, product.group, ...product.aliases];
  final textMatch = values.any(
    (value) => queryIdentity.isKnown
        ? _containsSearchPhrase(value, query)
        : value.toLowerCase().contains(normalized),
  );
  if (!queryIdentity.isKnown) return textMatch;

  final identities = [
    product.name,
    ...product.aliases,
  ].map(identifyProduct).where((identity) => identity.isKnown).toList();
  if (identities.isNotEmpty) {
    final nameIdentity = identities.first;
    return compatibleProductIdentity(queryIdentity, nameIdentity) ||
        _openMilkChoice(queryIdentity, nameIdentity) ||
        identities
            .skip(1)
            .any(
              (candidate) =>
                  compatibleProductIdentity(queryIdentity, candidate),
            );
  }
  return textMatch;
}

int _identitySpecificity(ProductIdentity identity) => [
  identity.variant,
  identity.productType,
  identity.fatPercent,
  identity.color,
  identity.shape,
  identity.meatType,
].where((value) => value != null).length;

bool _matchesExactSearchLabel(Product product, String query) {
  final normalized = normalizeIdentityText(query);
  return normalizeIdentityText(product.name) == normalized ||
      product.aliases.any(
        (alias) => normalizeIdentityText(alias) == normalized,
      );
}

// A receipt-style label can contain a retailer prefix and several unrelated
// abbreviations. Prefer a candidate whose own name/alias still occurs in the
// label when identity matching intentionally keeps several family siblings.
// This is a ranking signal only; it never broadens compatibility or price
// identity.
int _queryLabelScore(Product product, String query) {
  final normalizedQuery = normalizeIdentityText(query);
  var score = 0;
  for (final label in [product.name, ...product.aliases]) {
    final normalizedLabel = normalizeIdentityText(label);
    if (normalizedLabel.isEmpty) continue;
    if (normalizedQuery == normalizedLabel) {
      score = score < 3 ? 3 : score;
    } else if (normalizedQuery.contains(normalizedLabel)) {
      score = score < 2 ? 2 : score;
    }
    for (final token in normalizedLabel.split(' ')) {
      if (token.length >= 4 && normalizedQuery.contains(token)) {
        score = score < 1 ? 1 : score;
      }
    }
  }
  return score;
}

// Search may offer ordinary milk choices for an unspecified H-milk receipt
// label. This only retrieves separate products; it never transfers their
// prices or confirms which variant the receipt contained.
bool _openMilkChoice(ProductIdentity query, ProductIdentity candidate) =>
    isOpenMilkChoice(query, candidate);

/// Returns the lowest usable exact price or comparable recent receipt median
/// for one product. This is search ranking evidence, not a price guarantee.
ShoppingSuggestionPrice? shoppingSuggestionPriceForProduct(
  Product product, {
  Iterable<Offer> offers = const <Offer>[],
  Iterable<MarketPrice> marketPrices = const <MarketPrice>[],
  Iterable<ReceiptPriceStat> receiptPriceStats = const <ReceiptPriceStat>[],
  Map<String, ProspectPriceHistorySummary> prospectPriceHistory = const {},
  Iterable<String> enabledStores = const <String>[],
  DateTime? now,
  int historyDays = 60,
}) {
  final current = now ?? DateTime.now();
  final enabled = enabledStores.toSet();
  final quotes = <ShoppingSuggestionPrice>[];

  for (final offer in offers) {
    if (offer.productId != product.id ||
        (enabled.isNotEmpty && !enabled.contains(offer.storeName)) ||
        !isOfferDateRangeActive(
          validFrom: offer.validFrom,
          validUntil: offer.validUntil,
          now: current,
        ) ||
        isSampleOffer(offer)) {
      continue;
    }
    final effective = effectivePrice(offer);
    quotes.add(
      ShoppingSuggestionPrice(
        price: effective.finalPrice,
        storeName: offer.storeName,
        sourceLabel: effective.cashback > 0 ? 'Angebot, effektiv' : 'Angebot',
        validUntil: offer.validUntil,
        isOffer: true,
      ),
    );
  }

  for (final price in marketPrices) {
    if (price.productId != product.id ||
        price.source == MarketPriceSource.openPrices ||
        (enabled.isNotEmpty && !enabled.contains(price.storeName)) ||
        !price.price.isFinite ||
        price.price <= 0 ||
        !price.isUsable(now: current, openPricesMaxAgeDays: historyDays)) {
      continue;
    }
    quotes.add(
      ShoppingSuggestionPrice(
        price: price.price,
        storeName: price.storeName,
        sourceLabel: price.source == MarketPriceSource.receipt
            ? 'Bonpreis'
            : 'Eigener Preis',
        observedAt: price.updatedAt,
      ),
    );
  }

  final cutoff = DateTime(
    current.year,
    current.month,
    current.day,
  ).subtract(Duration(days: historyDays));
  final existingReceiptStores = quotes
      .where((quote) => quote.sourceLabel == 'Bonpreis')
      .map((quote) => quote.storeName)
      .toSet();
  final matchingReceiptStats = product.id.startsWith('receipt_suggestion_')
      ? const <ReceiptPriceStat>[]
      : receiptStatsForProduct(product, receiptPriceStats);
  for (final stat in matchingReceiptStats) {
    if (!stat.comparable ||
        stat.latestAt.isBefore(cutoff) ||
        stat.latestAt.isAfter(current) ||
        (enabled.isNotEmpty && !enabled.contains(stat.storeName)) ||
        existingReceiptStores.contains(stat.storeName)) {
      continue;
    }
    quotes.add(
      ShoppingSuggestionPrice(
        price: stat.medianPrice,
        storeName: stat.storeName,
        sourceLabel: 'Bon-Median',
        observedAt: stat.latestAt,
        isHistorical: true,
      ),
    );
  }

  if (quotes.isEmpty) {
    final history = prospectPriceHistory[product.id];
    if (history == null) {
      return null;
    }
    final histories = history.allSummaries
        .where(
          (summary) => enabled.isEmpty || enabled.contains(summary.storeName),
        )
        .toList(growable: false);
    if (histories.isEmpty) return null;
    final selected = [...histories]..sort(_compareHistoricalHints);
    final bestHistory = selected.first;
    return ShoppingSuggestionPrice(
      price: bestHistory.medianPrice,
      storeName: bestHistory.storeName,
      sourceLabel: bestHistory.kind == PriceObservationKind.offer
          ? 'Früheres Angebot (Median)'
          : 'Prospekt-Normalpreis (historisch)',
      observedAt: bestHistory.latestValidUntil,
      isHistorical: true,
    );
  }
  quotes.sort((a, b) {
    if (a.isOffer != b.isOffer) return a.isOffer ? -1 : 1;
    final byPrice = a.price.compareTo(b.price);
    if (byPrice != 0) return byPrice;
    return a.storeName.compareTo(b.storeName);
  });
  return quotes.first;
}

int _compareHistoricalHints(
  ProspectPriceHistorySummary a,
  ProspectPriceHistorySummary b,
) {
  if (a.kind != b.kind) {
    return a.kind == PriceObservationKind.offer ? -1 : 1;
  }
  final byPrice = a.medianPrice.compareTo(b.medianPrice);
  if (byPrice != 0) return byPrice;
  final byDate = b.latestValidUntil.compareTo(a.latestValidUntil);
  if (byDate != 0) return byDate;
  return a.storeName.compareTo(b.storeName);
}

({double price, QuantityDimension dimension})? _comparisonPrice(
  Product product,
  double price,
) {
  var amount = product.packageAmount;
  var unit = product.packageUnit;
  if (amount == null || unit == null) {
    // A unit label such as "2 x 500 g" needs explicit multipack parsing;
    // treating only the last component as the whole package would mis-rank it.
    if (RegExp(r'\d\s*[x×]').hasMatch(product.unit.toLowerCase())) {
      return null;
    }
    final match = RegExp(
      r'(\d+(?:[,.]\d+)?)\s*(kg|g|ml|l|stk|st|stück|stueck)\b',
    ).firstMatch(product.unit.toLowerCase());
    if (match == null) return null;
    amount = double.tryParse(match.group(1)!.replaceAll(',', '.'));
    unit = match.group(2);
  }
  final quantity = normalizeQuantity(amount, unit);
  final unitPrice = normalizedUnitPrice(
    price: price,
    amount: amount,
    unit: unit,
  );
  if (quantity == null || unitPrice == null) return null;
  return (price: unitPrice, dimension: quantity.dimension);
}

/// Keeps the text fallback conservative once the query has a known product
/// identity. An unknown candidate is only safe when its complete label is the
/// query; otherwise a family term could match an ingredient in a different
/// product, such as "Milch" in "Milch-Schokoladen-Bonbons".
bool _containsSearchPhrase(String value, String query) {
  final normalizedValue = normalizeIdentityText(value);
  final normalizedQuery = normalizeIdentityText(query);
  if (normalizedValue.isEmpty || normalizedQuery.isEmpty) return false;
  return normalizedValue == normalizedQuery;
}

List<Product> buildRelatedProductInterpretations({
  required String query,
  required List<Product> primarySuggestions,
  List<Product> catalogProducts = products,
  ShoppingSuggestionPrice? Function(Product product)? priceFor,
}) {
  final request = identifyProduct(query);
  if (!request.isKnown) return const <Product>[];

  final primaryIds = primarySuggestions.map((product) => product.id).toSet();
  final seen = <String>{};
  final matches = <Product>[];

  for (final product in catalogProducts) {
    if (primaryIds.contains(product.id)) continue;
    final identities = [
      product.name,
      ...product.aliases,
    ].map(identifyProduct).where((identity) => identity.isKnown);

    final related = identities.any(
      (candidate) =>
          sharesProductHierarchy(request, candidate) &&
          !compatibleProductIdentity(request, candidate),
    );
    if (related && seen.add(product.id)) {
      matches.add(product);
    }
  }

  final prices = <String, ShoppingSuggestionPrice?>{
    for (final product in matches) product.id: priceFor?.call(product),
  };
  matches.sort((a, b) {
    final aPrice = prices[a.id];
    final bPrice = prices[b.id];
    if (aPrice != null || bPrice != null) {
      if (aPrice == null) return 1;
      if (bPrice == null) return -1;
      if (aPrice.isHistorical != bPrice.isHistorical) {
        return aPrice.isHistorical ? 1 : -1;
      }
      if (aPrice.isOffer != bPrice.isOffer) {
        return aPrice.isOffer ? -1 : 1;
      }
      final byPrice = aPrice.price.compareTo(bPrice.price);
      if (byPrice != 0) return byPrice;
      final byStore = aPrice.storeName.compareTo(bPrice.storeName);
      if (byStore != 0) return byStore;
    }
    return a.name.compareTo(b.name);
  });
  return matches;
}

List<Product> buildQuickProducts(
  Map<String, String> preferredProductByGroup, {
  List<Product> catalogProducts = products,
}) {
  final preferredIds = preferredProductByGroup.values.toSet();
  final seen = <String>{};
  return <Product>[
    ...catalogProducts.where((p) => preferredIds.contains(p.id)),
    ...catalogProducts.where((p) => p.isFavorite),
    ...catalogProducts.where((p) => p.isStaple),
  ].where((p) => seen.add(p.id)).take(12).toList();
}
