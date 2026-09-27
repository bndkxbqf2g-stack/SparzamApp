import '../../models/market_price.dart';
import '../../models/offer.dart';
import '../../models/product.dart';
import '../../models/receipt_price_stat.dart';
import '../catalog/product_identity.dart';
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
  });

  final String storeName;
  final double price;
  final String label;
  final DateTime? observedAt;
  final DateTime? validUntil;
  final String? imageUrl;
}

class ShoppingCandidate {
  const ShoppingCandidate({required this.product, required this.quotes});

  final Product product;
  final List<ShoppingCandidateQuote> quotes;

  double? get bestPrice => quotes.isEmpty ? null : quotes.map((q) => q.price).reduce((a, b) => a < b ? a : b);

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
    return identities.any((candidate) => compatibleProductIdentity(identity, candidate));
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
      quotes.add(ShoppingCandidateQuote(
        storeName: offer.storeName,
        price: offer.offerPrice,
        label: 'Angebot',
        validUntil: offer.validUntil,
        imageUrl: offer.imageUrl,
      ));
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
    final productStats = receiptStatsForProduct(product, receiptPriceStats).where(
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
    quotes.sort((a, b) => a.price.compareTo(b.price));
    result.add(ShoppingCandidate(product: product, quotes: quotes));
  }
  result.sort((a, b) {
    final aPrice = a.bestPrice ?? double.infinity;
    final bPrice = b.bestPrice ?? double.infinity;
    final priceOrder = aPrice.compareTo(bPrice);
    return priceOrder == 0 ? a.product.name.compareTo(b.product.name) : priceOrder;
  });
  return result;
}

bool _storeEnabled(String store, Iterable<String> enabledStores) =>
    enabledStores.isEmpty || enabledStores.contains(store);
