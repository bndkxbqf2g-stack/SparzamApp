class RoadRouteMatrix {
  const RoadRouteMatrix({
    required this.originAddress,
    required this.distancesKm,
    this.fetchedAt,
  });

  static const origin = '@origin';

  final String originAddress;
  final Map<String, double> distancesKm;
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

  Map<String, dynamic> toJson() => {
        'originAddress': originAddress,
        'distancesKm': distancesKm,
        'fetchedAt': fetchedAt?.toIso8601String(),
      };

  factory RoadRouteMatrix.fromJson(Map<String, dynamic> json) =>
      RoadRouteMatrix(
        originAddress: json['originAddress'] as String,
        distancesKm:
            (json['distancesKm'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ),
        fetchedAt: json['fetchedAt'] == null
            ? null
            : DateTime.tryParse(json['fetchedAt'] as String),
      );
}
