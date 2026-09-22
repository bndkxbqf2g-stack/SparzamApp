import '../../models/price_point.dart';

class PriceHistoryStats {
  const PriceHistoryStats({
    required this.samples,
    this.normal90,
    this.best30,
    this.best90,
    this.latest,
    this.changeFromNormalPercent,
  });

  final int samples;
  final double? normal90;
  final double? best30;
  final double? best90;
  final double? latest;
  final double? changeFromNormalPercent;
}

PriceHistoryStats priceHistoryStats(
  List<PricePoint> history, {
  required String productId,
  required String storeName,
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final cutoff30 = today.subtract(const Duration(days: 30));
  final cutoff90 = today.subtract(const Duration(days: 90));

  final matching = history
      .where(
        (point) =>
            point.productId == productId &&
            point.storeName == storeName &&
            !point.date.isAfter(today),
      )
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  final days90 =
      matching.where((point) => !point.date.isBefore(cutoff90)).toList();
  final days30 =
      matching.where((point) => !point.date.isBefore(cutoff30)).toList();

  final normal90 = days90.isEmpty
      ? null
      : _median(days90.map((point) => point.price).toList());
  final latest = matching.isEmpty ? null : matching.last.price;

  return PriceHistoryStats(
    samples: matching.length,
    normal90: normal90,
    best30: _minimum(days30),
    best90: _minimum(days90),
    latest: latest,
    changeFromNormalPercent: normal90 == null ||
            latest == null ||
            normal90 <= 0
        ? null
        : ((latest - normal90) / normal90) * 100,
  );
}

double? _minimum(List<PricePoint> values) {
  if (values.isEmpty) return null;
  return values
      .map((point) => point.price)
      .reduce((a, b) => a < b ? a : b);
}

double _median(List<double> values) {
  final sorted = [...values]..sort();
  final middle = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[middle];
  return (sorted[middle - 1] + sorted[middle]) / 2;
}
