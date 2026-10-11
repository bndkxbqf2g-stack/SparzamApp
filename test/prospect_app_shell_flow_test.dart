import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/features/offers/offer_import.dart';
import 'package:sparzamapp/features/shell/app_shell.dart';
import 'package:sparzamapp/models/budget_plan.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/mobility_settings.dart';
import 'package:sparzamapp/models/offer.dart';
import 'package:sparzamapp/models/price_data_settings.dart';
import 'package:sparzamapp/models/price_point.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/purchase_record.dart';
import 'package:sparzamapp/models/recent_purchase.dart';
import 'package:sparzamapp/services/budget_store.dart';
import 'package:sparzamapp/services/diagnostic_log_service.dart';
import 'package:sparzamapp/services/mobility_settings_store.dart';
import 'package:sparzamapp/services/market_price_store.dart';
import 'package:sparzamapp/services/offer_store.dart';
import 'package:sparzamapp/services/price_data_settings_store.dart';
import 'package:sparzamapp/services/price_history_store.dart';
import 'package:sparzamapp/services/product_catalog_store.dart';
import 'package:sparzamapp/services/prospect_import_module.dart';
import 'package:sparzamapp/services/prospect_feed_service.dart';
import 'package:sparzamapp/services/purchase_store.dart';
import 'package:sparzamapp/services/recent_purchase_store.dart';
import 'package:sparzamapp/services/shopping_list_store.dart';

class _FakeProspectImportModule extends ProspectImportModule {
  _FakeProspectImportModule(this.result);

  final ProspectFeedLoadResult result;

  @override
  Future<ProspectFeedLoadResult> execute({String? startAddress}) async => result;
}

class _Stores {
  final budget = BudgetStore();
  final offers = OfferStore();
  final mobility = MobilitySettingsStore();
  final marketPrices = MarketPriceStore();
  final products = ProductCatalogStore();
  final priceData = PriceDataSettingsStore();
  final priceHistory = PriceHistoryStore();
  final recentPurchases = RecentPurchaseStore();
  final purchases = PurchaseStore();
  final shoppingList = ShoppingListStore();
}

Widget _app(
  _Stores stores,
  ProspectImportModule module, {
  Key? key,
  List<Offer> initialOffers = const <Offer>[],
  List<Product> initialCustomProducts = const <Product>[],
  List<ListItem> initialShoppingList = const <ListItem>[],
}) {
  return MaterialApp(
    home: AppShell(
      key: key,
      budgetStore: stores.budget,
      offerStore: stores.offers,
      mobilityStore: stores.mobility,
      marketPriceStore: stores.marketPrices,
      productCatalogStore: stores.products,
      priceDataSettingsStore: stores.priceData,
      priceHistoryStore: stores.priceHistory,
      recentPurchaseStore: stores.recentPurchases,
      purchaseStore: stores.purchases,
      shoppingListStore: stores.shoppingList,
      diagnosticLogService: DiagnosticLogService(),
      prospectImportModule: module,
      initialBudget: const BudgetPlan(),
      initialOffers: initialOffers,
      initialMobility: const MobilitySettings(
        startAddress: 'Zellingen',
        mode: MobilityMode.bike,
        enabledStoreNames: ['Netto'],
      ),
      initialMarketPrices: const <MarketPrice>[],
      initialCustomProducts: initialCustomProducts,
      initialPriceHistory: const <PricePoint>[],
      initialPriceDataSettings: const PriceDataSettings(),
      initialRecentPurchases: const <RecentPurchase>[],
      initialPurchaseHistory: const <PurchaseRecord>[],
      initialShoppingList: initialShoppingList,
      initialPreferredProductByGroup: const <String, String>{},
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  testWidgets(
    'Prospektartikel lässt sich im AppShell suchen, hinzufügen und nach Neustart sehen',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime.now();
      final record = OfferImportRecord(
        sourceId: 'netto-coffee-shell',
        productLabel: 'Jacobs Kaffee Crema 500 g',
        storeName: 'Netto',
        originalPrice: 7.99,
        offerPrice: 4.99,
        validFrom: now.subtract(const Duration(days: 1)),
        validUntil: now.add(const Duration(days: 2)),
        source: 'retailerWebsite',
        proofRef: 'https://example.test/netto/coffee',
        address: 'Am Strassacker 1, 97291 Thüngersheim',
      );
      final module = _FakeProspectImportModule(
        ProspectFeedLoadResult(
          records: [record],
          refreshedStores: const ['Netto'],
          generatedAt: now,
          prospects: const [
            ProspectIssue(
              storeName: 'Netto',
              title: 'Aktionsprospekt',
              pages: [],
              location: 'Thüngersheim',
              address: 'Am Strassacker 1, 97291 Thüngersheim',
            ),
          ],
        ),
      );
      final stores = _Stores();

      await tester.pumpWidget(_app(stores, module));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Prospekte'));
      await tester.pumpAndSettle();
      final search = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText ==
                'Prospekte und Artikel durchsuchen',
      );
      expect(search, findsOneWidget);
      await tester.enterText(search, 'Kaffee');
      await tester.pump();
      expect(find.text('Jacobs Kaffee Crema 500 g'), findsOneWidget);

      final addButton = find.byIcon(Icons.add_shopping_cart_outlined);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      final savedItems = await stores.shoppingList.load();
      final savedOffers = await stores.offers.load();
      expect(savedItems.single.product.name, 'Jacobs Kaffee Crema 500 g');
      expect(savedOffers.single.proofRef, record.proofRef);
      expect(savedOffers.single.address, record.address);

      await tester.pumpWidget(
        _app(
          stores,
          module,
          key: const ValueKey('simulated-restart'),
          initialOffers: savedOffers,
          initialCustomProducts: await stores.products.load(),
          initialShoppingList: savedItems,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Prospekte'));
      await tester.pumpAndSettle();
      final restartSearch = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText ==
                'Prospekte und Artikel durchsuchen',
      );
      expect(restartSearch, findsOneWidget);
      await tester.enterText(restartSearch, 'Kaffee');
      await tester.pump();
      expect(find.text('Jacobs Kaffee Crema 500 g'), findsOneWidget);
      await tester.tap(find.text('Liste'));
      await tester.pumpAndSettle();

      expect(find.text('Jacobs Kaffee Crema 500 g'), findsOneWidget);
      await tester.tap(find.text('Sparroute prüfen'));
      await tester.pumpAndSettle();
      expect(find.text('Einkaufsoptimierung'), findsOneWidget);
      expect(find.text('Netto'), findsWidgets);
    },
  );
}
