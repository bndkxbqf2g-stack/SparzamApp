import 'package:shared_preferences/shared_preferences.dart';

import '../data/price_history.dart';
import '../models/price_point.dart';
import 'sequential_operation_queue.dart';

class PriceHistoryStore {
  static const _key = 'price_history_v1';
  static const retentionDays = 365;
  static final _queue = SequentialOperationQueue();
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<List<PricePoint>> load() => _queue.schedule(_loadNow);

  Future<List<PricePoint>> _loadNow() async {
    final raw = await _preferences.getStringList(_key);
    if (raw == null) {
      // Price history is evidence, so a fresh installation starts without
      // synthetic observations. Real history is added by receipts, offers,
      // Open Prices, or an explicit manual price.
      await _saveNow(const <PricePoint>[]);
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
    if (current.length != result.length) await _saveNow(current);
    return current;
  }

  Future<void> save(List<PricePoint> history) {
    final snapshot = List<PricePoint>.of(history, growable: false);
    return _queue.schedule(() => _saveNow(snapshot));
  }

  Future<void> _saveNow(List<PricePoint> history) => _preferences.setStringList(
    _key,
    history.map((item) => item.toJson()).toList(),
  );

  Future<List<PricePoint>> _mergeWithStored(
    List<PricePoint> current,
  ) async {
    final byKey = <String, PricePoint>{
      for (final point in await _loadNow()) point.observationKey: point,
    };
    for (final point in current) {
      byKey[point.observationKey] = point;
    }
    return byKey.values.toList();
  }

  Future<List<PricePoint>> upsertObservation(
    PricePoint point,
    List<PricePoint> current, {
    DateTime? now,
  }) => upsertObservations([point], current, now: now);

  Future<List<PricePoint>> upsertObservations(
    Iterable<PricePoint> points,
    List<PricePoint> current, {
    DateTime? now,
  }) {
    final valid = points.where((point) => point.price > 0).toList();
    final snapshot = List<PricePoint>.of(current, growable: false);
    return _queue.schedule(() async {
      final base = await _mergeWithStored(snapshot);
      if (valid.isEmpty) return base;

      final reference = now ?? DateTime.now();
      final today = DateTime(reference.year, reference.month, reference.day);
      final cutoff = today.subtract(const Duration(days: retentionDays));
      final next = base
          .where((item) => !item.date.isBefore(cutoff))
          .toList();
      for (final point in valid) {
        next.removeWhere((item) => item.observationKey == point.observationKey);
        next.add(point);
      }
      next.sort((a, b) => a.date.compareTo(b.date));

      await _saveNow(next);
      return next;
    });
  }

  Future<List<PricePoint>> removeProduct(
    String productId,
    List<PricePoint> current,
  ) {
    final snapshot = List<PricePoint>.of(current, growable: false);
    return _queue.schedule(() async {
      final base = await _mergeWithStored(snapshot);
      final next = base
          .where((item) => item.productId != productId)
          .toList();
      await _saveNow(next);
      return next;
    });
  }
}
