import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/catalog/market_price_freshness.dart';
import 'package:sparzamapp/features/catalog/price_coverage.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/price_observation.dart';
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
    ], storeNames: const ['Lidl', 'Netto']);

    expect(coverage.first.storeName, 'Lidl');
    expect(coverage.first.products, 2);
    expect(coverage.first.receiptPrices, 1);
    expect(coverage.first.openPrices, 1);
    expect(coverage.last.storeName, 'Netto');
    expect(coverage.last.products, 0);
  });

  test('Coverage ignoriert Preise für eine abweichende Packungsgröße', () {
    const products = [
      Product(
        id: 'coffee',
        name: 'Kaffee',
        unit: '500 g',
        group: 'Kaffee',
      ),
    ];
    final prices = [
      MarketPrice(
        productId: 'coffee',
        storeName: 'Lidl',
        price: 8.99,
        updatedAt: now,
        source: MarketPriceSource.openPrices,
        quantity: 1,
        unit: 'kg',
      ),
      MarketPrice(
        productId: 'coffee',
        storeName: 'Lidl',
        price: 4.99,
        updatedAt: now,
        source: MarketPriceSource.receipt,
        quantity: 500,
        unit: 'g',
      ),
    ];

    final coverage = calculatePriceCoverage(
      products,
      prices,
      openPricesMaxAgeDays: 60,
      now: now,
    );
    final storeCoverage = calculateStorePriceCoverage(
      prices,
      products: products,
    );

    expect(coverage.openPrices, 0);
    expect(coverage.manualPrices, 1);
    expect(coverage.incompatiblePrices, 1);
    expect(storeCoverage.single.products, 1);
    expect(storeCoverage.single.openPrices, 0);
    expect(storeCoverage.single.receiptPrices, 1);
    expect(storeCoverage.single.incompatiblePrices, 1);
  });
  test('older receipts are historical and excluded from current prices', () {
    final receipt = MarketPrice(
      productId: 'bread',
      storeName: 'Netto',
      price: 1.19,
      updatedAt: DateTime(2026, 5, 26),
      source: MarketPriceSource.receipt,
    );
    expect(receipt.isUsable(now: now, openPricesMaxAgeDays: 60), isFalse);
    expect(receipt.freshnessLabel(now: now, openPricesMaxAgeDays: 60),
        'historischer Bonpreis');
  });

  test('future external observations are not usable before their date', () {
    final futureReceipt = MarketPrice(
      productId: 'bread',
      storeName: 'Netto',
      price: 1.19,
      updatedAt: DateTime(2026, 9, 23),
      source: MarketPriceSource.receipt,
    );
    final futureOpenPrice = MarketPrice(
      productId: 'milk',
      storeName: 'Lidl',
      price: 0.89,
      updatedAt: DateTime(2026, 9, 23),
      source: MarketPriceSource.openPrices,
    );

    expect(
      futureReceipt.isUsable(now: now, openPricesMaxAgeDays: 60),
      isFalse,
    );
    expect(
      futureOpenPrice.isUsable(now: now, openPricesMaxAgeDays: 60),
      isFalse,
    );
  });

  test('future manual prices are not usable before their date', () {
    final futureManual = MarketPrice(
      productId: 'butter',
      storeName: 'Lidl',
      price: 1.99,
      updatedAt: DateTime(2026, 9, 23),
    );

    expect(
      futureManual.isUsable(now: now, openPricesMaxAgeDays: 60),
      isFalse,
    );
  });

  test('usable market prices exclude direct prospect offers', () {
    final usable = usableMarketPrices(
      [
        MarketPrice(
          productId: 'milk',
          storeName: 'Lidl',
          price: 0.79,
          updatedAt: now,
          source: MarketPriceSource.prospect,
          kind: PriceObservationKind.offer,
          discounted: true,
        ),
        MarketPrice(
          productId: 'milk',
          storeName: 'Lidl',
          price: 1.29,
          updatedAt: now,
          source: MarketPriceSource.prospect,
          kind: PriceObservationKind.regular,
        ),
      ],
      openPricesMaxAgeDays: 60,
      now: now,
    );

    expect(usable, hasLength(1));
    expect(usable.single.price, 1.29);
    expect(usable.single.kind, PriceObservationKind.regular);
  });

}
