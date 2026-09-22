import '../../models/price_point.dart';

class PriceHistoryStats {
  const PriceHistoryStats({
    required this.samples,
    required this.samples30,
    required this.samples90,
    this.normal90,
    this.best30,
    this.best90,
    this.latest,
    this.changeFromNormalPercent,
  });

  final int samples;
  final int samples30;
  final int samples90;
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
  final reference = now ?? DateTime.now();
  final today = DateTime(reference.year, reference.month, reference.day);
  final cutoff30 = today.subtract(const Duration(days: 30));
  final cutoff90 = today.subtract(const Duration(days: 90));

  final matching = history
      .where(
        (point) =>
            point.productId == productId &&
            point.storeName == storeName &&
            !DateTime(point.date.year, point.date.month, point.date.day)
                .isAfter(today),
      )
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  final days90 =
      matching
          .where(
            (point) => !DateTime(
              point.date.year,
              point.date.month,
              point.date.day,
            ).isBefore(cutoff90),
          )
          .toList();
  final days30 =
      matching
          .where(
            (point) => !DateTime(
              point.date.year,
              point.date.month,
              point.date.day,
            ).isBefore(cutoff30),
          )
          .toList();

  final normal90 = days90.isEmpty
      ? null
      : _median(days90.map((point) => point.price).toList());
  final latest = matching.isEmpty ? null : matching.last.price;

  return PriceHistoryStats(
    samples: matching.length,
    samples30: days30.length,
    samples90: days90.length,
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
