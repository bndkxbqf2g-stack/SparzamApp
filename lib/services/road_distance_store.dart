import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class RoadDistanceStore {
  static const _key = 'road_distances_v1';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<Map<String, double>> load() async {
    final raw = await _preferences.getString(_key);
    if (raw == null || raw.isEmpty) return <String, double>{};

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return json.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      );
    } catch (_) {
      return <String, double>{};
    }
  }

  Future<void> save(Map<String, double> distances) =>
      _preferences.setString(_key, jsonEncode(distances));
}
