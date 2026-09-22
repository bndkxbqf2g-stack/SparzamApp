import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/shell/shell_pricing.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/price_data_settings.dart';
import 'package:sparzamapp/models/price_point.dart';

void main() {
  final manual = MarketPrice(
    productId: 'milk',
    storeName: 'Lidl',
    price: 1.19,
    updatedAt: DateTime(2026, 9, 22),
  );
  final external = MarketPrice(
    productId: 'milk',
    storeName: 'REWE',
    price: 1.09,
    updatedAt: DateTime.now(),
    source: MarketPriceSource.openPrices,
  );

  test('deaktivierte externe Quelle lässt nur eigene Preise durch', () {
    final result = activePrices(
      [manual, external],
      const PriceDataSettings(openPricesEnabled: false),
    );

    expect(result, [manual]);
  });

  test('Preisquelle wird korrekt in den Verlauf übertragen', () {
    expect(priceHistoryPoint(manual).source, PricePointSource.manual);
    expect(priceHistoryPoint(external).source, PricePointSource.openPrices);
  });
}
