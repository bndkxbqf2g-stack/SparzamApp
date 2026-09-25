import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/services/open_food_facts_service.dart';

void main() {
  test('Produktdaten werden über EAN angereichert', () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        '''
        {
          "status": 1,
          "product": {
            "code": "1234567890123",
            "product_name": "Espresso Bohnen",
            "brands": "Rösterei",
            "product_quantity": 500,
            "product_quantity_unit": "g",
            "quantity": "500 g",
            "categories": "Kaffee, Getränke",
            "image_front_small_url": "https://images.example/coffee.jpg"
          }
        }
        ''',
        200,
      );
    });

    final service = OpenFoodFactsService(client: client);
    final product = await service.fetchProductByEan('1234567890123');

    expect(captured.url.host, 'world.openfoodfacts.org');
    expect(captured.url.path, '/api/v2/product/1234567890123.json');
    expect(captured.headers['User-Agent'], contains('SparzamApp'));
    expect(product, isNotNull);
    expect(product!.name, 'Espresso Bohnen');
    expect(product.brand, 'Rösterei');
    expect(product.packageAmount, 500);
    expect(product.packageUnit, 'g');
    expect(product.group, 'kaffee');
    expect(product.imageUrl, 'https://images.example/coffee.jpg');

    service.close();
  });

  test('Multipack wird zur Gesamtmenge normalisiert', () async {
    final client = MockClient(
      (_) async => http.Response(
        '''
        {
          "status": 1,
          "product": {
            "product_name": "Wasser",
            "quantity": "6 x 250 ml"
          }
        }
        ''',
        200,
      ),
    );

    final service = OpenFoodFactsService(client: client);
    final product = await service.fetchProductByEan('999');

    expect(product, isNotNull);
    expect(product!.packageAmount, 1500);
    expect(product.packageUnit, 'ml');
    expect(product.unit, '1500 ml');

    service.close();
  });

  test('bestehende lokale Metadaten bleiben erhalten wenn API-Feld fehlt', () async {
    final client = MockClient(
      (_) async => http.Response(
        '''
        {
          "status": 1,
          "product": {
            "product_name": "Neuer Name"
          }
        }
        ''',
        200,
      ),
    );

    const existing = Product(
      id: 'custom',
      name: 'Alt',
      unit: '500 g',
      group: 'kaffee',
      ean: '123',
      brand: 'Lokale Marke',
      packageAmount: 500,
      packageUnit: 'g',
      imageUrl: 'https://local/image.jpg',
    );

    final service = OpenFoodFactsService(client: client);
    final product = await service.fetchProductByEan(
      '123',
      existing: existing,
    );

    expect(product!.id, 'custom');
    expect(product.name, 'Neuer Name');
    expect(product.brand, 'Lokale Marke');
    expect(product.packageAmount, 500);
    expect(product.imageUrl, 'https://local/image.jpg');

    service.close();
  });

  test('nicht gefundenes Produkt liefert null', () async {
    final client = MockClient(
      (_) async => http.Response('{"status":0}', 200),
    );
    final service = OpenFoodFactsService(client: client);

    expect(await service.fetchProductByEan('404'), isNull);

    service.close();
  });

  test('abweichender Produktcode aus API wird nicht übernommen', () async {
    final client = MockClient(
      (_) async => http.Response(
        '{"status":1,"code":"222","product":'
        '{"code":"222","product_name":"Falsches Produkt"}}',
        200,
      ),
    );
    final service = OpenFoodFactsService(client: client);

    expect(await service.fetchProductByEan('111'), isNull);

    service.close();
  });

  test('abweichender verschachtelter Code wird ebenfalls abgelehnt', () async {
    final client = MockClient(
      (_) async => http.Response(
        '{"status":1,"code":"111","product":'
        '{"code":"222","product_name":"Falsches Produkt"}}',
        200,
      ),
    );
    final service = OpenFoodFactsService(client: client);

    expect(await service.fetchProductByEan('111'), isNull);

    service.close();
  });
}
