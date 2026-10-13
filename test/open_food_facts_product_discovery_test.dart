import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/services/open_food_facts_product_discovery.dart';

void main() {
  test('gleicht Produktname und Packungsgröße ab', () async {
    final discovery = OpenFoodFactsProductDiscovery(
      client: MockClient((request) async {
        expect(request.url.queryParameters['search_terms'], 'Milch');
        return http.Response(
          jsonEncode({
            'products': [
              {
                'code': '4006381333931',
                'product_name': 'Milch 1,5 % Fett',
                'brands': 'Beispiel',
                'quantity': '1 l',
              },
            ],
          }),
          200,
        );
      }),
    );

    final result = await discovery.discover(
      const Product(
        id: 'milk',
        name: 'Milch',
        unit: '1 l',
        group: 'milch',
        packageAmount: 1,
        packageUnit: 'l',
      ),
    );

    expect(result?.ean, '4006381333931');
    expect(result?.brand, 'Beispiel');
    discovery.close();
  });

  test('verwirft abweichende Packungsgröße', () async {
    final discovery = OpenFoodFactsProductDiscovery(
      client: MockClient((_) async => http.Response(
            jsonEncode({
              'products': [
                {
                  'code': '4006381333931',
                  'product_name': 'Milch 1,5 % Fett',
                  'quantity': '500 ml',
                },
              ],
            }),
            200,
          )),
    );

    final result = await discovery.discover(
      const Product(
        id: 'milk',
        name: 'Milch',
        unit: '1 l',
        group: 'milch',
        packageAmount: 1,
        packageUnit: 'l',
      ),
    );

    expect(result, isNull);
    discovery.close();
  });

  test('verwirft eine abweichende bekannte Milchvariante', () async {
    final discovery = OpenFoodFactsProductDiscovery(
      client: MockClient((_) async => http.Response(
            jsonEncode({
              'products': [
                {
                  'code': '4006381333931',
                  'product_name': 'Milch 3,5 % Fett',
                  'quantity': '1 l',
                },
              ],
            }),
            200,
          )),
    );

    final result = await discovery.discover(
      const Product(
        id: 'milk-15',
        name: 'Milch 1,5 %',
        unit: '1 l',
        group: 'milch',
        packageAmount: 1,
        packageUnit: 'l',
      ),
    );

    expect(result, isNull);
    discovery.close();
  });

  test('verwirft reine Teilstrings ohne gemeinsame Produktidentität', () async {
    final discovery = OpenFoodFactsProductDiscovery(
      client: MockClient((_) async => http.Response(
            jsonEncode({
              'products': [
                {
                  'code': '4006381333931',
                  'product_name': 'Milchgetränk',
                  'quantity': '1 l',
                },
              ],
            }),
            200,
          )),
    );

    final result = await discovery.discover(
      const Product(
        id: 'milk',
        name: 'Milch',
        unit: '1 l',
        group: 'milch',
        packageAmount: 1,
        packageUnit: 'l',
      ),
    );

    expect(result, isNull);
    discovery.close();
  });

  test('erkennt die Gesamtmenge einer Mehrfachpackung', () async {
    final discovery = OpenFoodFactsProductDiscovery(
      client: MockClient((_) async => http.Response(
            jsonEncode({
              'products': [
                {
                  'code': '4006381333931',
                  'product_name': 'Joghurt Natur',
                  'quantity': '4 x 125 g',
                },
              ],
            }),
            200,
          )),
    );

    final result = await discovery.discover(
      const Product(
        id: 'yogurt-pack',
        name: 'Joghurt Natur',
        unit: '500 g',
        group: 'milch',
        packageAmount: 500,
        packageUnit: 'g',
      ),
    );

    expect(result?.ean, '4006381333931');
    discovery.close();
  });

  test('deaktivierte Discovery erzeugt keinen Request', () async {
    final discovery = OpenFoodFactsProductDiscovery(
      enabled: false,
      client: MockClient((_) async => throw StateError('must not fetch')),
    );

    final result = await discovery.discover(
      const Product(
        id: 'milk',
        name: 'Milch 1,5 %',
        unit: '1 l',
        group: 'milch',
        packageAmount: 1,
        packageUnit: 'l',
      ),
    );

    expect(result, isNull);
    discovery.close();
  });
}
