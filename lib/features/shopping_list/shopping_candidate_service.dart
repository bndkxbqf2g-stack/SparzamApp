import '../../models/market_price.dart';
import '../../models/offer.dart';
import '../../models/price_observation.dart';
import '../../models/product.dart';
import '../../models/receipt_price_stat.dart';
import '../catalog/product_identity.dart';
import '../offers/effective_price.dart';
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
}

class ShoppingCandidate {
  const ShoppingCandidate({required this.product, required this.quotes});

  final Product product;
  final List<ShoppingCandidateQuote> quotes;

  double? get bestPrice {
    final currentQuotes = quotes.where((quote) => !quote.isHistorical);
    final rankedQuotes = hasOffer
        ? quotes.where((quote) => quote.isOffer)
        : currentQuotes.isNotEmpty
            ? currentQuotes
            : quotes;
    if (rankedQuotes.isEmpty) return null;
    return rankedQuotes.map((quote) => quote.price).reduce(
          (a, b) => a < b ? a : b,
        );
  }

  bool get hasOffer => quotes.any((quote) => quote.isOffer);

  String? get imageUrl {
    for (final quote in quotes) {
      final url = quote.imageUrl?.trim();
      if (url != null && url.isNotEmpty) return url;
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
          !_storeEnabled(offer.storeName, enabledStores) ||
          isSampleOffer(offer) ||
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
          savings: _verifiedOfferSavings(offer, effective.finalPrice)));
    }
    for (final price in marketPrices) {
      if (price.productId != product.id ||
          !_storeEnabled(price.storeName, enabledStores) ||
          !price.isUsable(now: current, openPricesMaxAgeDays: historyDays)) {
        continue;
      }
      quotes.add(ShoppingCandidateQuote(
        storeName: price.storeName,
        price: price.price,
        label: price.sourceLabel,
        observedAt: price.updatedAt,
      ));
    }
    final productStats = (identity.isGeneric
            ? receiptPriceStats.where((stat) => stat.familyKey == identity.familyKey)
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
      if (quotes.any((quote) =>
          quote.storeName == stat.storeName && quote.isOffer)) {
        continue;
      }
      quotes.add(ShoppingCandidateQuote(
        storeName: stat.storeName,
        price: stat.medianPrice,
        label: 'Bon-Median (historisch)',
        observedAt: stat.latestAt,
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
      ));
      // The primary summary is followed by alternatives for the same store.
      // Keep one conservative historical quote per store in the selector.
      coveredStores.add(summary.storeName);
    }
    quotes.sort((a, b) {
      if (a.isOffer != b.isOffer) return a.isOffer ? -1 : 1;
      if (a.isHistorical != b.isHistorical) return a.isHistorical ? 1 : -1;
      final price = a.price.compareTo(b.price);
      return price != 0 ? price : a.storeName.compareTo(b.storeName);
    });
    result.add(ShoppingCandidate(product: product, quotes: quotes));
  }
  result.sort((a, b) {
    if (a.hasOffer != b.hasOffer) return a.hasOffer ? -1 : 1;
    final aPrice = a.bestPrice ?? double.infinity;
    final bPrice = b.bestPrice ?? double.infinity;
    final priceOrder = aPrice.compareTo(bPrice);
    return priceOrder == 0 ? a.product.name.compareTo(b.product.name) : priceOrder;
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
