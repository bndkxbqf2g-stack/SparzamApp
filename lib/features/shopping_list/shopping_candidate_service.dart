import '../../models/market_price.dart';
import '../../models/offer.dart';
import '../../models/price_observation.dart';
import '../../models/product.dart';
import '../../models/receipt_price_stat.dart';
import '../../services/safe_external_url.dart';
import '../../services/market_price_comparability.dart';
import '../../services/branch_identity.dart';
import '../route/market_price_quality.dart';
import '../../services/market_price_source_priority.dart';
import '../catalog/product_identity.dart';
import '../offers/effective_price.dart';
import '../offers/offer_import.dart';
import '../offers/offer_filter.dart';
import '../offers/prospect_price_statistics.dart';
import 'receipt_product_price_match.dart';
import 'shopping_price_quotes.dart';

class ShoppingCandidateQuote {
  const ShoppingCandidateQuote({
    required this.storeName,
    required this.price,
    required this.label,
    this.observedAt,
    this.validUntil,
    this.imageUrl,
    this.isOffer = false,
    this.isHistorical = false,
    this.evidenceLabel,
    this.savings,
    this.rankingPrice,
    this.sourcePriority = 99,
  });

  final String storeName;
  final double price;
  final String label;
  final DateTime? observedAt;
  final DateTime? validUntil;
  final String? imageUrl;
  final bool isOffer;
  final bool isHistorical;
  final String? evidenceLabel;
  final double? savings;
  /// Quality-adjusted value used only to rank evidence. The displayed [price]
  /// remains the observed checkout amount.
  final double? rankingPrice;
  /// Stable source precedence used after quality and amount ties.
  final int sourcePriority;

  double get comparisonPrice => rankingPrice ?? price;
}

class ShoppingCandidate {
  const ShoppingCandidate({required this.product, required this.quotes});

  final Product product;
  final List<ShoppingCandidateQuote> quotes;

  double? get bestPrice {
    final currentQuotes = quotes.where((quote) => !quote.isHistorical);
    // Offers and observed market prices share one current evidence bucket.
    // The offer is selected only when its effective price is actually lower;
    // a higher offer must not hide a cheaper receipt price.
    final rankedQuotes = currentQuotes.isNotEmpty ? currentQuotes : quotes;
    if (rankedQuotes.isEmpty) return null;
    return rankedQuotes.map((quote) => quote.price).reduce(
          (a, b) => a < b ? a : b,
        );
  }

  bool get hasOffer => quotes.any((quote) => quote.isOffer);

  /// Lowest quality-adjusted value among current quotes. Historical hints are
  /// used only when no current evidence exists.
  double? get bestComparisonPrice {
    final currentQuotes = quotes.where((quote) => !quote.isHistorical);
    final rankedQuotes = currentQuotes.isNotEmpty ? currentQuotes : quotes;
    if (rankedQuotes.isEmpty) return null;
    return rankedQuotes
        .map((quote) => quote.comparisonPrice)
        .reduce((a, b) => a < b ? a : b);
  }

  String? get imageUrl {
    for (final quote in quotes) {
      final url = safeExternalHttpUrl(quote.imageUrl);
      if (url != null) return url;
    }
    return null;
  }
}

List<ShoppingCandidate> buildShoppingCandidates({
  required String request,
  required Iterable<Product> catalogProducts,
  required Iterable<Offer> offers,
  required Iterable<MarketPrice> marketPrices,
  required Iterable<ReceiptPriceStat> receiptPriceStats,
  Map<String, ProspectPriceHistorySummary> prospectPriceHistory = const {},
  Iterable<String> enabledStores = const <String>[],
  DateTime? now,
  int historyDays = 60,
  int openPricesMaxAgeDays = 60,
}) {
  final identity = identifyProduct(request);
  if (!identity.isKnown) return const <ShoppingCandidate>[];
  final current = now ?? DateTime.now();
  final cutoff = DateTime(current.year, current.month, current.day)
      .subtract(Duration(days: historyDays));
  final products = catalogProducts.where((product) {
    final identities = [product.name, ...product.aliases]
        .map(identifyProduct)
        .where((candidate) => candidate.isKnown);
    if (identities.isEmpty) return false;
    final nameIdentity = identities.first;
    return compatibleProductIdentity(identity, nameIdentity) ||
        _openMilkChoice(identity, nameIdentity) ||
        identities
            .skip(1)
            .any((candidate) => compatibleProductIdentity(identity, candidate));
  });

  final result = <ShoppingCandidate>[];
  for (final product in products) {
    final quotes = <ShoppingCandidateQuote>[];
    for (final offer in offers) {
      if (offer.productId != product.id ||
          !offerMatchesProduct(offer, product) ||
          !_storeEnabled(offer.storeName, enabledStores) ||
          !matchesConfiguredBranch(offer.storeName, offer.locationId) ||
          !hasExactOfferBranch(offer) ||
          isSampleOffer(offer) ||
          !hasTrustedOfferEvidence(offer) ||
          !isOfferDateRangeActive(
            validFrom: offer.validFrom,
            validUntil: offer.validUntil,
            now: current,
          )) {
        continue;
      }
      final effective = effectivePrice(offer);
      quotes.add(ShoppingCandidateQuote(
          storeName: offer.storeName,
          price: effective.finalPrice,
          label: effective.cashback > 0 ? 'Angebot, effektiv' : 'Angebot',
          validUntil: offer.validUntil,
          imageUrl: offer.imageUrl,
          isOffer: true,
          evidenceLabel: offerEvidenceLabel(offer),
          savings: _verifiedOfferSavings(offer, effective.finalPrice),
          rankingPrice: effective.finalPrice,
          sourcePriority: 0,
        ));
    }
    for (final price in marketPrices) {
      if (price.productId != product.id ||
          !marketPriceMatchesProduct(price, product) ||
          !_storeEnabled(price.storeName, enabledStores) ||
          !matchesConfiguredBranch(price.storeName, price.sourceLocationId) ||
          !price.isUsable(
            now: current,
            openPricesMaxAgeDays: openPricesMaxAgeDays,
          )) {
        continue;
      }
      quotes.add(ShoppingCandidateQuote(
        storeName: price.storeName,
        price: price.price,
        label: price.sourceLabel,
        observedAt: price.updatedAt,
        rankingPrice: price.price *
            (1 + marketPriceQuality(price, current).uncertaintyRate),
        sourcePriority: marketPriceSourcePriority(price.source),
      ));
    }
    final productStats = (identity.isGeneric
            ? receiptPriceStats.where(
                (stat) =>
                    stat.familyKey == identity.familyKey &&
                    (stat.productId == null || stat.productId == product.id),
              )
            : receiptStatsForProduct(product, receiptPriceStats))
        .where(
      (stat) =>
          stat.identityConfirmed &&
          stat.comparable &&
          stat.storeName.isNotEmpty &&
          !stat.latestAt.isBefore(cutoff) &&
          !stat.latestAt.isAfter(current) &&
          _storeEnabled(stat.storeName, enabledStores),
    );
    for (final stat in productStats) {
      final cheaperOfferAlreadyCoversStore = quotes.any(
        (quote) =>
            quote.storeName == stat.storeName &&
            quote.isOffer &&
            quote.price <= stat.medianPrice,
      );
      if (cheaperOfferAlreadyCoversStore) continue;
      quotes.add(ShoppingCandidateQuote(
        storeName: stat.storeName,
        price: stat.medianPrice,
        label: 'Bon-Median (historisch)',
        observedAt: stat.latestAt,
        sourcePriority: marketPriceSourcePriority(MarketPriceSource.receipt),
      ));
    }
    final historical = prospectPriceHistory[product.id]?.allSummaries ??
        const <ProspectPriceHistorySummary>[];
    final coveredStores = quotes.map((quote) => quote.storeName).toSet();
    for (final summary in historical) {
      if (summary.storeName.isEmpty ||
          coveredStores.contains(summary.storeName) ||
          !_storeEnabled(summary.storeName, enabledStores) ||
          !summary.medianPrice.isFinite ||
          summary.medianPrice <= 0) {
        continue;
      }
      quotes.add(ShoppingCandidateQuote(
        storeName: summary.storeName,
        price: summary.medianPrice,
        label: summary.kind == PriceObservationKind.offer
            ? 'Früheres Angebot (Median)'
            : 'Prospekt-Normalpreis (historisch)',
        observedAt: summary.latestValidUntil,
        isHistorical: true,
        sourcePriority: marketPriceSourcePriority(MarketPriceSource.prospect),
      ));
      // The primary summary is followed by alternatives for the same store.
      // Keep one conservative historical quote per store in the selector.
      coveredStores.add(summary.storeName);
    }
    quotes.sort((a, b) {
      if (a.isHistorical != b.isHistorical) return a.isHistorical ? 1 : -1;
      final comparison = a.comparisonPrice.compareTo(b.comparisonPrice);
      if (comparison != 0) return comparison;
      final nominal = a.price.compareTo(b.price);
      if (nominal != 0) return nominal;
      if (a.isOffer != b.isOffer) return a.isOffer ? -1 : 1;
      final source = a.sourcePriority.compareTo(b.sourcePriority);
      if (source != 0) return source;
      return a.storeName.compareTo(b.storeName);
    });
    result.add(ShoppingCandidate(product: product, quotes: quotes));
  }
  result.sort((a, b) {
    final aPrice = a.bestComparisonPrice ?? double.infinity;
    final bPrice = b.bestComparisonPrice ?? double.infinity;
    final priceOrder = aPrice.compareTo(bPrice);
    if (priceOrder == 0) {
      final aNominal = a.bestPrice ?? double.infinity;
      final bNominal = b.bestPrice ?? double.infinity;
      final nominalOrder = aNominal.compareTo(bNominal);
      if (nominalOrder != 0) return nominalOrder;
    }
    if (priceOrder != 0) return priceOrder;
    if (a.hasOffer != b.hasOffer) return a.hasOffer ? -1 : 1;
    return a.product.name.compareTo(b.product.name);
  });
  return result;
}

bool _storeEnabled(String store, Iterable<String> enabledStores) =>
    enabledStores.isEmpty || enabledStores.contains(store);

double? _verifiedOfferSavings(Offer offer, double effectivePrice) {
  if (!offer.originalPriceVerified ||
      !offer.originalPrice.isFinite ||
      offer.originalPrice <= effectivePrice) {
    return null;
  }
  final savings = double.parse(
    (offer.originalPrice - effectivePrice).toStringAsFixed(2),
  );
  return savings > 0 ? savings : null;
}

// Receipt labels such as "K.H-Milch" identify the milk family but do not
// state whether the shopper bought fresh milk or a fat-level H-milk variant.
// Keep each catalog identity selectable until the user chooses one; this
// mirrors the regular shopping search and never transfers a price between
// products.
bool _openMilkChoice(ProductIdentity request, ProductIdentity candidate) =>
    isOpenMilkChoice(request, candidate);
