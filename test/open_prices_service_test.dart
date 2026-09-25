import 'dart:convert';

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
              "price_per": "UNIT",
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
              "price_per": "UNIT",
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
              "product_code": "1234567890123",
              "currency": "EUR",
              "price_is_discounted": false,
              "price_per": "UNIT",
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

  test('ähnliche Namen werden nicht als konfigurierter Markt importiert', () async {
    final client = MockClient((_) async => http.Response(
      jsonEncode({
        'items': [
          {
            'id': 14,
            'product_code': '1234567890123',
            'currency': 'EUR',
            'price_is_discounted': false,
            'price_per': 'UNIT',
            'price': 3.99,
            'date': '2026-09-20',
            'location': {
              'osm_brand': 'Lidl-Museum',
              'osm_name': 'Lidl-Museum',
              'osm_address_city': 'Zellingen',
            },
          },
        ],
      }), 200));
    final service = OpenPricesService(client: client);

    final result = await service.fetchRecentPrices(
      product: product,
      stores: stores,
      now: DateTime(2026, 9, 22),
    );

    expect(result, isEmpty);
    service.close();
  });

  test('gleiche Kette in anderer Stadt wird nicht als lokaler Preis genutzt',
      () async {
    final service = OpenPricesService(
      client: MockClient((_) async => http.Response('''
        {"items":[
          {"id":1,"price":1.19,"date":"2026-09-20",
           "product_code":"1234567890123","currency":"EUR",
           "price_is_discounted":false,"price_per":"UNIT",
           "location":{"osm_brand":"Lidl","osm_name":"Lidl",
                       "osm_address_city":"München"}},
          {"id":2,"price":1.49,"date":"2026-09-20",
           "product_code":"1234567890123","currency":"EUR",
           "price_is_discounted":false,"price_per":"UNIT",
           "location":{"osm_brand":"Lidl","osm_name":"Lidl"}},
          {"id":3,"price":1.59,"date":"2026-09-20",
           "product_code":"1234567890123","currency":"EUR",
           "price_is_discounted":false,"price_per":"UNIT",
           "location":{"osm_brand":"Lidl","osm_name":"Lidl",
                       "osm_address_city":"Zellingen"}}
        ]}''', 200)),
    );

    final prices = await service.fetchRecentPrices(
      product: product,
      stores: stores,
      now: DateTime(2026, 9, 22),
    );

    expect(prices, hasLength(1));
    expect(prices.single.price, 1.59);
    expect(prices.single.sourceLocationName, 'Lidl · Zellingen');
    service.close();
  });

  test('abweichende Postleitzahl schließt gleiche Stadt und Kette aus',
      () async {
    final service = OpenPricesService(
      client: MockClient((_) async => http.Response('''
        {"items":[
          {"id":1,"price":1.19,"date":"2026-09-20",
           "product_code":"1234567890123","currency":"EUR",
           "price_is_discounted":false,"price_per":"UNIT",
           "location":{"osm_brand":"Lidl","osm_name":"Lidl",
                       "osm_address_city":"Zellingen",
                       "osm_address_postcode":"99999"}}
        ]}''', 200)),
    );
    const local = Store(
      name: 'Lidl',
      location: 'Zellingen',
      address: 'Am Güßgraben 2, 97225 Zellingen, Germany',
      distanceKm: 1,
      prices: {},
    );

    final prices = await service.fetchRecentPrices(
      product: product,
      stores: const [local],
      now: DateTime(2026, 9, 22),
    );
    expect(prices, isEmpty);
    service.close();
  });

  test('jüngster Preis gewinnt auch bei ungeordneter Antwort', () async {
    final service = OpenPricesService(
      client: MockClient((_) async => http.Response('''
        {"items":[
          {"id":1,"price":2.5,"date":"2026-09-19",
           "product_code":"1234567890123","currency":"EUR",
           "price_is_discounted":false,"price_per":"UNIT",
           "location":{"osm_brand":"Lidl","osm_name":"Lidl",
                       "osm_address_city":"Zellingen"}},
          {"id":2,"price":1.9,"date":"2026-09-21",
           "product_code":"1234567890123","currency":"EUR",
           "price_is_discounted":false,"price_per":"UNIT",
           "location":{"osm_brand":"Lidl","osm_name":"Lidl",
                       "osm_address_city":"Zellingen"}}
        ]}''', 200)),
    );

    final prices = await service.fetchRecentPrices(
      product: product,
      stores: stores,
      now: DateTime(2026, 9, 22),
    );

    expect(prices.single.price, 1.9);
    expect(prices.single.externalId, 2);
    service.close();
  });

  test('fremde, rabattierte und veraltete Preise werden nicht importiert',
      () async {
    final valid = <String, dynamic>{
      'id': 10,
      'type': 'PRODUCT',
      'product_code': product.ean,
      'price': 2.49,
      'currency': 'EUR',
      'price_is_discounted': false,
      'price_per': 'UNIT',
      'date': '2026-09-20',
      'location': {
        'osm_brand': 'Lidl',
        'osm_name': 'Lidl',
        'osm_address_city': 'Zellingen',
      },
    };
    final service = OpenPricesService(
      maxAge: const Duration(days: 30),
      client: MockClient((_) async => http.Response(jsonEncode({
            'items': [
              {...valid, 'product_code': 'another-ean'},
              {...valid, 'currency': 'USD'},
              {...valid, 'price_is_discounted': true},
              {...valid, 'price_per': 'KILOGRAM'},
              {...valid, 'duplicate_of': 12},
              {...valid, 'type': 'CATEGORY'},
              {...valid, 'date': '2026-07-01'},
              {...valid, 'date': '2026-09-23'},
              valid,
            ],
          }), 200)),
    );

    final prices = await service.fetchRecentPrices(
      product: product,
      stores: stores,
      now: DateTime(2026, 9, 22),
    );

    expect(prices, hasLength(1));
    expect(prices.single.price, 2.49);
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
