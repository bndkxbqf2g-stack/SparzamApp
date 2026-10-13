import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/road_route_matrix.dart';
import 'sequential_operation_queue.dart';
import 'travel_matrix_cache.dart';

class RoadRouteMatrixStore implements TravelMatrixCache {
  static const _key = 'road_route_matrix_v2';
  static const _legacyKey = 'road_route_matrix_v1';
  static final _queue = SequentialOperationQueue();
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  @override
  Future<RoadRouteMatrix?> load(
    String originAddress, {
    DateTime? now,
    Duration maxAge = const Duration(hours: 24),
  }) => _queue.schedule(() async {
    final entries = await _readEntries();
    final current = _decodeEntry(entries[_originKey(originAddress)]);
    if (current != null &&
        _sameOrigin(current.originAddress, originAddress) &&
        current.isFresh(now: now, maxAge: maxAge)) {
      return current;
    }

    // Read the v1 single-origin format for existing installations. It is kept
    // until a later write so an offline upgrade never destroys old evidence.
    final legacy = await _readLegacy();
    if (legacy == null || !_sameOrigin(legacy.originAddress, originAddress)) {
      return null;
    }
    return legacy.isFresh(now: now, maxAge: maxAge) ? legacy : null;
  });

  @override
  Future<void> save(RoadRouteMatrix matrix) {
    return _queue.schedule(() async {
      final entries = await _readEntries();
      entries[_originKey(matrix.originAddress)] = matrix.toJson();
      await _preferences.setString(
        _key,
        jsonEncode({'version': 1, 'entries': entries}),
      );
    });
  }

  Future<void> clear() => _queue.schedule(() async {
    await _preferences.remove(_key);
    await _preferences.remove(_legacyKey);
  });

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

  Future<RoadRouteMatrix?> _readLegacy() async {
    final raw = await _preferences.getString(_legacyKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      return RoadRouteMatrix.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  RoadRouteMatrix? _decodeEntry(Object? value) {
    if (value is! Map) return null;
    try {
      return RoadRouteMatrix.fromJson(
        value.map((key, raw) => MapEntry(key.toString(), raw)),
      );
    } catch (_) {
      return null;
    }
  }

  String _originKey(String originAddress) => originAddress
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ');

  bool _sameOrigin(String left, String right) =>
      _originKey(left) == _originKey(right);
}
