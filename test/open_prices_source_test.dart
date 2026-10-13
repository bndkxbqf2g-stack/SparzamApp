import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/store.dart';
import 'package:sparzamapp/services/open_prices_cache.dart';
import 'package:sparzamapp/services/open_prices_service.dart';
import 'package:sparzamapp/services/price_source.dart';

class MemoryOpenPricesCache implements OpenPricesCache {
  String? body;

  @override
  Future<String?> load(String productCode) async => body;

  @override
  Future<void> save(String productCode, String responseBody) async {
    body = responseBody;
  }
}

const product = Product(
  id: 'coffee',
  name: 'Kaffee',
  unit: '500 g',
  group: 'kaffee',
  ean: '1234567890123',
  packageAmount: 500,
  packageUnit: 'g',
);

const store = Store(
  name: 'Lidl',
  location: 'Zellingen',
  address: 'Filiale, 97225 Zellingen',
  branchId: '42',
  distanceKm: 1,
  prices: {},
);

Map<String, dynamic> payload({String date = '2026-09-20'}) => {
      'items': [
        {
          'id': 11,
          'product_code': product.ean,
          'price': 4.49,
          'currency': 'EUR',
          'price_is_discounted': false,
          'price_per': 'UNIT',
          'date': date,
          'location': {
            'id': 42,
            'osm_brand': 'Lidl',
            'osm_name': 'Lidl',
            'osm_address_city': 'Zellingen',
          },
        },
      ],
    };

void main() {
  test('source keeps exact location IDs and implements PriceSource', () async {
    final source = OpenPricesSource(
      client: MockClient((_) async => http.Response(
        jsonEncode(payload()),
        200,
      )),
    );

    final prices = await source.fetchRecentPrices(
      product: product,
      stores: const [store],
      now: DateTime(2026, 9, 22),
    );
    source.close();

    expect(source, isA<PriceSource>());
    expect(prices.single.sourceLocationId, '42');
    expect(prices.single.sourceLocationName, 'Lidl · Zellingen');
    expect(prices.single.quantity, 500);
    expect(prices.single.unit, 'g');
    expect(prices.single.unitPrice, closeTo(8.98, 0.00001));
  });

  test('configured branch ID cannot override a conflicting city', () async {
    final source = OpenPricesSource(
      client: MockClient((_) async => http.Response(
        jsonEncode({
          'items': [
            {
              'id': 12,
              'product_code': product.ean,
              'price': 4.49,
              'currency': 'EUR',
              'price_is_discounted': false,
              'price_per': 'UNIT',
              'date': '2026-09-20',
              'location': {
                'id': 42,
                'osm_brand': 'Lidl',
                'osm_name': 'Lidl',
                'osm_address_city': 'München',
              },
            },
          ],
        }),
        200,
      )),
    );

    final prices = await source.fetchRecentPrices(
      product: product,
      stores: const [store],
      now: DateTime(2026, 9, 22),
    );
    source.close();

    expect(prices, isEmpty);
  });

  test('configured branch ID cannot override a conflicting retailer label',
      () async {
    const aldi = Store(
      name: 'ALDI Süd',
      location: 'Zellingen',
      address: 'Filiale, 97225 Zellingen',
      branchId: '7',
      distanceKm: 2,
      prices: {},
    );
    final source = OpenPricesSource(
      client: MockClient((_) async => http.Response(
        jsonEncode({
          'items': [
            {
              'id': 13,
              'product_code': product.ean,
              'price': 4.49,
              'currency': 'EUR',
              'price_is_discounted': false,
              'price_per': 'UNIT',
              'date': '2026-09-20',
              'location': {
                'id': 42,
                'osm_brand': 'ALDI Süd',
                'osm_name': 'ALDI Süd',
                'osm_address_city': 'Zellingen',
              },
            },
          ],
        }),
        200,
      )),
    );

    final prices = await source.fetchRecentPrices(
      product: product,
      stores: const [store, aldi],
      now: DateTime(2026, 9, 22),
    );
    source.close();

    expect(prices, isEmpty);
  });

  test('cache is used on provider failure and stale result stays non-routeable',
      () async {
    final cache = MemoryOpenPricesCache();
    final live = OpenPricesSource(
      cache: cache,
      client: MockClient((_) async => http.Response(
        jsonEncode(payload()),
        200,
      )),
    );
    await live.fetchRecentPrices(
      product: product,
      stores: const [store],
      now: DateTime(2026, 9, 22),
    );
    live.close();

    final offline = OpenPricesSource(
      cache: cache,
      client: MockClient((_) async {
        throw http.ClientException('offline');
      }),
    );
    final prices = await offline.fetchRecentPrices(
      product: product,
      stores: const [store],
      now: DateTime(2026, 12, 1),
    );
    offline.close();

    expect(prices, hasLength(1));
    expect(
      prices.single.isUsable(
        now: DateTime(2026, 12, 1),
        openPricesMaxAgeDays: 60,
      ),
      isFalse,
    );
  });

  test('deaktivierte Preisquelle erzeugt keinen Request', () async {
    var requests = 0;
    final source = OpenPricesSource(
      enabled: false,
      client: MockClient((_) async {
        requests++;
        return http.Response('{}', 200);
      }),
    );

    expect(
      await source.fetchRecentPrices(
        product: product,
        stores: const [store],
      ),
      isEmpty,
    );
    source.close();
    expect(requests, 0);
  });
}
