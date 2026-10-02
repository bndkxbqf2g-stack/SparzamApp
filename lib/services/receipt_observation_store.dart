import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/receipt_observation.dart';

class ReceiptObservationStore {
  static const _key = 'receipt_observations_v1';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<List<ReceiptObservation>> load() async {
    final values = await _preferences.getStringList(_key);
    if (values == null) return <ReceiptObservation>[];
    final result = <ReceiptObservation>[];
    for (final value in values) {
      try {
        result.add(
          ReceiptObservation.fromJson(
            jsonDecode(value) as Map<String, dynamic>,
          ),
        );
      } catch (_) {
        // Defekte Einzelbeobachtungen blockieren die übrige Preishistorie nicht.
      }
    }
    return result;
  }

  Future<int> addMany(Iterable<ReceiptObservation> observations) async {
    final current = await load();
    final byId = <String, ReceiptObservation>{
      for (final item in current) item.id: item,
    };
    var changedCount = 0;
    var changed = false;
    for (final observation in observations) {
      final previous = byId[observation.id];
      if (previous == null) {
        changedCount++;
        changed = true;
      } else if (jsonEncode(previous.toJson()) !=
          jsonEncode(observation.toJson())) {
        changedCount++;
        changed = true;
      }
      byId[observation.id] = observation;
    }
    if (!changed) return 0;
    final next = byId.values.toList()
      ..sort((a, b) => b.observedAt.compareTo(a.observedAt));
    await _preferences.setStringList(
      _key,
      next.map((item) => jsonEncode(item.toJson())).toList(),
    );
    // The import dialog uses this value to decide whether an import changed
    // anything. Count updates as well as first-time inserts so a corrected
    // identity is not reported as an empty save.
    return changedCount;
  }

  Future<void> replaceAll(List<ReceiptObservation> observations) =>
      _preferences.setStringList(
        _key,
        observations.map((item) => jsonEncode(item.toJson())).toList(),
      );
}
