import '../../models/product.dart';
import '../../models/purchase_record.dart';
import '../../models/receipt_observation.dart';
import '../../models/replenishment_suggestion.dart';

List<ReplenishmentSuggestion> buildReplenishmentSuggestions({
  required List<PurchaseRecord> history,
  required List<Product> catalogProducts,
  required Set<String> currentListProductIds,
  Iterable<ReceiptObservation> receiptObservations =
      const <ReceiptObservation>[],
  DateTime? now,
  int dueSoonDays = 3,
  int minimumPurchases = 2,
}) {
  final today = _dateOnly(now ?? DateTime.now());
  final purchaseQuantityByProduct = <String, Map<DateTime, double>>{};
  final receiptQuantityByProduct = <String, Map<DateTime, double>>{};

  for (final record in history) {
    final date = _dateOnly(record.createdAt);
    if (date.isAfter(today)) continue;
    for (final line in record.items) {
      if (line.productId.trim().isEmpty || line.quantity <= 0) continue;
      final daily = purchaseQuantityByProduct.putIfAbsent(
        line.productId,
        () => <DateTime, double>{},
      );
      daily[date] = (daily[date] ?? 0) + line.quantity;
    }
  }

  for (final observation in receiptObservations) {
    final productId = observation.productId;
    final date = _dateOnly(observation.observedAt);
    final quantity = _receiptReplenishmentQuantity(observation);
    if (productId == null ||
        productId.trim().isEmpty ||
        date.isAfter(today) ||
        quantity == null) {
      continue;
    }
    final daily = receiptQuantityByProduct.putIfAbsent(
      productId,
      () => <DateTime, double>{},
    );
    daily[date] = (daily[date] ?? 0) + quantity;
  }

  final byProduct = <String, List<_ObservedPurchase>>{};
  for (final productId in {
    ...purchaseQuantityByProduct.keys,
    ...receiptQuantityByProduct.keys,
  }) {
    final purchaseDays = purchaseQuantityByProduct[productId] ?? const {};
    final receiptDays = receiptQuantityByProduct[productId] ?? const {};
    final dates = {...purchaseDays.keys, ...receiptDays.keys}.toList()..sort();
    byProduct[productId] = [
      for (final date in dates)
        _ObservedPurchase(
          date: date,
          // A receipt and a completed in-app purchase on the same day may be
          // the same shopping trip. Use the larger source quantity instead
          // of counting that trip twice.
          quantity: _maxNullable(purchaseDays[date], receiptDays[date])!,
          fromPurchaseHistory: purchaseDays.containsKey(date),
          fromConfirmedReceipt: receiptDays.containsKey(date),
        ),
    ];
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
      final days = purchases[index].date
          .difference(purchases[index - 1].date)
          .inDays;
      if (days > 0) intervals.add(days);
    }
    if (intervals.isEmpty) continue;

    final intervalDays = _medianInt(intervals);
    final lastPurchasedAt = purchases.last.date;
    final dueAt = lastPurchasedAt.add(Duration(days: intervalDays));
    final daysUntilDue = dueAt.difference(today).inDays;
    if (daysUntilDue > dueSoonDays) continue;

    final averageQuantity =
        purchases.fold<double>(0, (sum, purchase) => sum + purchase.quantity) /
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
        fromPurchaseHistory: purchases.any(
          (purchase) => purchase.fromPurchaseHistory,
        ),
        fromConfirmedReceipts: purchases.any(
          (purchase) => purchase.fromConfirmedReceipt,
        ),
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

double? _maxNullable(double? first, double? second) {
  if (first == null) return second;
  if (second == null) return first;
  return first > second ? first : second;
}

double? _receiptReplenishmentQuantity(ReceiptObservation observation) {
  if (!observation.identityConfirmed) return null;
  final unit = observation.quantityUnit.trim().toLowerCase();
  final countUnit =
      unit.isEmpty ||
      unit == 'stück' ||
      unit == 'stueck' ||
      unit == 'stk' ||
      unit == 'st' ||
      unit == 'pack' ||
      unit == 'packung' ||
      unit == 'einheit';
  // Weight and volume need package semantics before they can become a
  // repeat quantity. They remain valid price evidence, but not replenishment
  // evidence here.
  if (!countUnit) return null;
  final quantity = observation.quantity?.toDouble() ?? 1;
  if (!quantity.isFinite || quantity <= 0) return null;
  return quantity;
}

class _ObservedPurchase {
  const _ObservedPurchase({
    required this.date,
    required this.quantity,
    required this.fromPurchaseHistory,
    required this.fromConfirmedReceipt,
  });

  final DateTime date;
  final double quantity;
  final bool fromPurchaseHistory;
  final bool fromConfirmedReceipt;
}
