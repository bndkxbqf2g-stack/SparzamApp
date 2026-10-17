import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/features/shopping_list/shopping_additions.dart';
import 'package:sparzamapp/features/shopping_list/shopping_list_updates.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/recent_purchase.dart';
import 'package:sparzamapp/models/replenishment_suggestion.dart';
import 'package:sparzamapp/services/recent_purchase_store.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  tearDown(() => SharedPreferencesAsyncPlatform.instance = null);

  const milk = Product(id: 'milk', name: 'Milch', unit: '1 l', group: 'milch');

  test('Nachkaufvorschlag übernimmt die gelernte Menge', () {
    final products = productsForReplenishment(
      ReplenishmentSuggestion(
        product: milk,
        purchaseCount: 3,
        averageQuantity: 2.4,
        intervalDays: 7,
        lastPurchasedAt: DateTime(2026, 9, 15),
        dueAt: DateTime(2026, 9, 22),
        daysUntilDue: 0,
        urgency: ReplenishmentUrgency.overdue,
      ),
    );

    expect(products, [milk, milk]);
  });

  test('letzter Kauf fügt mindestens ein Produkt hinzu', () {
    const purchase = RecentPurchase(
      id: 'milk',
      name: 'Milch',
      unit: '1 l',
      group: 'milch',
      purchaseCount: 1,
      totalQuantity: 0,
    );

    expect(productsForRecentPurchase(purchase), hasLength(1));
  });

  test('aktualisiert bekannte Listeneinträge ohne Nutzerzustand zu verlieren', () {
    const oldProduct = Product(
      id: 'milk',
      name: 'Milch',
      unit: '1 l',
      group: 'milch',
      packageAmount: 1,
      packageUnit: 'l',
    );
    const refreshedProduct = Product(
      id: 'milk',
      name: 'Bio Milch',
      unit: '1 l',
      group: 'milch',
      aliases: ['Kuhmilch'],
      brand: 'Hofmilch',
      packageAmount: 1,
      packageUnit: 'l',
      imageUrl: 'https://cdn.example.test/milk.jpg',
    );
    final item = ListItem(
      product: oldProduct,
      quantity: 3,
      note: 'kalt',
      checked: true,
    );

    final refreshed = refreshShoppingListProducts(
      items: [item],
      catalogProducts: [refreshedProduct],
    );

    expect(refreshed, hasLength(1));
    expect(refreshed.single.product, same(refreshedProduct));
    expect(refreshed.single.quantity, 3);
    expect(refreshed.single.note, 'kalt');
    expect(refreshed.single.checked, isTrue);
  });

  test('bewahrt Metadaten unbekannter Produkte im letzten Kauf', () async {
    const product = Product(
      id: 'custom-coffee-500',
      name: 'Röstkaffee',
      unit: '500 g',
      group: 'kaffee',
      aliases: ['Bohnenkaffee'],
      ean: '4000000000001',
      brand: 'Rösterei',
      packageAmount: 500,
      packageUnit: 'g',
      imageUrl: 'https://cdn.example.test/coffee.jpg',
    );
    final store = RecentPurchaseStore();

    final saved = await store.add(product, 2, const <RecentPurchase>[]);
    final loaded = await store.load();
    final restored = loaded.single.toProduct();

    expect(saved.single.totalQuantity, 2);
    expect(loaded.single.aliases, ['Bohnenkaffee']);
    expect(loaded.single.ean, '4000000000001');
    expect(loaded.single.brand, 'Rösterei');
    expect(loaded.single.packageAmount, 500);
    expect(loaded.single.packageUnit, 'g');
    expect(loaded.single.imageUrl, 'https://cdn.example.test/coffee.jpg');
    expect(restored.name, 'Röstkaffee');
    expect(restored.aliases, ['Bohnenkaffee']);
    expect(restored.brand, 'Rösterei');
    expect(restored.packageAmount, 500);
    expect(restored.packageUnit, 'g');
    expect(restored.imageUrl, 'https://cdn.example.test/coffee.jpg');
  });

  test('alte letzte-Kauf-JSON bleibt ohne neue Metadaten lesbar', () {
    final legacy = RecentPurchase.fromJson(
      '{"id":"legacy","name":"Tee","unit":"20 Beutel","group":"tee",'
      '"purchaseCount":1,"totalQuantity":1}',
    );

    expect(legacy.aliases, isEmpty);
    expect(legacy.brand, isNull);
    expect(legacy.toProduct().name, 'Tee');
  });
}
