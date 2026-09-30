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
      // Price history is evidence, so a fresh installation starts without
      // synthetic observations. Real history is added by receipts, offers,
      // Open Prices, or an explicit manual price.
      await save(const <PricePoint>[]);
      return <PricePoint>[];
    }

    final result = <PricePoint>[];
    for (final value in raw) {
      try {
        result.add(PricePoint.fromJson(value));
      } catch (_) {
        // Einzelne defekte Alt-Einträge nicht den kompletten Verlauf zerstören.
      }
    }
    // Older releases persisted a fixed sample history on first start. Remove
    // only those exact observations so any user-created history survives.
    final sampleKeys = samplePriceHistory
        .map((point) => point.observationKey)
        .toSet();
    final current = result
        .where((point) => !sampleKeys.contains(point.observationKey))
        .toList(growable: false);
    if (current.length != result.length) await save(current);
    return current;
  }

  Future<void> save(List<PricePoint> history) => _preferences.setStringList(
    _key,
    history.map((item) => item.toJson()).toList(),
  );

  Future<List<PricePoint>> upsertObservation(
    PricePoint point,
    List<PricePoint> current, {
    DateTime? now,
  }) => upsertObservations([point], current, now: now);

  Future<List<PricePoint>> upsertObservations(
    Iterable<PricePoint> points,
    List<PricePoint> current, {
    DateTime? now,
  }) async {
    final valid = points.where((point) => point.price > 0).toList();
    if (valid.isEmpty) return [...current];

    final reference = now ?? DateTime.now();
    final today = DateTime(reference.year, reference.month, reference.day);
    final cutoff = today.subtract(const Duration(days: retentionDays));
    final next = current.where((item) => !item.date.isBefore(cutoff)).toList();
    for (final point in valid) {
      next.removeWhere((item) => item.observationKey == point.observationKey);
      next.add(point);
    }
    next.sort((a, b) => a.date.compareTo(b.date));

    await save(next);
    return next;
  }

  Future<List<PricePoint>> removeProduct(
    String productId,
    List<PricePoint> current,
  ) async {
    final next = current.where((item) => item.productId != productId).toList();
    await save(next);
    return next;
  }
}
