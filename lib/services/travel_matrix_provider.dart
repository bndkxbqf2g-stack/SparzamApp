import '../models/road_route_matrix.dart';

/// Routing provider boundary kept separate from shopping route optimization.
abstract interface class TravelMatrixProvider {
  bool get enabled;

  Future<double?> fetchKm(String destination);

  Future<RoadRouteMatrix?> fetchMatrix(
    Map<String, String> destinations,
  );

  void close();
}
