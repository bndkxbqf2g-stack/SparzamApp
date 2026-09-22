import '../../models/list_item.dart';
import '../../models/offer.dart';
import 'shopping_offer_hint.dart';

List<ListItem> prioritizeOfferItems(
  List<ListItem> items,
  List<Offer> offers, {
  DateTime? now,
}) {
  final indexed = items.indexed.map((entry) {
    final hint = bestShoppingOffer(entry.$2, offers, now: now);
    return _RankedItem(
      item: entry.$2,
      originalIndex: entry.$1,
      savings: hint?.savings ?? 0,
      hasOffer: hint != null,
    );
  }).toList();

  indexed.sort((a, b) {
    if (a.hasOffer != b.hasOffer) return a.hasOffer ? -1 : 1;
    if (a.hasOffer && b.hasOffer) {
      final bySavings = b.savings.compareTo(a.savings);
      if (bySavings != 0) return bySavings;
    }
    return a.originalIndex.compareTo(b.originalIndex);
  });

  return indexed.map((entry) => entry.item).toList();
}

class _RankedItem {
  const _RankedItem({
    required this.item,
    required this.originalIndex,
    required this.savings,
    required this.hasOffer,
  });

  final ListItem item;
  final int originalIndex;
  final double savings;
  final bool hasOffer;
}
