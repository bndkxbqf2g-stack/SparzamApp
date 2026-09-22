import '../../models/offer.dart';
import '../../models/price_point.dart';
import 'price_history_stats.dart';

enum PriceLevel { great, normal, expensive }

class PriceEvaluation {
  const PriceEvaluation({
    required this.level,
    required this.normalPrice,
    required this.bestPrice,
    required this.savingPercent,
    required this.sampleCount,
    this.best30Price,
    this.best90Price,
  });

  final PriceLevel level;
  final double normalPrice;
  final double bestPrice;
  final double savingPercent;
  final int sampleCount;
  final double? best30Price;
  final double? best90Price;
}

PriceEvaluation evaluatePrice(
  Offer offer,
  List<PricePoint> history, {
  double? currentPrice,
  DateTime? now,
}) {
  final current = currentPrice ?? offer.offerPrice;
  final stats = priceHistoryStats(
    history,
    productId: offer.productId,
    storeName: offer.storeName,
    now: now,
  );

  final normal = stats.normal90 ?? offer.originalPrice;
  final best = stats.best90 ?? current;
  final saving =
      normal <= 0 ? 0.0 : ((normal - current) / normal) * 100;

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
    sampleCount: stats.samples,
    best30Price: stats.best30,
    best90Price: stats.best90,
  );
}
