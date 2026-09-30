import '../../models/market_price.dart';
import '../../models/offer.dart';
import '../../models/product.dart';
import '../../models/receipt_price_stat.dart';
import '../catalog/product_identity.dart';
import '../offers/effective_price.dart';
import '../offers/offer_filter.dart';
import 'receipt_product_price_match.dart';

class ShoppingCandidateQuote {
  const ShoppingCandidateQuote({
    required this.storeName,
    required this.price,
    required this.label,
    this.observedAt,
    this.validUntil,
    this.imageUrl,
    this.isOffer = false,
  });

  final String storeName;
  final double price;
  final String label;
  final DateTime? observedAt;
  final DateTime? validUntil;
  final String? imageUrl;
  final bool isOffer;
}

class ShoppingCandidate {
  const ShoppingCandidate({required this.product, required this.quotes});

  final Product product;
  final List<ShoppingCandidateQuote> quotes;

  double? get bestPrice {
    final rankedQuotes = hasOffer
        ? quotes.where((quote) => quote.isOffer)
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
    return identities.any((candidate) =>
        compatibleProductIdentity(identity, candidate) ||
        _openMilkChoice(identity, candidate));
  });

  final result = <ShoppingCandidate>[];
  for (final product in products) {
    final quotes = <ShoppingCandidateQuote>[];
    for (final offer in offers) {
      if (offer.productId != product.id ||
          !_storeEnabled(offer.storeName, enabledStores) ||
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
          isOffer: true));
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
          stat.storeName.isNotEmpty &&
          stat.latestAt.isAfter(cutoff) &&
          _storeEnabled(stat.storeName, enabledStores),
    );
    for (final stat in productStats) {
      if (quotes.any((quote) =>
          quote.storeName == stat.storeName && quote.label == 'Angebot')) {
        continue;
      }
      quotes.add(ShoppingCandidateQuote(
        storeName: stat.storeName,
        price: stat.latestPrice,
        label: 'Bonpreis',
        observedAt: stat.latestAt,
      ));
    }
    quotes.sort((a, b) {
      if (a.isOffer != b.isOffer) return a.isOffer ? -1 : 1;
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

// Receipt labels such as "K.H-Milch" identify the H-milk family but do not
// print the fat percentage. Keep both catalog variants selectable until the
// user chooses one; this mirrors the regular shopping search and never
// transfers a variant's price to the other one.
bool _openMilkChoice(ProductIdentity request, ProductIdentity candidate) =>
    request.familyKey == 'milch' &&
    request.variant == 'h' &&
    request.fatPercent == null &&
    candidate.familyKey == 'milch' &&
    candidate.fatPercent != null &&
    candidate.variant == null;
