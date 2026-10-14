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

  double? distance(String from, String to) =>
      from == to ? 0 : distancesKm[_key(from, to)];

  double? durationMinutes(String from, String to) =>
      from == to ? 0 : durationsMinutes[_key(from, to)];

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

  factory RoadRouteMatrix.fromJson(Map<String, dynamic> json) =>
      RoadRouteMatrix(
        originAddress: json['originAddress'] as String,
        distancesKm:
            (json['distancesKm'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ),
        durationsMinutes:
            (json['durationsMinutes'] as Map<String, dynamic>?)?.map(
                  (key, value) => MapEntry(key, (value as num).toDouble()),
                ) ??
                const <String, double>{},
        fetchedAt: json['fetchedAt'] == null
            ? null
            : DateTime.tryParse(json['fetchedAt'] as String),
      );
}
