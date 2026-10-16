import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/route/route_optimizer.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/store.dart';

void main() {
  const product = Product(
    id: 'test',
    name: 'Test',
    unit: '1 Stk',
    group: 'test',
  );
  const store = Store(
    name: 'Markt',
    location: 'Ort',
    distanceKm: 10,
    prices: {'test': 1.0},
  );

  test('reale Straßenentfernung überschreibt Fallback-Distanz', () {
    final optimizer = RouteOptimizer(
      [ListItem(product: product)],
      const [],
      roadDistances: const {'Markt': 4.0},
    );

    expect(optimizer.travelCost([store]), closeTo(1.76, 0.001));
  });

  test('eigener Kilometerpreis wird verwendet', () {
    final optimizer = RouteOptimizer(
      [ListItem(product: product)],
      const [],
      roadDistances: const {'Markt': 4.0},
      euroPerKm: 0.50,
    );

    expect(optimizer.travelCost([store]), closeTo(4.0, 0.001));
  });

  test('ohne Straßenentfernung bleibt Fallback aktiv', () {
    final optimizer = RouteOptimizer(
      [ListItem(product: product)],
      const [],
    );

    expect(optimizer.travelCost([store]), closeTo(4.40, 0.001));
  });
  test('ungültige Matrix- und Fallback-Distanzen werden nicht geroutet', () {
    final matrixOptimizer = RouteOptimizer(
      [ListItem(product: product)],
      const [],
      roadMatrix: const RoadRouteMatrix(
        originAddress: 'Start',
        distancesKm: {
          '@origin|Markt': -2,
          'Markt|@origin': -2,
        },
      ),
    );
    final fallbackOptimizer = RouteOptimizer(
      [ListItem(product: product)],
      const [],
      roadDistances: {'Markt': double.nan},
    );

    expect(matrixOptimizer.travelCost([store]), closeTo(4.40, 0.001));
    expect(fallbackOptimizer.travelCost([store]), closeTo(4.40, 0.001));
  });

  test('ungültige Planungsparameter fallen auf sichere Defaults zurück', () {
    final optimizer = RouteOptimizer(
      const [],
      const [],
      euroPerKm: -1,
      maxStores: 0,
      minExtraStoreSavings: double.nan,
      additionalStoreCost: -2,
      timeValuePerHour: double.infinity,
      travelMinutesPerKm: -3,
      openPricesMaxAgeDays: -1,
    );

    expect(optimizer.euroPerKm, 0.22);
    expect(optimizer.maxStores, 1);
    expect(optimizer.minExtraStoreSavings, 0);
    expect(optimizer.additionalStoreCost, 0);
    expect(optimizer.timeValuePerHour, 0);
    expect(optimizer.travelMinutesPerKm, closeTo(60 / 45, 0.0001));
    expect(optimizer.openPricesMaxAgeDays, 60);
  });

}
