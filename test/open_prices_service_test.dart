import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/store.dart';
import 'package:sparzamapp/services/open_prices_service.dart';

void main() {
  const product = Product(
    id: 'coffee',
    name: 'Kaffee',
    unit: '500 g',
    group: 'kaffee',
    ean: '1234567890123',
  );

  const stores = [
    Store(
      name: 'Lidl',
      location: 'Zellingen',
      distanceKm: 1,
      prices: {},
    ),
    Store(
      name: 'ALDI Süd',
      location: 'Zellingen',
      distanceKm: 2,
      prices: {},
    ),
  ];

  test('Open Prices filtert EAN, EUR und aktuelle Normalpreise', () async {
    late Uri requested;
    final client = MockClient((request) async {
      requested = request.url;
      return http.Response(
        '''
        {
          "items": [
            {
              "id": 11,
              "product_code": "1234567890123",
              "price": 4.49,
              "currency": "EUR",
              "price_is_discounted": false,
              "date": "2026-09-20",
              "location": {
                "osm_brand": "Lidl",
                "osm_name": "Lidl",
                "osm_address_city": "Zellingen"
              }
            },
            {
              "id": 12,
              "product_code": "1234567890123",
              "price": 4.79,
              "currency": "EUR",
              "price_is_discounted": false,
              "date": "2026-09-19",
              "location": {
                "osm_brand": "ALDI Süd",
                "osm_name": "ALDI Süd",
                "osm_address_city": "Zellingen"
              }
            }
          ],
          "page": 1,
          "pages": 1,
          "size": 100,
          "total": 2
        }
        ''',
        200,
      );
    });

    final service = OpenPricesService(client: client);
    final result = await service.fetchRecentPrices(
      product: product,
      stores: stores,
      now: DateTime(2026, 9, 22),
    );

    expect(requested.host, 'prices.openfoodfacts.org');
    expect(requested.path, '/api/v1/prices');
    expect(requested.queryParameters['product_code'], product.ean);
    expect(requested.queryParameters['currency'], 'EUR');
    expect(requested.queryParameters['price_is_discounted'], 'false');
    expect(requested.queryParameters['order_by'], '-date');
    expect(requested.queryParameters['date__gte'], '2026-07-24');

    expect(result, hasLength(2));
    expect(result.first.storeName, 'Lidl');
    expect(result.first.price, 4.49);
    expect(result.first.source.name, 'openPrices');
    expect(result.first.sourceLocationName, 'Lidl · Zellingen');
    expect(result.last.storeName, 'ALDI Süd');

    service.close();
  });

  test('Produkt ohne EAN löst keinen Request aus', () async {
    var called = false;
    final client = MockClient((request) async {
      called = true;
      return http.Response('{}', 200);
    });
    final service = OpenPricesService(client: client);

    final result = await service.fetchRecentPrices(
      product: const Product(
        id: 'x',
        name: 'Ohne Barcode',
        unit: '1 Stk',
        group: 'custom',
      ),
      stores: stores,
    );

    expect(result, isEmpty);
    expect(called, isFalse);
    service.close();
  });

  test('unbekannte Märkte werden nicht importiert', () async {
    final client = MockClient(
      (_) async => http.Response(
        '''
        {
          "items": [
            {
              "id": 13,
              "price": 3.99,
              "date": "2026-09-20",
              "location": {
                "osm_brand": "Unbekannter Markt",
                "osm_name": "Unbekannter Markt"
              }
            }
          ]
        }
        ''',
        200,
      ),
    );
    final service = OpenPricesService(client: client);

    final result = await service.fetchRecentPrices(
      product: product,
      stores: stores,
      now: DateTime(2026, 9, 22),
    );

    expect(result, isEmpty);
    service.close();
  });

  test('Serverfehler wird als Abruffehler gemeldet', () async {
    final service = OpenPricesService(
      client: MockClient((_) async => http.Response('{}', 503)),
    );
    await expectLater(
      service.fetchRecentPrices(product: product, stores: stores),
      throwsA(isA<http.ClientException>()),
    );
    service.close();
  });
}
