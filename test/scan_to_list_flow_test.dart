import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/features/scanner/barcode_product_resolver.dart';
import 'package:sparzamapp/features/shopping_list/shopping_list_updates.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/services/shopping_list_store.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  tearDown(() => SharedPreferencesAsyncPlatform.instance = null);

  test('gescannter Artikel bleibt mit korrekter Menge in der Liste', () async {
    const product = Product(
      id: 'own-milk',
      name: 'Milch',
      group: 'Molkerei',
      unit: '1 l',
      aliases: ['Kuhmilch'],
      isFavorite: true,
      isStaple: true,
      ean: '1234567890123',
      brand: 'Hofmilch',
      packageAmount: 1,
      packageUnit: 'l',
      imageUrl: 'https://cdn.example.test/milk.jpg',
    );
    final scanned = productForBarcode(' 1234567890123 ', [product]);
    expect(scanned, same(product));

    final first = addShoppingProduct([], scanned!);
    first.single.note = 'Bio';
    first.single.checked = true;
    final second = addShoppingProduct(first, scanned);
    await ShoppingListStore().save(second);
    final restored = await ShoppingListStore().load();

    expect(first.single.quantity, 1);
    expect(restored, hasLength(1));
    expect(restored.single.product.id, product.id);
    expect(restored.single.quantity, 2);
    expect(restored.single.note, 'Bio');
    expect(restored.single.checked, isTrue);
    expect(restored.single.product.aliases, ['Kuhmilch']);
    expect(restored.single.product.isFavorite, isTrue);
    expect(restored.single.product.isStaple, isTrue);
    expect(restored.single.product.brand, 'Hofmilch');
    expect(restored.single.product.packageAmount, 1);
    expect(restored.single.product.packageUnit, 'l');
    expect(restored.single.product.imageUrl, 'https://cdn.example.test/milk.jpg');
    expect(productForBarcode('   ', [product]), isNull);
  });
}
