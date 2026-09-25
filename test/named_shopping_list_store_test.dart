import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/named_shopping_list.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/services/shopping_list_store.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  test('mehrere benannte Einkaufslisten bleiben getrennt gespeichert', () async {
    const product = Product(
      id: 'milk',
      name: 'Milch',
      unit: '1 l',
      group: 'milch',
    );
    final store = ShoppingListStore();
    await store.saveNamedLists([
      NamedShoppingList(
        id: 'weekly',
        name: 'Wocheneinkauf',
        items: [
          ListItem(
            product: product,
            quantity: 2,
            note: 'Laktosefrei',
            checked: true,
          ),
        ],
      ),
      const NamedShoppingList(
        id: 'party',
        name: 'Party',
        items: <ListItem>[],
      ),
    ]);

    final loaded = await store.loadNamedLists();
    expect(loaded.map((list) => list.name), ['Wocheneinkauf', 'Party']);
    expect(loaded.first.items.single.quantity, 2);
    expect(loaded.first.items.single.note, 'Laktosefrei');
    expect(loaded.first.items.single.checked, isTrue);
    expect(loaded.last.items, isEmpty);
  });

  test('Marktreihenfolge und Ansichtsmodus bleiben gespeichert', () async {
    final store = ShoppingListStore();

    await store.saveAisleOrder(['obst', 'milch', 'backwaren']);
    await store.saveTileView(true);

    expect(
      await store.loadAisleOrder(),
      ['obst', 'milch', 'backwaren'],
    );
    expect(await store.loadTileView(), isTrue);
  });
}
