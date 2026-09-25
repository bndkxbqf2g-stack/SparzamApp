import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/services/product_catalog_store.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  test('eigene Produkte werden vollständig gespeichert und geladen', () async {
    final store = ProductCatalogStore();
    const product = Product(
      id: 'custom_test',
      name: 'Testprodukt',
      brand: 'Meine Marke',
      unit: '500 g',
      group: 'vorrat',
      aliases: ['test', 'probe'],
      isFavorite: true,
      ean: '1234567890123',
    );

    await store.upsert(product, const <Product>[]);
    final loaded = await store.load();

    expect(loaded, hasLength(1));
    expect(loaded.single.name, 'Testprodukt');
    expect(loaded.single.brand, 'Meine Marke');
    expect(loaded.single.aliases, ['test', 'probe']);
    expect(loaded.single.isFavorite, isTrue);
    expect(loaded.single.ean, '1234567890123');
  });

  test('Produkt kann aktualisiert und entfernt werden', () async {
    final store = ProductCatalogStore();
    const original = Product(
      id: 'custom_test',
      name: 'Alt',
      unit: '1 Stk',
      group: 'custom',
    );
    const updated = Product(
      id: 'custom_test',
      name: 'Neu',
      unit: '2 Stk',
      group: 'custom',
    );

    final first = await store.upsert(original, const <Product>[]);
    final second = await store.upsert(updated, first);
    expect(second, hasLength(1));
    expect(second.single.name, 'Neu');

    final empty = await store.remove(updated.id, second);
    expect(empty, isEmpty);
  });
}
