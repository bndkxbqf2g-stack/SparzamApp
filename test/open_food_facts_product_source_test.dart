import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/services/open_food_facts_product_source.dart';
import 'package:sparzamapp/services/product_data_cache.dart';
import 'package:sparzamapp/services/product_data_source.dart';

class MemoryProductCache implements ProductDataCache {
  final values = <String, Product>{};

  @override
  Future<Product?> load(String ean) async => values[ean];

  @override
  Future<void> save(Product product) async {
    values[product.ean!] = product;
  }
}

void main() {
  test('Open Food Facts source caches metadata for offline reuse', () async {
    final cache = MemoryProductCache();
    var requests = 0;
    final first = OpenFoodFactsProductSource(
      cache: cache,
      client: MockClient((_) async {
        requests++;
        return http.Response(
          jsonEncode({
            'status': 1,
            'product': {
              'code': '123',
              'product_name': 'Milch 1,5 %',
              'quantity': '1 l',
              'brands': 'Beispiel',
            },
          }),
          200,
        );
      }),
    );

    final loaded = await first.fetchProductByEan('123');
    first.close();

    final offline = OpenFoodFactsProductSource(
      cache: cache,
      client: MockClient((_) async {
        requests++;
        throw http.ClientException('offline');
      }),
    );
    final cached = await offline.fetchProductByEan('123');
    offline.close();

    expect(requests, 2);
    expect(loaded?.name, 'Milch 1,5 %');
    expect(cached?.packageAmount, 1);
    expect(cached?.packageUnit, 'l');
  });

  test('deaktivierte Produktquelle erzeugt keinen Request', () async {
    var requests = 0;
    final source = OpenFoodFactsProductSource(
      enabled: false,
      client: MockClient((_) async {
        requests++;
        return http.Response('{}', 200);
      }),
    );

    expect(await source.fetchProductByEan('123'), isNull);
    source.close();
    expect(requests, 0);
  });

  test('source contract remains explicit', () {
    final source = OpenFoodFactsProductSource(enabled: false);
    expect(source, isA<ProductDataSource>());
    source.close();
  });

  test('canonicalizes UPC-A before the Open Food Facts request', () async {
    late http.Request request;
    final source = OpenFoodFactsProductSource(
      client: MockClient((captured) async {
        request = captured;
        return http.Response(
          jsonEncode({
            'status': 1,
            'product': {
              'code': '0123456789012',
              'product_name': 'Beispielprodukt',
            },
          }),
          200,
        );
      }),
    );

    final product = await source.fetchProductByEan('123456789012');
    source.close();

    expect(request.url.path, '/api/v2/product/0123456789012.json');
    expect(product?.ean, '0123456789012');
  });

  test('normalizes structured centiliter quantities to milliliters', () async {
    final source = OpenFoodFactsProductSource(
      client: MockClient((_) async {
        return http.Response(
          jsonEncode({
            'status': 1,
            'product': {
              'code': '456',
              'product_name': 'Sahne',
              'product_quantity': 20,
              'product_quantity_unit': 'cl',
            },
          }),
          200,
        );
      }),
    );

    final product = await source.fetchProductByEan('456');
    source.close();

    expect(product?.packageAmount, 200);
    expect(product?.packageUnit, 'ml');
    expect(product?.unit, '200 ml');
  });
}
