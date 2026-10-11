import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/features/offers/offer_import.dart';
import 'package:sparzamapp/features/offers/prospect_offer_products.dart';
import 'package:sparzamapp/features/route/route_optimizer.dart';
import 'package:sparzamapp/features/shopping_list/shopping_list_updates.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/services/offer_store.dart';
import 'package:sparzamapp/services/shopping_list_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  test('Prospektartikel bleibt nach Neustart in der Liste und routebar', () async {
    final now = DateTime(2026, 10, 1);
    final entry = prospectOfferProducts(
      records: [
        OfferImportRecord(
          sourceId: 'netto-coffee-1',
          productLabel: 'Jacobs Kaffee Crema 500 g',
          storeName: 'Netto',
          originalPrice: 7.99,
          offerPrice: 4.99,
          validFrom: DateTime(2026, 9, 28),
          validUntil: DateTime(2026, 10, 3),
          source: 'retailerWebsite',
          proofRef: 'https://example.test/netto/coffee',
          address: 'Am Strassacker 1, 97291 Thüngersheim',
        ),
      ],
      catalogProducts: const <Product>[],
      now: now,
    ).single;

    final shoppingStore = ShoppingListStore();
    final offerStore = OfferStore();
    final added = addShoppingProduct(<ListItem>[], entry.product);
    await shoppingStore.save(added);
    await offerStore.save([entry.offer]);

    final restoredItems = await shoppingStore.load();
    final restoredOffers = await offerStore.load();
    final route = RouteOptimizer(
      restoredItems,
      restoredOffers,
      enabledStoreNames: const ['Netto'],
      maxStores: 1,
      now: now,
    ).bestSingleStorePlan();

    expect(restoredItems, hasLength(1));
    expect(restoredItems.single.product.id, entry.product.id);
    expect(restoredItems.single.product.name, 'Jacobs Kaffee Crema 500 g');
    expect(restoredOffers, hasLength(1));
    expect(restoredOffers.single.proofRef, entry.offer.proofRef);
    expect(restoredOffers.single.address, entry.offer.address);
    expect(route, isNotNull);
    expect(route!.unassigned, isEmpty);
    expect(route.stores.single.name, 'Netto');
    expect(route.basket, closeTo(4.99, 0.001));
  });
}
