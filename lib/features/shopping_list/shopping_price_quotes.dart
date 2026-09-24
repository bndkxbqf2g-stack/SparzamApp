import '../../data/offers.dart';
import '../../models/list_item.dart';
import '../../models/market_price.dart';
import '../../models/offer.dart';

enum ShoppingQuoteKind { receipt, ownPrice, offer }

class ShoppingQuote {
  const ShoppingQuote({
    required this.storeName,
    required this.unitPrice,
    required this.kind,
    this.observedAt,
    this.offer,
  });

  final String storeName;
  final double unitPrice;
  final ShoppingQuoteKind kind;
  final DateTime? observedAt;
  final Offer? offer;

  String get sourceLabel => switch (kind) {
        ShoppingQuoteKind.receipt => 'Bonpreis vom ${_date(observedAt!)}',
        ShoppingQuoteKind.ownPrice => 'Eigener Preis vom ${_date(observedAt!)}',
        ShoppingQuoteKind.offer => 'Angebot bis ${_date(offer!.validUntil)}',
      };

  String get amountLabel =>
      '${unitPrice.toStringAsFixed(2).replaceAll('.', ',')} €';

  static String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}.${date.year}';
}

/// Exact product identity only. Receipts are observations of a purchase,
/// never a guarantee that a shelf price still applies today.
List<ShoppingQuote> shoppingQuotes(
  ListItem item, {
  required List<MarketPrice> prices,
  required List<Offer> offers,
  List<String> enabledStores = const [],
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final candidates = <ShoppingQuote>[];

  for (final price in prices) {
    if (price.productId != item.product.id ||
        price.source == MarketPriceSource.openPrices ||
        !price.price.isFinite ||
        price.price <= 0 ||
        (enabledStores.isNotEmpty &&
            !enabledStores.contains(price.storeName))) {
      continue;
    }
    candidates.add(ShoppingQuote(
      storeName: price.storeName,
      unitPrice: price.price,
      kind: price.source == MarketPriceSource.receipt
          ? ShoppingQuoteKind.receipt
          : ShoppingQuoteKind.ownPrice,
      observedAt: price.updatedAt,
    ));
  }

  for (final offer in offers) {
    if (offer.productId != item.product.id ||
        offer.validUntil.isBefore(DateTime(today.year, today.month, today.day)) ||
        (enabledStores.isNotEmpty &&
            !enabledStores.contains(offer.storeName)) ||
        sampleOffers.any((sample) =>
            sample.id == offer.id &&
            sample.productId == offer.productId &&
            sample.offerPrice == offer.offerPrice)) {
      continue;
    }
    // Coupon, cashback and multi-buy conditions are not assumed to apply.
    candidates.add(ShoppingQuote(
      storeName: offer.storeName,
      unitPrice: offer.offerPrice,
      kind: ShoppingQuoteKind.offer,
      offer: offer,
    ));
  }

  candidates.sort((a, b) {
    final sourceOrder =
        (a.kind == ShoppingQuoteKind.offer ? 0 : 1)
            .compareTo(b.kind == ShoppingQuoteKind.offer ? 0 : 1);
    if (sourceOrder != 0) return sourceOrder;
    final storeOrder = a.storeName.compareTo(b.storeName);
    if (storeOrder != 0) return storeOrder;
    return b.observedAt?.compareTo(a.observedAt ?? today) ?? 0;
  });
  return candidates;
}
