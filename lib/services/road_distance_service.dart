import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/road_route_matrix.dart';

class RoadDistanceService {
  RoadDistanceService({
    required this.originAddress,
    http.Client? client,
    this.geocodeDelay = const Duration(milliseconds: 1100),
  }) : _client = client ?? http.Client();

  final String originAddress;
  final http.Client _client;
  final Duration geocodeDelay;
  _Coordinate? _origin;

  Future<double?> fetchKm(String destination) async {
    try {
      final origin = _origin ??= await _geocode(originAddress);
      final target = await _geocode(destination);
      if (origin == null || target == null) return null;

      final routeUri = Uri.https(
        'router.project-osrm.org',
        '/route/v1/driving/'
            '${origin.longitude},${origin.latitude};'
            '${target.longitude},${target.latitude}',
        {'overview': 'false'},
      );
      final response = await _client
          .get(routeUri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = json['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;
      final route = routes.first as Map<String, dynamic>;
      final meters = (route['distance'] as num?)?.toDouble();
      return meters == null ? null : meters / 1000;
    } catch (_) {
      return null;
    }
  }

  Future<RoadRouteMatrix?> fetchMatrix(
    Map<String, String> destinations,
  ) async {
    try {
      final origin = _origin ??= await _geocode(originAddress);
      if (origin == null) return null;

      final names = <String>[RoadRouteMatrix.origin];
      final coordinates = <_Coordinate>[origin];

      for (final entry in destinations.entries) {
        if (entry.value.trim().isEmpty) continue;
        if (coordinates.length > 1 && geocodeDelay > Duration.zero) {
          await Future<void>.delayed(geocodeDelay);
        }
        final coordinate = await _geocode(entry.value);
        if (coordinate == null) continue;
        names.add(entry.key);
        coordinates.add(coordinate);
      }

      if (coordinates.length < 2) return null;

      final coordinateText = coordinates
          .map(
            (point) => '${point.longitude},${point.latitude}',
          )
          .join(';');
      final uri = Uri.https(
        'router.project-osrm.org',
        '/table/v1/driving/$coordinateText',
        {'annotations': 'distance'},
      );
      final response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final rows = json['distances'] as List<dynamic>?;
      if (rows == null || rows.length != coordinates.length) return null;

      final distances = <String, double>{};
      for (var from = 0; from < rows.length; from++) {
        final row = rows[from] as List<dynamic>;
        if (row.length != coordinates.length) return null;
        for (var to = 0; to < row.length; to++) {
          if (from == to) continue;
          final meters = (row[to] as num?)?.toDouble();
          if (meters == null) continue;
          distances['${names[from]}|${names[to]}'] = meters / 1000;
        }
      }

      return RoadRouteMatrix(
        originAddress: originAddress,
        distancesKm: distances,
      );
    } catch (_) {
      return null;
    }
  }

  Future<_Coordinate?> _geocode(String query) async {
    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      {
        'format': 'jsonv2',
        'limit': '1',
        'countrycodes': 'de',
        'q': query,
      },
    );
    final response = await _client
        .get(
          uri,
          headers: const {
            'Accept': 'application/json',
            'User-Agent': 'SparzamApp/1.0 (route geocoding)',
          },
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;

    final json = jsonDecode(response.body) as List<dynamic>;
    if (json.isEmpty) return null;
    final first = json.first as Map<String, dynamic>;
    final latitude = double.tryParse(first['lat'] as String? ?? '');
    final longitude = double.tryParse(first['lon'] as String? ?? '');
    if (latitude == null || longitude == null) return null;
    return _Coordinate(latitude: latitude, longitude: longitude);
  }

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
