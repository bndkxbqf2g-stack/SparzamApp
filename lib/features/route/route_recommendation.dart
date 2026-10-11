import '../../models/mobility_settings.dart';
import '../../models/route_plan.dart';

class RouteRecommendationInfo {
  const RouteRecommendationInfo({required this.title, required this.detail});

  final String title;
  final String detail;
}

RouteRecommendationInfo buildRouteRecommendationInfo({
  required RoutePlan recommended,
  required RoutePlan cheapest,
  required RoutePlan? singleStore,
  required MobilitySettings mobility,
}) {
  if (recommended.hasDataGaps) {
    final percent = (recommended.priceCoverage * 100).round();
    return RouteRecommendationInfo(
      title: 'Noch keine belastbare Gesamtempfehlung',
      detail:
          'Für $percent % der Liste liegen belastbare Preise vor. '
          'Die aktuelle Route vergleicht deshalb nur den preislich belegten Teil '
          'und ist noch keine Empfehlung für den vollständigen Einkauf.',
    );
  }

  if (recommended.stores.length > 1 && singleStore != null) {
    if (singleStore.hasDataGaps) {
      final singlePercent = (singleStore.priceCoverage * 100).round();
      final recommendedPercent = (recommended.priceCoverage * 100).round();
      return RouteRecommendationInfo(
        title: 'Mehrere Märkte sichern die Preisabdeckung',
        detail:
            'Der beste Einzelmarkt deckt nur $singlePercent % der Liste ab. '
            'Die empfohlene Route deckt $recommendedPercent % ab. Die Empfehlung '
            'beruht damit auf vollständiger Preisabdeckung.',
      );
    }
    final savings = singleStore.planningScore - recommended.planningScore;
    if (savings > 0) {
      return RouteRecommendationInfo(
        title: 'Mehrere Märkte lohnen sich',
        detail:
            '${recommended.stores.length} Märkte verbessern den Planungswert '
            'um ${savings.toStringAsFixed(2)} € gegenüber dem besten Einzelmarkt.'
            '${_timeValueSuffix(mobility)}',
      );
    }
  }

  if (cheapest.stores.length > recommended.stores.length &&
      cheapest.planningScore < recommended.planningScore) {
    final extraStores = cheapest.stores.length - recommended.stores.length;
    final possibleSavings = recommended.planningScore - cheapest.planningScore;
    final threshold = mobility.minExtraStoreSavings * extraStores;
    return RouteRecommendationInfo(
      title: 'Weniger Wege sind sinnvoller',
      detail:
          '$extraStores zusätzliche ${extraStores == 1 ? 'Markt' : 'Märkte'} '
          'würden den Planungswert nur um ${possibleSavings.toStringAsFixed(2)} € verbessern. '
          'Deine Schwelle liegt bei ${threshold.toStringAsFixed(2)} €.'
          '${_timeValueSuffix(mobility)}',
    );
  }

  return RouteRecommendationInfo(
    title: 'Ein Markt reicht für diese Liste',
    detail:
        'Ein zusätzlicher Markt bringt nach ${_planningBasis(mobility)} '
        'keinen ausreichenden Vorteil.',
  );
}

String _planningBasis(MobilitySettings mobility) =>
    mobility.timeValuePerHour > 0
    ? 'Preisen, Fahrtkosten und Zeitwert'
    : 'Preisen und Fahrtkosten';

String _timeValueSuffix(MobilitySettings mobility) =>
    mobility.timeValuePerHour > 0
    ? ' Der persönliche Zeitwert von '
          '${mobility.timeValuePerHour.toStringAsFixed(2)} €/Std. ist dabei '
          'im Planungswert enthalten.'
    : '';
