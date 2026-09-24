import '../../models/receipt_observation.dart';
import '../../models/receipt_price_stat.dart';

List<ReceiptPriceStat> buildReceiptPriceStats(
  Iterable<ReceiptObservation> observations, {
  DateTime? now,
  int maxAgeDays = 90,
}) {
  final today = now ?? DateTime.now();
  final cutoff = DateTime(today.year, today.month, today.day)
      .subtract(Duration(days: maxAgeDays));
  final groups = <String, List<ReceiptObservation>>{};

  for (final item in observations) {
    if (item.discounted || item.familyKey.isEmpty ||
        item.observedAt.isBefore(cutoff)) {
      continue;
    }
    groups.putIfAbsent('${item.familyKey}|${item.storeName}', () => [])
        .add(item);
  }

  final result = <ReceiptPriceStat>[];
  for (final entries in groups.values) {
    entries.sort((a, b) => b.observedAt.compareTo(a.observedAt));
    final unitEntries = entries.where((e) => e.unitPrice != null).toList();
    final comparable = unitEntries.length == entries.length;
    final values = (comparable
            ? unitEntries.map((e) => e.unitPrice!)
            : entries.map((e) => e.totalPrice))
        .toList()
      ..sort();
    result.add(ReceiptPriceStat(
      familyKey: entries.first.familyKey,
      storeName: entries.first.storeName,
      latestPrice: comparable
          ? entries.first.unitPrice!
          : entries.first.totalPrice,
      latestAt: entries.first.observedAt,
      observationCount: entries.length,
      medianPrice: _median(values),
      comparable: comparable,
      priceBasis: comparable ? entries.first.quantityUnit : 'Packung',
    ));
  }
  result.sort((a, b) => b.latestAt.compareTo(a.latestAt));
  return result;
}

double _median(List<double> values) {
  final middle = values.length ~/ 2;
  if (values.length.isOdd) return values[middle];
  return (values[middle - 1] + values[middle]) / 2;
}
