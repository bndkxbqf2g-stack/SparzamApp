import 'package:shared_preferences/shared_preferences.dart';

import '../data/price_history.dart';
import '../models/price_point.dart';

class PriceHistoryStore {
  static const _key = 'price_history_v1';
  static const retentionDays = 365;
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<List<PricePoint>> load() async {
    final raw = await _preferences.getStringList(_key);
    if (raw == null) {
      await save(samplePriceHistory);
      return [...samplePriceHistory];
    }

    final result = <PricePoint>[];
    for (final value in raw) {
      try {
        result.add(PricePoint.fromJson(value));
      } catch (_) {
        // Einzelne defekte Alt-Einträge nicht den kompletten Verlauf zerstören.
      }
    }
    return result;
  }

  Future<void> save(List<PricePoint> history) =>
      _preferences.setStringList(
        _key,
        history.map((item) => item.toJson()).toList(),
      );

  Future<List<PricePoint>> upsertObservation(
    PricePoint point,
    List<PricePoint> current, {
    DateTime? now,
  }) async {
    if (point.price <= 0) return [...current];

    final reference = now ?? DateTime.now();
    final today = DateTime(reference.year, reference.month, reference.day);
    final cutoff = today.subtract(const Duration(days: retentionDays));
    final next = [
      ...current.where(
        (item) =>
            item.observationKey != point.observationKey &&
            !item.date.isBefore(cutoff),
      ),
      point,
    ]..sort((a, b) => a.date.compareTo(b.date));

    await save(next);
    return next;
  }

  Future<List<PricePoint>> removeProduct(
    String productId,
    List<PricePoint> current,
  ) async {
    final next =
        current.where((item) => item.productId != productId).toList();
    await save(next);
    return next;
  }
}
