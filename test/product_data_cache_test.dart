import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/services/product_data_cache.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  test('cache canonicalizes separators and UPC-A keys', () async {
    final cache = SharedPreferencesProductDataCache();
    const product = Product(
      id: 'cached_upc',
      name: 'UPC-Produkt',
      unit: '1 Stück',
      group: 'vorrat',
      ean: '123-456789012',
    );

    await cache.save(product);
    final loaded = await cache.load('0123456789012');

    expect(loaded?.ean, '0123456789012');
    expect(loaded?.name, 'UPC-Produkt');
  });

  test('cache rejects an invalid barcode instead of creating an identity', () async {
    final cache = SharedPreferencesProductDataCache();
    const product = Product(
      id: 'invalid',
      name: 'Ungültig',
      unit: '1 Stück',
      group: 'vorrat',
      ean: 'EAN-ABC',
    );

    await cache.save(product);
    expect(await cache.load('EAN-ABC'), isNull);
  });

  test('cache reads a legacy twelve-digit key through the canonical UPC', () async {
    final preferences = SharedPreferencesAsync();
    await preferences.setString(
      '${SharedPreferencesProductDataCache.keyPrefix}123456789012',
      jsonEncode(const Product(
        id: 'legacy_upc',
        name: 'Altes UPC-Produkt',
        unit: '1 Stück',
        group: 'vorrat',
        ean: '123456789012',
      ).toJson()),
    );

    final loaded = await SharedPreferencesProductDataCache().load(
      '0123456789012',
    );
    expect(loaded?.ean, '0123456789012');
    expect(loaded?.id, 'legacy_upc');
  });

  test('ein paralleler Read wartet auf einen Produkt-Cache-Write', () async {
    final cache = SharedPreferencesProductDataCache();
    final reader = SharedPreferencesProductDataCache();
    const product = Product(
      id: 'parallel_cache',
      name: 'Milch',
      unit: '1 l',
      group: 'milch',
      ean: '4001234567890',
    );

    final writing = cache.save(product);
    final reading = reader.load(product.ean!);

    await writing;
    expect((await reading)?.id, 'parallel_cache');
  });
}
