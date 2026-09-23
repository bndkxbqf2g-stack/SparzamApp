import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/catalog/market_price_freshness.dart';
import 'package:sparzamapp/features/catalog/price_coverage.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  final now = DateTime(2026, 9, 22);

  test('manuelle Preise veralten nicht automatisch', () {
    final manual = MarketPrice(
      productId: 'a',
      storeName: 'Lidl',
      price: 2.49,
      updatedAt: DateTime(2025, 1, 1),
    );

    expect(
      manual.isUsable(now: now, openPricesMaxAgeDays: 60),
      isTrue,
    );
  });

  test('alte Open-Prices-Daten werden herausgefiltert', () {
    final prices = [
      MarketPrice(
        productId: 'a',
        storeName: 'Lidl',
        price: 2.49,
        updatedAt: DateTime(2026, 9, 10),
        source: MarketPriceSource.openPrices,
      ),
      MarketPrice(
        productId: 'b',
        storeName: 'Lidl',
        price: 3.49,
        updatedAt: DateTime(2026, 6, 1),
        source: MarketPriceSource.openPrices,
      ),
    ];

    final usable = usableMarketPrices(
      prices,
      openPricesMaxAgeDays: 60,
      now: now,
    );

    expect(usable.map((item) => item.productId), ['a']);
  });

  test('Coverage zählt EAN, Quellen und veraltete Werte', () {
    const products = [
      Product(
        id: 'a',
        name: 'A',
        unit: '1 Stk',
        group: 'x',
        ean: '123',
      ),
      Product(
        id: 'b',
        name: 'B',
        unit: '1 Stk',
        group: 'x',
      ),
    ];
    final prices = [
      MarketPrice(
        productId: 'a',
        storeName: 'Lidl',
        price: 1,
        updatedAt: DateTime(2026, 9, 20),
      ),
      MarketPrice(
        productId: 'a',
        storeName: 'ALDI Süd',
        price: 2,
        updatedAt: DateTime(2026, 6, 1),
        source: MarketPriceSource.openPrices,
      ),
    ];

    final coverage = calculatePriceCoverage(
      products,
      prices,
      openPricesMaxAgeDays: 60,
      now: now,
    );

    expect(coverage.products, 2);
    expect(coverage.productsWithEan, 1);
    expect(coverage.manualPrices, 1);
    expect(coverage.openPrices, 1);
    expect(coverage.staleOpenPrices, 1);
  });

  test('Coverage zählt verfügbare Produkte und Quellen je Markt', () {
    final coverage = calculateStorePriceCoverage([
      MarketPrice(
        productId: 'a',
        storeName: 'Lidl',
        price: 1,
        updatedAt: now,
        source: MarketPriceSource.receipt,
      ),
      MarketPrice(
        productId: 'b',
        storeName: 'Lidl',
        price: 2,
        updatedAt: now,
        source: MarketPriceSource.openPrices,
      ),
    ], storeNames: const ['Lidl', 'REWE']);

    expect(coverage.first.storeName, 'Lidl');
    expect(coverage.first.products, 2);
    expect(coverage.first.receiptPrices, 1);
    expect(coverage.first.openPrices, 1);
    expect(coverage.last.storeName, 'REWE');
    expect(coverage.last.products, 0);
  });
}
