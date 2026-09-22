import '../../data/stores.dart';
import '../../models/list_item.dart';
import '../../models/offer.dart';
import '../route/route_price_resolver.dart';

class ShoppingOfferHint {
  const ShoppingOfferHint({
    required this.storeName,
    required this.unitPrice,
    required this.total,
    required this.savings,
    required this.offer,
  });

  final String storeName;
  final double unitPrice;
  final double total;
  final double savings;
  final Offer offer;
}

ShoppingOfferHint? bestShoppingOffer(
  ListItem item,
  List<Offer> offers, {
  DateTime? now,
  List<String> enabledStoreNames = const <String>[],
}) {
  final resolver = RoutePriceResolver(offers, now: now);
  ShoppingOfferHint? best;

  for (final store in stores) {
    if (enabledStoreNames.isNotEmpty &&
        !enabledStoreNames.contains(store.name)) {
      continue;
    }
    final quote = resolver.quote(store, item);
    if (quote == null || !quote.usesOffer || quote.offer == null) continue;

    final candidate = ShoppingOfferHint(
      storeName: store.name,
      unitPrice: quote.unitPrice,
      total: quote.total,
      savings: quote.savings,
      offer: quote.offer!,
    );

    if (best == null || candidate.total < best.total) best = candidate;
  }

  return best;
}
