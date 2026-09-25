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
}
