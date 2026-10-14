import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/road_route_matrix.dart';
import 'travel_matrix_cache.dart';
import 'travel_matrix_provider.dart';

/// OSRM/Nominatim adapter used only to obtain travel distances.
///
/// The provider is switchable and every network boundary is injectable for
/// deterministic tests or a self-hosted endpoint. It never decides which
/// products or markets belong in a shopping route.
class RoadDistanceService implements TravelMatrixProvider {
  RoadDistanceService({
    required this.originAddress,
    http.Client? client,
    this.geocodeDelay = const Duration(milliseconds: 1100),
    this.enabled = true,
    Uri? osrmBaseUri,
    Uri? geocodingBaseUri,
    this.matrixCache,
    this.matrixCacheMaxAge = const Duration(hours: 24),
    this.routeTimeout = const Duration(seconds: 10),
    this.matrixTimeout = const Duration(seconds: 15),
    this.geocodeTimeout = const Duration(seconds: 10),
  })  : _client = client ?? http.Client(),
        _osrmBaseUri =
            osrmBaseUri ?? Uri.parse('https://router.project-osrm.org'),
        _geocodingBaseUri = geocodingBaseUri ??
            Uri.parse('https://nominatim.openstreetmap.org');

  final String originAddress;
  final http.Client _client;
  final Duration geocodeDelay;
  @override
  final bool enabled;
  final Uri _osrmBaseUri;
  final Uri _geocodingBaseUri;
  final TravelMatrixCache? matrixCache;
  final Duration matrixCacheMaxAge;
  final Duration routeTimeout;
  final Duration matrixTimeout;
  final Duration geocodeTimeout;
  _Coordinate? _origin;

  @override
  Future<double?> fetchKm(String destination) async {
    if (!enabled) return null;

    try {
      final origin = _origin ??= await _geocode(originAddress);
      final target = await _geocode(destination);
      if (origin == null || target == null) return null;

      final routeUri = _osrmUri(
        'route',
        '${origin.longitude},${origin.latitude};'
        '${target.longitude},${target.latitude}',
        {'overview': 'false'},
      );
      final response = await _client
          .get(routeUri, headers: const {'Accept': 'application/json'})
          .timeout(routeTimeout);
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = json['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;
      final route = routes.first as Map<String, dynamic>;
      final meters = (route['distance'] as num?)?.toDouble();
      if (meters == null || !meters.isFinite || meters < 0) return null;
      return meters / 1000;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<RoadRouteMatrix?> fetchMatrix(
    Map<String, String> destinations,
  ) async {
    if (!enabled) return null;

    final requested = destinations.entries
        .where((entry) => entry.value.trim().isNotEmpty)
        .map((entry) => entry.key)
        .toList();
    if (requested.isEmpty) return null;

    RoadRouteMatrix? cached;
    final cache = matrixCache;
    if (cache != null) {
      try {
        cached = await cache.load(
          originAddress,
          now: DateTime.now(),
          maxAge: matrixCacheMaxAge,
        );
        if (cached != null && cached.covers(requested)) return cached;
      } catch (_) {
        // A cache outage must not disable a live routing attempt.
      }
    }

    try {
      final origin = _origin ??= await _geocode(originAddress);
      if (origin == null) return cached;

      final names = <String>[RoadRouteMatrix.origin];
      final coordinates = <_Coordinate>[origin];

      for (final entry in destinations.entries) {
        if (entry.value.trim().isEmpty) continue;
        if (geocodeDelay > Duration.zero) {
          await Future<void>.delayed(geocodeDelay);
        }
        final coordinate = await _geocode(entry.value);
        if (coordinate == null) continue;
        names.add(entry.key);
        coordinates.add(coordinate);
      }

      if (coordinates.length < 2) return cached;

      final coordinateText = coordinates
          .map(
            (point) => '${point.longitude},${point.latitude}',
          )
          .join(';');
      final uri = _osrmUri(
        'table',
        coordinateText,
        {'annotations': 'distance,duration'},
      );
      final response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(matrixTimeout);
      if (response.statusCode != 200) return cached;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final rows = json['distances'] as List<dynamic>?;
      if (rows == null || rows.length != coordinates.length) return cached;

      final distances = <String, double>{};
      for (var from = 0; from < rows.length; from++) {
        final row = rows[from] as List<dynamic>;
        if (row.length != coordinates.length) return cached;
        for (var to = 0; to < row.length; to++) {
          if (from == to) continue;
          final meters = (row[to] as num?)?.toDouble();
          if (meters == null || !meters.isFinite || meters < 0) continue;
          distances['${names[from]}|${names[to]}'] = meters / 1000;
        }
      }

      // Duration data is useful for time-value planning but remains optional:
      // older/self-hosted OSRM responses may publish distances only.
      final durations = <String, double>{};
      final durationRows = json['durations'] as List<dynamic>?;
      if (durationRows != null && durationRows.length == coordinates.length) {
        for (var from = 0; from < durationRows.length; from++) {
          final row = durationRows[from];
          if (row is! List<dynamic> || row.length != coordinates.length) {
            continue;
          }
          for (var to = 0; to < row.length; to++) {
            if (from == to) continue;
            final seconds = (row[to] as num?)?.toDouble();
            if (seconds == null || !seconds.isFinite || seconds < 0) continue;
            durations['${names[from]}|${names[to]}'] = seconds / 60;
          }
        }
      }

      final matrix = RoadRouteMatrix(
        originAddress: originAddress,
        distancesKm: distances,
        durationsMinutes: durations,
        fetchedAt: DateTime.now(),
      );
      if (cache != null) {
        try {
          await cache.save(matrix);
        } catch (_) {
          // A cache write failure must not hide a valid live matrix.
        }
      }
      return matrix;
    } catch (_) {
      return cached;
    }
  }

  Future<_Coordinate?> _geocode(String query) async {
    final uri = _geocodingUri(query);
    final response = await _client
        .get(
          uri,
          headers: const {
            'Accept': 'application/json',
            'User-Agent': 'SparzamApp/1.0 (route geocoding)',
          },
        )
        .timeout(geocodeTimeout);
    if (response.statusCode != 200) return null;

    final json = jsonDecode(response.body) as List<dynamic>;
    if (json.isEmpty) return null;
    final first = json.first as Map<String, dynamic>;
    final latitude = double.tryParse(first['lat'] as String? ?? '');
    final longitude = double.tryParse(first['lon'] as String? ?? '');
    if (latitude == null ||
        longitude == null ||
        !latitude.isFinite ||
        !longitude.isFinite) {
      return null;
    }
    return _Coordinate(latitude: latitude, longitude: longitude);
  }

  Uri _osrmUri(
    String service,
    String coordinates,
    Map<String, String> query,
  ) {
    final path = _joinPath(
      _osrmBaseUri.path,
      '$service/v1/driving/$coordinates',
    );
    return _osrmBaseUri.replace(path: path, queryParameters: query);
  }

  Uri _geocodingUri(String query) {
    final path = _joinPath(_geocodingBaseUri.path, 'search');
    return _geocodingBaseUri.replace(
      path: path,
      queryParameters: {
        'format': 'jsonv2',
        'limit': '1',
        'countrycodes': 'de',
        'q': query,
      },
    );
  }

  String _joinPath(String prefix, String suffix) {
    final normalized = prefix.endsWith('/')
        ? prefix.substring(0, prefix.length - 1)
        : prefix;
    return '$normalized/$suffix';
  }

  @override
  void close() => _client.close();
}

class _Coordinate {
  const _Coordinate({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}
