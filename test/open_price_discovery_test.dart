import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sparzamapp/services/open_price_discovery.dart';

void main() {
  test('requests productless category leads and retains provenance', () async {
    final client = MockClient((request) async {
      expect(request.url.queryParameters['category_tag'], 'en:breads');
      expect(request.url.queryParameters['product_code__isnull'], 'true');
      expect(request.url.queryParameters['currency'], 'EUR');
      return http.Response(jsonEncode({
        'pages': 1,
        'items': [{
          'id': 12, 'type': 'CATEGORY', 'product_code': null,
          'category_tag': 'en:breads', 'price': 2.49, 'currency': 'EUR',
          'date': '2026-09-01', 'price_is_discounted': true,
          'price_per': 'KILOGRAM', 'location_id': 44,
          'location': {'osm_name': 'Example Store'}
        }]
      }), 200);
    });
    final leads = await OpenPriceDiscovery(client: client).search(
      categoryTag: 'en:breads', withoutProductCode: true,
    );
    expect(leads, hasLength(1));
    expect(leads.single.isProductLead, isFalse);
    expect(leads.single.isDiscounted, isTrue);
    expect(leads.single.pricePer, 'KILOGRAM');
    expect(leads.single.locationId, 44);
  });

  test('paginates within bound and preserves barcode and location', () async {
    var requests = 0;
    final client = MockClient((request) async {
      requests++;
      expect(request.url.queryParameters['product_code'], '12345678');
      expect(request.url.queryParameters['location_id'], '7');
      return http.Response(jsonEncode({
        'pages': 9,
        'items': [{
          'id': requests, 'type': 'PRODUCT',
          'product_code': '12345678', 'price': 1.15,
          'currency': 'EUR', 'date': '2026-09-01',
          'location_id': 7, 'price_is_discounted': false,
          'price_per': 'UNIT'
        }]
      }), 200);
    });
    final leads = await OpenPriceDiscovery(client: client).search(
      productCode: '12345678', locationId: 7, maxPages: 2,
    );
    expect(requests, 2);
    expect(leads, hasLength(2));
    expect(leads.every((lead) => lead.isProductLead), isTrue);
  });

  test('requires a bounded targeted query', () async {
    final discovery = OpenPriceDiscovery(
        client: MockClient((request) async => http.Response('{}', 200)));
    await expectLater(discovery.search(), throwsArgumentError);
    await expectLater(
        discovery.search(categoryTag: 'en:breads', maxPages: 4),
        throwsArgumentError);
  });
}
