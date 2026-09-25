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

  /// Replaces evidence with the same stable ID. This is reserved for
  /// deterministic derived observations (for example reinterpreted receipts),
  /// so identity improvements do not leave stale projections behind.
  Future<List<PriceObservation>> upsertById(
      Iterable<PriceObservation> incoming) {
    final valid = incoming.where((entry) => entry.isValid).toList();
    final result = _pending.then((_) async {
      final existing = await load();
      final byId = <String, PriceObservation>{
        for (final entry in existing) entry.id: entry,
      };
      var changed = false;
      for (final entry in valid) {
        final previous = byId[entry.id];
        final previousJson =
            previous == null ? null : jsonEncode(previous.toJson());
        final nextJson = jsonEncode(entry.toJson());
        if (previousJson != nextJson) changed = true;
        byId[entry.id] = entry;
      }
      if (!changed) return existing;
      final next = byId.values.toList(growable: false);
      await _preferences.setStringList(
        storageKey,
        next.map((entry) => jsonEncode(entry.toJson())).toList(),
      );
      return next;
    });
    _pending = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }
}
