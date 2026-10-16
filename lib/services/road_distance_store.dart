import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'sequential_operation_queue.dart';

class RoadDistanceStore {
  static const _key = 'road_distances_v3';
  static const _legacyKey = 'road_distances_v2';
  static final _queue = SequentialOperationQueue();
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<Map<String, double>> load(String originAddress) =>
      _queue.schedule(() async {
        final entries = await _readEntries();
        final current = _decodeEntry(
          entries[_originKey(originAddress)],
          originAddress,
        );
        if (current != null) return current;

        // Keep installations from v2 readable. The next save writes the new
        // multi-origin format without deleting this legacy value first.
        final legacy = await _preferences.getString(_legacyKey);
        return _decodeLegacy(legacy, originAddress) ?? <String, double>{};
      });

  Future<void> save(
    String originAddress,
    Map<String, double> distances,
  ) {
    final snapshot = Map<String, double>.from(distances);
    return _queue.schedule(() async {
      final entries = await _readEntries();
      entries[_originKey(originAddress)] = {
        'originAddress': originAddress,
        'distances': snapshot,
      };
      await _preferences.setString(
        _key,
        jsonEncode({'version': 1, 'entries': entries}),
      );
    });
  }

  Future<Map<String, dynamic>> _readEntries() async {
    final raw = await _preferences.getString(_key);
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return <String, dynamic>{};
      final entries = json['entries'];
      if (entries is! Map) return <String, dynamic>{};
      return entries.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Map<String, double>? _decodeLegacy(String? raw, String originAddress) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic> ||
          !_sameOrigin(json['originAddress'], originAddress)) {
        return null;
      }
      return _decodeDistances(json['distances']);
    } catch (_) {
      return null;
    }
  }

  Map<String, double>? _decodeEntry(Object? value, String originAddress) {
    if (value is! Map) return null;
    if (!_sameOrigin(value['originAddress'], originAddress)) return null;
    return _decodeDistances(value['distances']);
  }

  Map<String, double>? _decodeDistances(Object? value) {
    if (value is! Map) return null;
    final distances = <String, double>{};
    for (final entry in value.entries) {
      final key = entry.key.toString().trim();
      final raw = entry.value;
      if (key.isEmpty || raw is! num) continue;
      final distance = raw.toDouble();
      if (!distance.isFinite || distance < 0) continue;
      distances[key] = distance;
    }
    return distances;
  }

  String _originKey(String originAddress) => originAddress
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ');

  bool _sameOrigin(Object? stored, String requested) =>
      stored is String && _originKey(stored) == _originKey(requested);
}
