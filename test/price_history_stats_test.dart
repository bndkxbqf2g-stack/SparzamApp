import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/offers/price_history_stats.dart';
import 'package:sparzamapp/models/price_point.dart';

void main() {
  final now = DateTime(2026, 9, 22);

  PricePoint point(int daysAgo, double price) => PricePoint(
        productId: 'milk',
        storeName: 'Lidl',
        price: price,
        date: now.subtract(Duration(days: daysAgo)),
      );

  test('30 und 90 Tage Bestpreis werden getrennt berechnet', () {
    final stats = priceHistoryStats(
      [
        point(10, 1.19),
        point(40, 0.99),
        point(70, 1.29),
        point(120, 0.79),
      ],
      productId: 'milk',
      storeName: 'Lidl',
      now: now,
    );

    expect(stats.best30, 1.19);
    expect(stats.best90, 0.99);
    expect(stats.normal90, 1.19);
    expect(stats.samples, 4);
    expect(stats.samples30, 1);
    expect(stats.samples90, 3);
  });

  test('fremde Märkte und zukünftige Werte werden ignoriert', () {
    final stats = priceHistoryStats(
      [
        point(5, 1.19),
        PricePoint(
          productId: 'milk',
          storeName: 'EDEKA',
          price: 0.50,
          date: now,
        ),
        PricePoint(
          productId: 'milk',
          storeName: 'Lidl',
          price: 0.40,
          date: now.add(const Duration(days: 1)),
        ),
      ],
      productId: 'milk',
      storeName: 'Lidl',
      now: now,
    );

    expect(stats.best30, 1.19);
    expect(stats.samples, 1);
  });

  test('Kalendertag an der 30-Tage-Grenze wird vollständig berücksichtigt', () {
    final reference = DateTime(2026, 9, 22, 18, 30);
    final stats = priceHistoryStats(
      [
        PricePoint(
          productId: 'milk',
          storeName: 'Lidl',
          price: 1.09,
          date: DateTime(2026, 8, 23, 8),
        ),
      ],
      productId: 'milk',
      storeName: 'Lidl',
      now: reference,
    );

    expect(stats.best30, 1.09);
    expect(stats.samples30, 1);
  });
}
