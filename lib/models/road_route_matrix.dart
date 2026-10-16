class RoadRouteMatrix {
  const RoadRouteMatrix({
    required this.originAddress,
    required this.distancesKm,
    this.durationsMinutes = const <String, double>{},
    this.fetchedAt,
  });

  static const origin = '@origin';

  final String originAddress;
  final Map<String, double> distancesKm;

  /// Optional OSRM duration matrix in minutes. Older cached matrices may omit
  /// this field; callers must retain their deterministic speed fallback then.
  final Map<String, double> durationsMinutes;
  final DateTime? fetchedAt;

  bool isFresh({
    DateTime? now,
    Duration maxAge = const Duration(hours: 24),
  }) {
    final fetched = fetchedAt;
    if (fetched == null) return false;
    final reference = now ?? DateTime.now();
    if (fetched.isAfter(reference)) return false;
    return reference.difference(fetched) <= maxAge;
  }

  String _key(String from, String to) => '$from|$to';

  double? distance(String from, String to) {
    if (from == to) return 0;
    final value = distancesKm[_key(from, to)];
    return _usableNonNegative(value) ? value : null;
  }

  double? durationMinutes(String from, String to) {
    if (from == to) return 0;
    final value = durationsMinutes[_key(from, to)];
    return _usableNonNegative(value) ? value : null;
  }

  bool covers(Iterable<String> storeNames) {
    final nodes = [origin, ...storeNames];
    for (final from in nodes) {
      for (final to in nodes) {
        if (from == to) continue;
        if (distance(from, to) == null) return false;
      }
    }
    return true;
  }

  bool coversDurations(Iterable<String> storeNames) {
    final nodes = [origin, ...storeNames];
    for (final from in nodes) {
      for (final to in nodes) {
        if (from == to) continue;
        if (durationMinutes(from, to) == null) return false;
      }
    }
    return true;
  }

  Map<String, dynamic> toJson() => {
        'originAddress': originAddress,
        'distancesKm': distancesKm,
        'durationsMinutes': durationsMinutes,
        'fetchedAt': fetchedAt?.toIso8601String(),
      };

  factory RoadRouteMatrix.fromJson(Map<String, dynamic> json) {
    final originAddress = json['originAddress'];
    final fetchedAt = json['fetchedAt'];
    return RoadRouteMatrix(
      originAddress: originAddress is String ? originAddress : '',
      distancesKm: _readNonNegativeFiniteMap(json['distancesKm']),
      durationsMinutes: _readNonNegativeFiniteMap(json['durationsMinutes']),
      fetchedAt: fetchedAt is String ? DateTime.tryParse(fetchedAt) : null,
    );
  }

  static Map<String, double> _readNonNegativeFiniteMap(Object? raw) {
    if (raw is! Map) return const <String, double>{};
    final values = <String, double>{};
    for (final entry in raw.entries) {
      final key = entry.key.toString().trim();
      final value = entry.value;
      if (key.isEmpty || value is! num) continue;
      final number = value.toDouble();
      if (!number.isFinite || number < 0) continue;
      values[key] = number;
    }
    return values;
  }
}

bool _usableNonNegative(double? value) =>
    value != null && value.isFinite && value >= 0;
