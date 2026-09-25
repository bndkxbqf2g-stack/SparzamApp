import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/catalog/market_price_import.dart';
import 'package:sparzamapp/models/market_price.dart';

void main() {
  final first = MarketPrice(
    productId: 'milk',
    storeName: 'Lidl',
    price: 1.29,
    updatedAt: DateTime(2026, 9, 1),
  );
  final second = MarketPrice(
    productId: 'milk',
    storeName: 'EDEKA',
    price: 1.39,
    updatedAt: DateTime(2026, 9, 2),
  );
  final third = MarketPrice(
    productId: 'milk',
    storeName: 'PENNY',
    price: 1.19,
    updatedAt: DateTime(2026, 9, 3),
  );

  test('bewahrt Teilerfolge und versucht weitere Preise nach Speicherfehler',
      () async {
    final attempts = <String>[];
    final result = await importMarketPrices(
      found: [first, second, third],
      current: const [],
      onSave: (price) async {
        attempts.add(price.storeName);
        if (price.storeName == second.storeName) {
          throw StateError('storage failed');
        }
        return [price, if (price.storeName == third.storeName) first];
      },
    );

    expect(attempts, ['Lidl', 'EDEKA', 'PENNY']);
    expect(result.processed, 2);
    expect(result.failed, 1);
    expect(result.prices.map((price) => price.storeName), ['PENNY', 'Lidl']);
  });

  test('ohne Treffer bleibt die bestehende Liste erhalten', () async {
    final current = [first];
    final result = await importMarketPrices(
      found: const [],
      current: current,
      onSave: (_) async => throw StateError('must not be called'),
    );
    expect(identical(result.prices, current), isTrue);
    expect(result.processed, 0);
    expect(result.failed, 0);
  });
}
