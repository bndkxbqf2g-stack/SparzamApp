import '../../models/product.dart';
import '../../models/purchase_record.dart';
import '../../models/replenishment_suggestion.dart';

List<ReplenishmentSuggestion> buildReplenishmentSuggestions({
  required List<PurchaseRecord> history,
  required List<Product> catalogProducts,
  required Set<String> currentListProductIds,
  DateTime? now,
  int dueSoonDays = 3,
  int minimumPurchases = 2,
}) {
  final today = _dateOnly(now ?? DateTime.now());
  final byProduct = <String, List<_ObservedPurchase>>{};

  for (final record in history) {
    final date = _dateOnly(record.createdAt);
    for (final line in record.items) {
      byProduct.putIfAbsent(line.productId, () => []).add(
            _ObservedPurchase(
              date: date,
              quantity: line.quantity,
            ),
          );
    }
  }

  final catalogById = {
    for (final product in catalogProducts) product.id: product,
  };
  final suggestions = <ReplenishmentSuggestion>[];

  for (final entry in byProduct.entries) {
    if (currentListProductIds.contains(entry.key)) continue;
    final product = catalogById[entry.key];
    if (product == null) continue;

    final purchases = entry.value..sort((a, b) => a.date.compareTo(b.date));
    if (purchases.length < minimumPurchases) continue;

    final intervals = <int>[];
    for (var index = 1; index < purchases.length; index++) {
      final days = purchases[index].date.difference(purchases[index - 1].date).inDays;
      if (days > 0) intervals.add(days);
    }
    if (intervals.isEmpty) continue;

    final intervalDays = _medianInt(intervals);
    final lastPurchasedAt = purchases.last.date;
    final dueAt = lastPurchasedAt.add(Duration(days: intervalDays));
    final daysUntilDue = dueAt.difference(today).inDays;
    if (daysUntilDue > dueSoonDays) continue;

    final averageQuantity =
        purchases.fold<int>(0, (sum, purchase) => sum + purchase.quantity) /
            purchases.length;

    suggestions.add(
      ReplenishmentSuggestion(
        product: product,
        purchaseCount: purchases.length,
        averageQuantity: averageQuantity,
        intervalDays: intervalDays,
        lastPurchasedAt: lastPurchasedAt,
        dueAt: dueAt,
        daysUntilDue: daysUntilDue,
        urgency: daysUntilDue <= 0
            ? ReplenishmentUrgency.overdue
            : ReplenishmentUrgency.dueSoon,
      ),
    );
  }

  suggestions.sort((a, b) {
    final byDue = a.daysUntilDue.compareTo(b.daysUntilDue);
    if (byDue != 0) return byDue;
    final byCount = b.purchaseCount.compareTo(a.purchaseCount);
    if (byCount != 0) return byCount;
    return a.product.name.compareTo(b.product.name);
  });

  return suggestions;
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

int _medianInt(List<int> values) {
  final sorted = [...values]..sort();
  final middle = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[middle];
  return ((sorted[middle - 1] + sorted[middle]) / 2).round();
}

class _ObservedPurchase {
  const _ObservedPurchase({
    required this.date,
    required this.quantity,
  });

  final DateTime date;
  final int quantity;
}
