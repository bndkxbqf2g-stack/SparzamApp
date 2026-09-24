import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/price_observation.dart';

/// Local append-only evidence for small, user-relevant data sets. A scalable
/// indexed backend can replace this store without changing observation IDs.
class PriceObservationStore {
  PriceObservationStore({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const storageKey = 'price_observations_v1';
  static Future<void> _pending = Future<void>.value();
  final SharedPreferencesAsync _preferences;

  Future<List<PriceObservation>> load() async {
    final raw = await _preferences.getStringList(storageKey) ?? const [];
    final observations = <PriceObservation>[];
    for (final value in raw) {
      try {
        observations.add(PriceObservation.fromJson(
            jsonDecode(value) as Map<String, dynamic>));
      } catch (_) {
        // A corrupt entry does not hide the remaining price evidence.
      }
    }
    return observations;
  }

  Future<List<PriceObservation>> append(
      Iterable<PriceObservation> incoming) {
    final valid = incoming.where((entry) => entry.isValid).toList();
    final result = _pending.then((_) async {
      final existing = await load();
      final ids = existing.map((entry) => entry.id).toSet();
      final additions = valid.where((entry) => ids.add(entry.id)).toList();
      if (additions.isEmpty) return existing;
      final next = [...existing, ...additions];
      await _preferences.setStringList(storageKey,
          next.map((entry) => jsonEncode(entry.toJson())).toList());
      return next;
    });
    _pending = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }
}
