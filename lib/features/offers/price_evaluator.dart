import '../../models/offer.dart';
import '../../models/price_point.dart';

enum PriceLevel { great, normal, expensive }

class PriceEvaluation {
  const PriceEvaluation({
    required this.level,
    required this.normalPrice,
    required this.bestPrice,
    required this.savingPercent,
  });

  final PriceLevel level;
  final double normalPrice;
  final double bestPrice;
  final double savingPercent;
}

PriceEvaluation evaluatePrice(
  Offer offer,
  List<PricePoint> history, {
  double? currentPrice,
}) {
  final values = history
      .where((p) => p.productId == offer.productId && p.storeName == offer.storeName)
      .map((p) => p.price)
      .toList();

  final current = currentPrice ?? offer.offerPrice;
  final normal = values.isEmpty ? offer.originalPrice : _median(values);
  final best = values.isEmpty ? current : values.reduce((a, b) => a < b ? a : b);
  final saving = normal <= 0 ? 0.0 : ((normal - current) / normal) * 100;

  final level = current <= best || saving >= 15
      ? PriceLevel.great
      : current < normal
          ? PriceLevel.normal
          : PriceLevel.expensive;

  return PriceEvaluation(
    level: level,
    normalPrice: normal,
    bestPrice: best,
    savingPercent: saving,
  );
}
double _median(List<double> values) {
  final sorted = [...values]..sort();
  final middle = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[middle];
  return (sorted[middle - 1] + sorted[middle]) / 2;
}
