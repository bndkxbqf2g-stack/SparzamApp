import '../../models/list_item.dart';
import '../../models/market_price.dart';
import '../../models/offer.dart';
import 'shopping_item_sorter.dart';

Map<String, List<ListItem>> groupShoppingItems(
  List<ListItem> items,
  List<Offer> offers, {
  List<String> enabledStoreNames = const [],
  List<MarketPrice> marketPrices = const [],
}) {
  final grouped = <String, List<ListItem>>{};
  for (final item in items) {
    grouped.putIfAbsent(item.product.group, () => []).add(item);
  }
  for (final entry in grouped.entries) {
    grouped[entry.key] = prioritizeOfferItems(
      entry.value,
      offers,
      enabledStoreNames: enabledStoreNames,
      marketPrices: marketPrices,
    );
  }
  return grouped;
}
