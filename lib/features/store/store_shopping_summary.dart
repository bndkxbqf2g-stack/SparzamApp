import '../../models/list_item.dart';
import '../../models/market_price.dart';
import '../../models/offer.dart';
import '../../models/store.dart';
import '../route/route_price_resolver.dart';

class StoreShoppingLine {
  const StoreShoppingLine({
    required this.item,
    required this.unitPrice,
    required this.total,
    required this.regularTotal,
    required this.savings,
    required this.usesOffer,
  });

  final ListItem item;
  final double unitPrice;
  final double total;
  final double regularTotal;
  final double savings;
  final bool usesOffer;
}

class StoreShoppingSummary {
  const StoreShoppingSummary({
    required this.lines,
    required this.total,
    required this.regularTotal,
    required this.savings,
  });

  final List<StoreShoppingLine> lines;
  final double total;
  final double regularTotal;
  final double savings;
}

StoreShoppingSummary buildStoreShoppingSummary(
  Store store,
  List<ListItem> items,
  List<Offer> offers, {
  DateTime? now,
  List<MarketPrice> marketPrices = const <MarketPrice>[],
}) {
  final resolver = RoutePriceResolver(
    offers,
    now: now,
    marketPrices: marketPrices,
  );
  final lines = <StoreShoppingLine>[];

  for (final item in items) {
    final quote = resolver.quote(store, item);
    if (quote == null || quote.isEstimated) continue;
    lines.add(
      StoreShoppingLine(
        item: item,
        unitPrice: quote.unitPrice,
        total: quote.total,
        regularTotal: quote.regularTotal,
        savings: quote.savings,
        usesOffer: quote.usesOffer,
      ),
    );
  }

  lines.sort((a, b) {
    if (a.usesOffer != b.usesOffer) return a.usesOffer ? -1 : 1;
    final savings = b.savings.compareTo(a.savings);
    if (savings != 0) return savings;
    return a.item.product.name.compareTo(b.item.product.name);
  });

  final total = lines.fold<double>(0, (sum, line) => sum + line.total);
  final regularTotal =
      lines.fold<double>(0, (sum, line) => sum + line.regularTotal);

  return StoreShoppingSummary(
    lines: lines,
    total: total,
    regularTotal: regularTotal,
    savings: regularTotal - total,
  );
}
