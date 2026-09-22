import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/road_route_matrix.dart';

class RoadRouteMatrixStore {
  static const _key = 'road_route_matrix_v1';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<RoadRouteMatrix?> load(
    String originAddress, {
    DateTime? now,
    Duration maxAge = const Duration(hours: 24),
  }) async {
    final raw = await _preferences.getString(_key);
    if (raw == null || raw.isEmpty) return null;

    try {
      final matrix = RoadRouteMatrix.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      return matrix.originAddress == originAddress &&
              matrix.isFresh(now: now, maxAge: maxAge)
          ? matrix
          : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> save(RoadRouteMatrix matrix) =>
      _preferences.setString(_key, jsonEncode(matrix.toJson()));
}
