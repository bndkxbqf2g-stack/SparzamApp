import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/services/open_food_facts_product_discovery.dart';
import 'package:sparzamapp/services/open_prices_sync_service.dart';

void main() {
  test('Live-Open-Prices-Batches bleiben klein und Test-Fetcher seriell', () {
    expect(
      openPricesNetworkBatchSize(live: true, configured: 0),
      1,
    );
    expect(
      openPricesNetworkBatchSize(live: true, configured: 8),
      4,
    );
    expect(
      openPricesNetworkBatchSize(live: false, configured: 4),
      1,
    );
  });

  test('Live-EAN-Discovery bleibt begrenzt parallel und geordnet', () async {
    var inFlight = 0;
    var maximumInFlight = 0;
    var requests = 0;
    final discovery = OpenFoodFactsProductDiscovery(
      client: MockClient((request) async {
        inFlight++;
        requests++;
        if (inFlight > maximumInFlight) {
          maximumInFlight = inFlight;
        }
        final name = request.url.queryParameters['search_terms']!;
        await Future<void>.delayed(const Duration(milliseconds: 5));
        inFlight--;
        final code = switch (name) {
          'Tee Sorte A' => '4000000000001',
          'Tee Sorte B' => '4000000000002',
          'Tee Sorte C' => '4000000000003',
          _ => '4000000000004',
        };
        return http.Response(
          jsonEncode({
            'products': [
              {
                'code': code,
                'product_name': name,
                'quantity': '1 l',
              },
            ],
          }),
          200,
        );
      }),
    );
    final fetched = <String>[];
    final service = OpenPricesSyncService(
      productDiscovery: discovery,
      networkConcurrency: 2,
      fetcher: (product, _) async {
        fetched.add(product.id);
        return const [];
      },
    );

    final result = await service.sync(
      products: const [
        Product(
          id: 'a',
          name: 'Tee Sorte A',
          unit: '1 l',
          group: 'getraenke',
          packageAmount: 1,
          packageUnit: 'l',
        ),
        Product(
          id: 'b',
          name: 'Tee Sorte B',
          unit: '1 l',
          group: 'getraenke',
          packageAmount: 1,
          packageUnit: 'l',
        ),
        Product(
          id: 'c',
          name: 'Tee Sorte C',
          unit: '1 l',
          group: 'getraenke',
          packageAmount: 1,
          packageUnit: 'l',
        ),
        Product(
          id: 'd',
          name: 'Tee Sorte D',
          unit: '1 l',
          group: 'getraenke',
          packageAmount: 1,
          packageUnit: 'l',
        ),
      ],
      maxAgeDays: 30,
    );
    discovery.close();

    expect(requests, 4);
    expect(maximumInFlight, 2);
    expect(fetched, ['a', 'b', 'c', 'd']);
    expect(result.productsWithEan, 4);
    expect(result.productsProcessed, 4);
    expect(result.cancelled, isFalse);
  });

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

  test('Abbruch bewahrt bereits abgefragte Preise und meldet Fortschritt',
      () async {
    final seen = <String>[];
    final progress = <String>[];
    var cancel = false;
    final service = OpenPricesSyncService(
      fetcher: (product, _) async {
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
        Product(id: 'one', name: 'Eins', unit: 'Stk', group: 'x', ean: '1'),
        Product(id: 'two', name: 'Zwei', unit: 'Stk', group: 'x', ean: '2'),
      ],
      maxAgeDays: 30,
      onProgress: (processed, total) {
        progress.add('$processed/$total');
        cancel = true;
      },
      shouldCancel: () => cancel,
    );

    expect(seen, ['one']);
    expect(progress, ['1/2']);
    expect(result.productsProcessed, 1);
    expect(result.cancelled, isTrue);
    expect(result.prices.single.productId, 'one');
  });

  test('Fehler eines Produkts blockiert folgende Produkte nicht', () async {
    final service = OpenPricesSyncService(
      fetcher: (product, _) async {
        if (product.id == 'bad') throw Exception('timeout');
        return [
          MarketPrice(
            productId: product.id,
            storeName: 'Lidl',
            price: 1.2,
            updatedAt: DateTime(2026, 9, 20),
          ),
        ];
      },
    );
    final result = await service.sync(
      products: const [
        Product(id: 'bad', name: 'Fehler', unit: 'Stk', group: 'x', ean: '1'),
        Product(id: 'good', name: 'Gut', unit: 'Stk', group: 'x', ean: '2'),
      ],
      maxAgeDays: 30,
    );

    expect(result.productsProcessed, 2);
    expect(result.cancelled, isFalse);
    expect(result.failedProductIds, ['bad']);
    expect(result.prices.single.productId, 'good');
  });
  test('fehlende EAN kann konservativ vor dem Preisabruf entdeckt werden', () async {
    final seen = <Product>[];
    final service = OpenPricesSyncService(
      discoverer: (product) async => product.copyWith(ean: '4000000000001'),
      fetcher: (product, _) async {
        seen.add(product);
        return [
          MarketPrice(
            productId: product.id,
            storeName: 'Lidl',
            price: 0.79,
            updatedAt: DateTime(2026, 9, 24),
            source: MarketPriceSource.openPrices,
          ),
        ];
      },
    );

    final result = await service.sync(
      products: const [
        Product(
          id: 'schmand',
          name: 'Schmand',
          unit: '200 g',
          group: 'milchprodukte',
          packageAmount: 200,
          packageUnit: 'g',
        ),
      ],
      maxAgeDays: 30,
    );

    expect(seen.single.ean, '4000000000001');
    expect(seen.single.id, 'schmand');
    expect(result.productsWithEan, 1);
    expect(result.pricesFound, 0);
    expect(result.prices, isEmpty);
  });

  test('nicht sicher entdecktes Produkt bleibt aus der Preisroute', () async {
    var priceFetches = 0;
    final service = OpenPricesSyncService(
      discoverer: (_) async => null,
      fetcher: (_, _) async {
        priceFetches++;
        return const [];
      },
    );

    final result = await service.sync(
      products: const [
        Product(
          id: 'kaese',
          name: 'Käse',
          unit: '200 g',
          group: 'milchprodukte',
          packageAmount: 200,
          packageUnit: 'g',
        ),
      ],
      maxAgeDays: 30,
    );

    expect(priceFetches, 0);
    expect(result.productsWithEan, 0);
    expect(result.pricesFound, 0);
  });

  test('Doppelte Produkt-IDs werden nur einmal abgefragt', () async {
    final seen = <String>[];
    final service = OpenPricesSyncService(
      fetcher: (product, _) async {
        seen.add(product.id);
        return const [];
      },
    );

    final result = await service.sync(
      products: const [
        Product(id: 'same', name: 'Basis', unit: 'Stk', group: 'x', ean: '1'),
        Product(id: 'same', name: 'Duplikat', unit: 'Stk', group: 'x', ean: '2'),
      ],
      maxAgeDays: 30,
    );

    expect(seen, ['same']);
    expect(result.productsWithEan, 1);
    expect(result.productsProcessed, 1);
    expect(result.cancelled, isFalse);
  });

  test('Abbruch stoppt die Barcode-Ermittlung vor dem nächsten Produkt', () async {
    final discovered = <String>[];
    var checks = 0;
    final service = OpenPricesSyncService(
      discoverer: (product) async {
        discovered.add(product.id);
        return product.copyWith(ean: '4000000000001');
      },
      fetcher: (_, _) async => const [],
    );

    final result = await service.sync(
      products: const [
        Product(id: 'one', name: 'Eins', unit: 'Stk', group: 'x'),
        Product(id: 'two', name: 'Zwei', unit: 'Stk', group: 'x'),
      ],
      maxAgeDays: 30,
      shouldCancel: () => ++checks > 1,
    );

    expect(discovered, ['one']);
    expect(result.productsWithEan, 1);
    expect(result.productsProcessed, 0);
    expect(result.cancelled, isTrue);
  });

}
