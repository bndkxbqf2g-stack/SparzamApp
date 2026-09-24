import '../../models/receipt_observation.dart';
import '../../models/receipt_price_stat.dart';
import 'receipt_observation_builder.dart';

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
    if (item.observedAt.isBefore(cutoff)) {
      continue;
    }

    // Always derive the family from the original receipt label. This also
    // repairs legacy observations with stale or accidentally wrong family keys.
    final familyKey = inferReceiptFamily(item.rawLabel);
    if (familyKey.isEmpty) continue;
    final normalized = ReceiptObservation(
      id: item.id,
      receiptFingerprint: item.receiptFingerprint,
      rowLine: item.rowLine,
      rawLabel: item.rawLabel,
      familyKey: familyKey,
      storeName: item.storeName,
      observedAt: item.observedAt,
      totalPrice: item.totalPrice,
      quantity: item.quantity,
      quantityUnit: item.quantityUnit,
      unitPrice: item.unitPrice,
      discounted: item.discounted,
      productId: item.productId,
    );
    final identity = item.productId == null
        ? 'family:$familyKey'
        : 'product:${item.productId}';
    groups.putIfAbsent('$identity|${item.storeName}', () => []).add(normalized);
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
      productId: entries.first.productId,
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
  final median = values.length.isOdd
      ? values[middle]
      : (values[middle - 1] + values[middle]) / 2;
  return (median * 100).roundToDouble() / 100;
}
