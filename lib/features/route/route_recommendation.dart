import '../../models/mobility_settings.dart';
import '../../models/route_plan.dart';

class RouteRecommendationInfo {
  const RouteRecommendationInfo({
    required this.title,
    required this.detail,
  });

  final String title;
  final String detail;
}

RouteRecommendationInfo buildRouteRecommendationInfo({
  required RoutePlan recommended,
  required RoutePlan cheapest,
  required RoutePlan? singleStore,
  required MobilitySettings mobility,
}) {
  if (recommended.stores.length > 1 && singleStore != null) {
    final savings = singleStore.total - recommended.total;
    return RouteRecommendationInfo(
      title: 'Mehrere Märkte lohnen sich',
      detail:
          '${recommended.stores.length} Märkte sparen insgesamt '
          '${savings.toStringAsFixed(2)} € gegenüber dem besten Einzelmarkt.',
    );
  }

  if (cheapest.stores.length > recommended.stores.length &&
      cheapest.total < recommended.total) {
    final extraStores = cheapest.stores.length - recommended.stores.length;
    final possibleSavings = recommended.total - cheapest.total;
    final threshold = mobility.minExtraStoreSavings * extraStores;
    return RouteRecommendationInfo(
      title: 'Weniger Wege sind sinnvoller',
      detail:
          '$extraStores zusätzliche ${extraStores == 1 ? 'Markt' : 'Märkte'} '
          'würden nur ${possibleSavings.toStringAsFixed(2)} € sparen. '
          'Deine Schwelle liegt bei ${threshold.toStringAsFixed(2)} €.',
    );
  }

  return const RouteRecommendationInfo(
    title: 'Ein Markt reicht für diese Liste',
    detail:
        'Ein zusätzlicher Markt bringt nach Preisen und Fahrtkosten keinen ausreichenden Vorteil.',
  );
}
