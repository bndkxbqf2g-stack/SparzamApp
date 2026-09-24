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

  test('deaktivierte externe Quelle lässt eigene und aktuelle Bonpreise durch', () {
    final receipt = MarketPrice(
      productId: 'milk', storeName: 'Netto', price: 1.15,
      updatedAt: DateTime.now(), source: MarketPriceSource.receipt,
    );
    final result = activePrices(
      [manual, receipt, external],
      const PriceDataSettings(openPricesEnabled: false),
    );

    expect(result, [manual, receipt]);
  });

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
  test('historical receipt is excluded even with external sync disabled', () {
    final oldReceipt = MarketPrice(
      productId: 'bread', storeName: 'Netto', price: 1.19,
      updatedAt: DateTime(2025, 1, 1),
      source: MarketPriceSource.receipt,
    );
    final result = activePrices(
      [manual, oldReceipt],
      const PriceDataSettings(openPricesEnabled: false),
    );
    expect(result, [manual]);
  });

}
