import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/route/route_recommendation.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/mobility_settings.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/route_plan.dart';
import 'package:sparzamapp/models/store.dart';

void main() {
  const a = Store(
    name: 'A',
    location: 'Ort',
    distanceKm: 1,
    prices: {},
  );
  const b = Store(
    name: 'B',
    location: 'Ort',
    distanceKm: 2,
    prices: {},
  );

  RoutePlan plan(List<Store> stores, double total) => RoutePlan(
        stores: stores,
        assignments: const {},
        basket: total,
        travel: 0,
        total: total,
        unassigned: const [],
      );

  test('erklärt wenn zusätzlicher Markt Schwelle nicht erreicht', () {
    final recommended = plan([a], 10);
    final cheapest = plan([a, b], 9.70);

    final info = buildRouteRecommendationInfo(
      recommended: recommended,
      cheapest: cheapest,
      singleStore: recommended,
      mobility: const MobilitySettings(minExtraStoreSavings: 0.50),
    );

    expect(info.title, 'Weniger Wege sind sinnvoller');
    expect(info.detail, contains('0.30 €'));
    expect(info.detail, contains('0.50 €'));
  });

  test('erklärt wenn mehrere Märkte wirklich sparen', () {
    final single = plan([a], 12);
    final recommended = plan([a, b], 10);

    final info = buildRouteRecommendationInfo(
      recommended: recommended,
      cheapest: recommended,
      singleStore: single,
      mobility: const MobilitySettings(),
    );

    expect(info.title, 'Mehrere Märkte lohnen sich');
    expect(info.detail, contains('2.00 €'));
  });
  test('incomplete route does not claim a complete recommendation', () {
    const product = Product(id: 'missing', name: 'Schmand', unit: 'Stück', group: 'molkerei');
    final incomplete = RoutePlan(
      stores: const [a],
      assignments: const {},
      basket: 0.95,
      travel: 3.90,
      total: 4.85,
      unassigned: [ListItem(product: product)],
    );

    final info = buildRouteRecommendationInfo(
      recommended: incomplete,
      cheapest: incomplete,
      singleStore: incomplete,
      mobility: const MobilitySettings(),
    );

    expect(info.title, 'Noch keine belastbare Gesamtempfehlung');
    expect(info.detail, contains('vollständigen Einkauf'));
  });

  test('route plan exposes incomplete price coverage as data gap', () {
    const product = Product(
      id: 'unknown',
      name: 'Bergkäse',
      unit: 'Stück',
      group: 'kaese',
    );
    final missing = ListItem(product: product, quantity: 1);

    final incomplete = RoutePlan(
      stores: const [a],
      assignments: const {},
      basket: 0,
      travel: 0,
      total: 0,
      unassigned: [missing],
    );

    expect(incomplete.hasDataGaps, isTrue);
    expect(incomplete.missingItemCount, 1);
    expect(incomplete.pricedItemCount, 0);
    expect(incomplete.priceCoverage, 0);
  });
}
