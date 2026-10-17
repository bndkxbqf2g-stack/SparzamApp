import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/route/market_price_selection.dart';
import 'package:sparzamapp/features/route/route_price_resolver.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/price_observation.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/store.dart';

void main() {
  final now = DateTime(2026, 10, 17);

  MarketPrice price({
    required MarketPriceSource source,
    double amount = 1,
    DateTime? updatedAt,
    double identityConfidence = 1,
    PriceObservationKind? kind,
    double? quantity,
    String? unit,
    String? sourceLocationId,
  }) =>
      MarketPrice(
        productId: 'milk',
        storeName: 'Lidl',
        price: amount,
        updatedAt: updatedAt ?? now,
        source: source,
        identityConfidence: identityConfidence,
        kind: kind ??
            (source == MarketPriceSource.prospect
                ? PriceObservationKind.regular
                : PriceObservationKind.unknown),
        quantity: quantity,
        unit: unit,
        sourceLocationId: sourceLocationId,
      );

  test('quality-adjusted amount beats a nominally cheaper uncertain source', () {
    final manual = price(source: MarketPriceSource.manual, amount: 1.00);
    final receipt = price(source: MarketPriceSource.receipt, amount: 0.98);

    final selected = preferredMarketPricesByKey(
      [receipt, manual],
      now,
    );

    expect(selected.values.single.source, MarketPriceSource.manual);
    expect(selected.values.single.price, 1.00);
  });

  test('newer evidence wins before source precedence', () {
    final oldReceipt = price(
      source: MarketPriceSource.receipt,
      updatedAt: DateTime(2026, 10, 15),
    );
    final newerProspect = price(
      source: MarketPriceSource.prospect,
      updatedAt: DateTime(2026, 10, 17),
    );

    final selected = preferredMarketPricesByKey(
      [oldReceipt, newerProspect],
      now,
    );

    expect(selected.values.single.source, MarketPriceSource.prospect);
  });

  test('equal amount and age use the documented source precedence', () {
    final openPrices = price(source: MarketPriceSource.openPrices);
    final prospect = price(source: MarketPriceSource.prospect);
    final receipt = price(source: MarketPriceSource.receipt);

    for (final order in [
      [openPrices, prospect, receipt],
      [receipt, openPrices, prospect],
      [prospect, receipt, openPrices],
    ]) {
      final selected = preferredMarketPricesByKey(order, now);
      expect(selected.values.single.source, MarketPriceSource.receipt);
    }
  });

  test('planning keeps exact branch slots separate', () {
    final first = price(
      source: MarketPriceSource.receipt,
      amount: 0.99,
      sourceLocationId: 'LIDL-THUENGERSHEIM',
    );
    final second = price(
      source: MarketPriceSource.receipt,
      amount: 1.09,
      sourceLocationId: 'lidl-wuerzburg',
    );

    final selected = preferredMarketPricesByKeyAndLocation(
      [first, second],
      now,
    );

    expect(selected, hasLength(2));
    expect(
      selected.values.map((item) => item.sourceLocationId),
      containsAll(['LIDL-THUENGERSHEIM', 'lidl-wuerzburg']),
    );
  });

  test('unconfirmed or incomplete evidence remains a data gap', () {
    final uncertain = price(
      source: MarketPriceSource.openPrices,
      identityConfidence: 0.5,
    );
    final missingUnit = price(
      source: MarketPriceSource.openPrices,
      quantity: 1000,
    );

    expect(preferredMarketPricesByKey([uncertain], now), isEmpty);
    expect(preferredMarketPricesByKey([missingUnit], now), isEmpty);
  });

  test('route resolver uses the same source precedence independent of input order', () {
    const product = Product(
      id: 'milk',
      name: 'Milch',
      unit: '1 l',
      group: 'milch',
    );
    const store = Store(
      name: 'Lidl',
      location: 'Ort',
      distanceKm: 1,
      prices: <String, double>{},
    );

    final receipt = price(source: MarketPriceSource.receipt);
    final prospect = price(source: MarketPriceSource.prospect);
    for (final order in [
      [prospect, receipt],
      [receipt, prospect],
    ]) {
      final quote = RoutePriceResolver(
        const [],
        marketPrices: order,
        now: now,
      ).quote(store, ListItem(product: product));

      expect(quote?.observation?.source, MarketPriceSource.receipt);
    }
  });
}
