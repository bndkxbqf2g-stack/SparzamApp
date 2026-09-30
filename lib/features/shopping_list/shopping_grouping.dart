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
    final group = shoppingGroupBucket(item.product.group);
    grouped.putIfAbsent(group, () => []).add(item);
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

String shoppingGroupBucket(String group) => switch (group) {
  'butter' || 'milch' || 'eier' || 'joghurt' => 'milch',
  'obst' => 'obst',
  'fleisch' || 'wurst' => 'fleisch',
  'nudeln' => 'nudeln',
  'backwaren' || 'brot' => 'backwaren',
  'getraenke' || 'getränke' => 'getraenke',
  'vorrat' || 'konserven' || 'aufstrich' || 'kaffee' => 'vorrat',
  'tiefkuehl' || 'tiefkühl' => 'tiefkuehl',
  'haushalt' => 'haushalt',
  'drogerie' => 'drogerie',
  'non-food' || 'nonfood' => 'nonfood',
  _ => 'other',
};

int shoppingGroupRank(String group) =>
    const {
      'obst': 0,
      'milch': 1,
      'fleisch': 2,
      'backwaren': 3,
      'getraenke': 4,
      'nudeln': 5,
      'vorrat': 5,
      'tiefkuehl': 6,
      'haushalt': 7,
      'drogerie': 7,
      'nonfood': 8,
      'other': 9,
    }[group] ??
    99;
