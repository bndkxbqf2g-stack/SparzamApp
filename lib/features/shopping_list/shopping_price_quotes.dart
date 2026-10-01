import '../../data/offers.dart';
import '../../data/stores.dart';
import '../../models/list_item.dart';
import '../../models/market_price.dart';
import '../../models/offer.dart';
import '../offers/effective_price.dart';
import '../offers/offer_filter.dart';

bool isSampleOffer(Offer offer) => sampleOffers.any((sample) =>
    sample.id == offer.id &&
    sample.productId == offer.productId &&
    sample.storeName == offer.storeName &&
    sample.offerPrice == offer.offerPrice);

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
        ShoppingQuoteKind.offer =>
            'Angebot${(offer!.hasCoupon || offer!.hasCashback) ? ', effektiv' : ''} '
            'bis ${_date(offer!.validUntil)}',
      };

  String get displayPrefix => switch (kind) {
        ShoppingQuoteKind.receipt => 'Bonpreis',
        ShoppingQuoteKind.ownPrice => 'Eigener Preis',
        ShoppingQuoteKind.offer =>
            'Angebot${(offer!.hasCoupon || offer!.hasCashback) ? ', effektiv' : ''}',
      };

  String get amountLabel =>
      '${unitPrice.toStringAsFixed(2).replaceAll('.', ',')} €';

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
  const ShoppingPriceMatrixEntry({
    required this.storeName,
    this.quote,
  });

  final String storeName;
  final ShoppingQuote? quote;

  bool get hasQuote => quote != null;
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
    candidates.add(ShoppingQuote(
      storeName: offer.storeName,
      unitPrice: effective.finalPrice,
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

/// Resolves one best visible quote per enabled market while retaining markets
/// without evidence. Offers are preferred over non-offer observations, and
/// the cheapest active offer wins within a market. For non-offer evidence the
/// newest observation wins; a lower price is only a deterministic tie-breaker.
List<ShoppingPriceMatrixEntry> shoppingPriceMatrix(
  ListItem item, {
  required List<MarketPrice> prices,
  required List<Offer> offers,
  List<String> enabledStores = const [],
  DateTime? now,
}) {
  final quotes = shoppingQuotes(
    item,
    prices: prices,
    offers: offers,
    enabledStores: enabledStores,
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
    return ShoppingPriceMatrixEntry(
      storeName: storeName,
      quote: sorted.first,
    );
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
  final aOffer = a.kind == ShoppingQuoteKind.offer;
  final bOffer = b.kind == ShoppingQuoteKind.offer;
  if (aOffer != bOffer) return aOffer ? -1 : 1;
  if (aOffer) {
    final byPrice = a.unitPrice.compareTo(b.unitPrice);
    if (byPrice != 0) return byPrice;
  } else {
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
  }
  return a.sourceLabel.compareTo(b.sourceLabel);
}
