import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/services/open_prices_sync_service.dart';

void main() {
  test('Bulk-Sync prüft nur Produkte mit EAN', () async {
    final seen = <String>[];
    final service = OpenPricesSyncService(
      fetcher: (product, maxAgeDays) async {
        seen.add(product.id);
        return [
          MarketPrice(
            productId: product.id,
            storeName: 'Lidl',
            price: 1.99,
            updatedAt: DateTime(2026, 9, 20),
            source: MarketPriceSource.openPrices,
          ),
        ];
      },
    );

    final result = await service.sync(
      products: const [
        Product(
          id: 'ean',
          name: 'Mit EAN',
          unit: '1 Stk',
          group: 'x',
          ean: '123',
        ),
        Product(
          id: 'none',
          name: 'Ohne EAN',
          unit: '1 Stk',
          group: 'x',
        ),
      ],
      maxAgeDays: 30,
    );

    expect(seen, ['ean']);
    expect(result.productsChecked, 2);
    expect(result.productsWithEan, 1);
    expect(result.pricesFound, 1);
  });

  test('Bulk-Sync reicht Alterslimit an Fetcher weiter', () async {
    int? receivedAge;
    final service = OpenPricesSyncService(
      fetcher: (product, maxAgeDays) async {
        receivedAge = maxAgeDays;
        return const [];
      },
    );

    await service.sync(
      products: const [
        Product(
          id: 'ean',
          name: 'Mit EAN',
          unit: '1 Stk',
          group: 'x',
          ean: '123',
        ),
      ],
      maxAgeDays: 90,
    );

    expect(receivedAge, 90);
  });
}
