import 'dart:convert';

import 'package:http/http.dart' as http;

class RoadDistanceService {
  RoadDistanceService({http.Client? client}) : _client = client ?? http.Client();

  static const originAddress = '97225 Zellingen, Germany';
  final http.Client _client;
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
        .get(uri, headers: const {'Accept': 'application/json'})
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
  const _Coordinate({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}
