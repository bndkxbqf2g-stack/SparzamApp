import 'dart:async';

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
import 'package:sparzamapp/models/named_shopping_list.dart';
import 'package:sparzamapp/models/offer.dart';
import 'package:sparzamapp/models/price_data_settings.dart';
import 'package:sparzamapp/models/price_observation.dart';
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
import 'package:sparzamapp/features/offers/prospect_regular_price_persistence.dart';
import 'package:sparzamapp/services/prospect_feed_service.dart';
import 'package:sparzamapp/services/purchase_store.dart';
import 'package:sparzamapp/services/recent_purchase_store.dart';
import 'package:sparzamapp/services/shopping_list_store.dart';
import 'package:sparzamapp/services/price_observation_store.dart';

class _FakeProspectImportModule extends ProspectImportModule {
  _FakeProspectImportModule(this.result);

  final ProspectFeedLoadResult result;

  @override
  Future<ProspectFeedLoadResult> execute({String? startAddress}) async => result;
}

class _DelayedNamedListStore extends ShoppingListStore {
  _DelayedNamedListStore(this.result);

  final Future<List<NamedShoppingList>> result;

  @override
  Future<List<NamedShoppingList>> loadNamedLists() => result;
}

class _InMemoryShoppingListStore extends ShoppingListStore {
  List<ListItem> items = const <ListItem>[];
  List<NamedShoppingList> namedLists = const <NamedShoppingList>[];

  @override
  Future<List<ListItem>> load() async => List<ListItem>.of(items);

  @override
  Future<void> save(List<ListItem> next) async {
    items = List<ListItem>.of(next);
  }

  @override
  Future<List<NamedShoppingList>> loadNamedLists() async =>
      List<NamedShoppingList>.of(namedLists);

  @override
  Future<void> saveNamedLists(List<NamedShoppingList> next) async {
    namedLists = List<NamedShoppingList>.of(next);
  }

  @override
  Future<void> saveKnownItem(Product product) async {}
}

class _InMemoryOfferStore extends OfferStore {
  List<Offer> offers = const <Offer>[];

  @override
  Future<List<Offer>> load() async => List<Offer>.of(offers);

  @override
  Future<void> save(List<Offer> next) async {
    offers = List<Offer>.of(next);
  }

  @override
  Future<List<Offer>> upsert(Offer offer, List<Offer> current) async {
    final next = List<Offer>.of(current);
    final index = next.indexWhere((item) => item.id == offer.id);
    if (index < 0) {
      next.add(offer);
    } else {
      next[index] = offer;
    }
    offers = next;
    return List<Offer>.of(next);
  }
}

class _InMemoryProductCatalogStore extends ProductCatalogStore {
  List<Product> products = const <Product>[];

  @override
  Future<List<Product>> load() async => List<Product>.of(products);

  @override
  Future<List<Product>> upsert(Product product, List<Product> current) async {
    products = [
      product,
      ...current.where((item) => item.id != product.id),
    ];
    return List<Product>.of(products);
  }
}

class _Stores {
  _Stores({
    ShoppingListStore? shoppingListStore,
    OfferStore? offerStore,
    ProductCatalogStore? productCatalogStore,
  })  : shoppingList = shoppingListStore ?? ShoppingListStore(),
        offers = offerStore ?? OfferStore(),
        products = productCatalogStore ?? ProductCatalogStore();

  final budget = BudgetStore();
  final OfferStore offers;
  final mobility = MobilitySettingsStore();
  final marketPrices = MarketPriceStore();
  final ProductCatalogStore products;
  final priceData = PriceDataSettingsStore();
  final priceHistory = PriceHistoryStore();
  final recentPurchases = RecentPurchaseStore();
  final purchases = PurchaseStore();
  final ShoppingListStore shoppingList;
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
    'verzögerter alter Listenstand überschreibt keine neue Nutzereingabe',
    (tester) async {
      final gate = Completer<List<NamedShoppingList>>();
      final stores = _Stores(
        shoppingListStore: _DelayedNamedListStore(gate.future),
      );
      final module = _FakeProspectImportModule(
        ProspectFeedLoadResult(
          records: const <OfferImportRecord>[],
          refreshedStores: const <String>[],
          generatedAt: DateTime(2026, 10, 13),
          prospects: const <ProspectIssue>[],
        ),
      );

      await tester.pumpWidget(_app(stores, module));
      await tester.pump();
      final input = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Was möchtest du einkaufen?',
      );
      expect(input, findsOneWidget);
      await tester.enterText(input, 'Testartikel');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      gate.complete([
        NamedShoppingList(
          id: 'default',
          name: 'Einkauf',
          items: [
            ListItem(
              product: Product(
                id: 'stale-item',
                name: 'Alter Stand',
                unit: 'Stück',
                group: 'sonstiges',
              ),
            ),
          ],
        ),
      ]);
      await tester.pump(const Duration(milliseconds: 500));

      // The list now shows a price-coverage card before the item groups. Bring
      // the newly entered item into the viewport before asserting its visible
      // presence; the persisted assertion below remains the race guard.
      await tester.scrollUntilVisible(
        find.text('Testartikel'),
        260,
        scrollable: find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        ),
      );
      expect(find.text('Testartikel'), findsOneWidget);
      expect(find.text('Alter Stand'), findsNothing);
      final persisted = await stores.shoppingList.load();
      expect(persisted.single.product.name, 'Testartikel');
    },
  );

  testWidgets(
    'Prospektartikel lässt sich im AppShell suchen, hinzufügen und nach Neustart sehen',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime.now();
      final coffeeProduct = Product(
        id: 'test-jacobs-kaffee-crema-500-g',
        name: 'Jacobs Kaffee Crema 500 g',
        unit: '500 g',
        group: 'Kaffee & Snacks',
      );
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
      final stores = _Stores(
        shoppingListStore: _InMemoryShoppingListStore(),
        offerStore: _InMemoryOfferStore(),
        productCatalogStore: _InMemoryProductCatalogStore(),
      );

      await tester.pumpWidget(
        _app(
          stores,
          module,
          initialCustomProducts: [coffeeProduct],
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Automatic feed imports are rebuilt in memory and must not fill the
      // durable user-offer store. Only the later explicit add action persists.
      expect(await stores.offers.load(), isEmpty);

      await tester.tap(find.text('Prospekte'));
      // The shell refreshes and persists the feed in the background. Waiting
      // for animation quiescence would also wait on the feed status spinner;
      // one frame is enough for the already mounted Prospekte page.
      await tester.pump(const Duration(milliseconds: 500));
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

      // Switching tabs must keep the prospect search controller and scroll state.
      await tester.tap(find.text('Liste').last);
      await tester.pump();
      await tester.tap(find.text('Prospekte').last);
      await tester.pump();
      final retainedSearch = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText ==
                'Prospekte und Artikel durchsuchen',
      );
      expect(retainedSearch, findsOneWidget);
      expect(
        tester.widget<TextField>(retainedSearch).controller?.text,
        'Kaffee',
      );

      final addButton = find.byTooltip('Zur Einkaufsliste');
      expect(addButton, findsOneWidget);
      await tester.ensureVisible(addButton);
      await tester.tap(addButton);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byTooltip('Noch einmal zur Einkaufsliste'), findsOneWidget);
      await tester.runAsync(() async {
        for (var attempt = 0; attempt < 200; attempt++) {
          final items = await stores.shoppingList.load();
          final offers = await stores.offers.load();
          if (items.isNotEmpty && offers.isNotEmpty) return;
          await Future<void>.delayed(const Duration(milliseconds: 25));
        }
      });

      final savedItems = await stores.shoppingList.load();
      final savedOffers = await stores.offers.load();
      expect(savedItems.single.product.name, 'Jacobs Kaffee Crema 500 g');
      // Feed-derived offers are rebuilt from the prospect snapshot and are not
      // written into the durable user-offer store.
      expect(savedOffers, isEmpty);

      await tester.pumpWidget(
        _app(
          stores,
          module,
          key: const ValueKey('simulated-restart'),
          initialOffers: savedOffers,
          initialCustomProducts: [coffeeProduct],
          initialShoppingList: savedItems,
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Prospekte'));
      await tester.pump(const Duration(milliseconds: 500));
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
      final persistedAfterRestart = await stores.shoppingList.load();
      expect(persistedAfterRestart.single.product.name,
          'Jacobs Kaffee Crema 500 g');
      expect(find.text('Jacobs Kaffee Crema 500 g'), findsOneWidget);
      // Route opening is covered by dedicated route flow tests. Keeping this
      // test focused on feed import and restart persistence avoids coupling it
      // to the route screen's background distance work.
    },
  );

  test(
    'Prospektrefresh speichert nur den regulären Normalpreis lokal',
    () async {
      final now = DateTime(2026, 10, 15, 12);
      const coffee = Product(
        id: 'shell-coffee-500',
        name: 'Jacobs Kaffee Crema 500 g',
        unit: '500 g',
        group: 'Kaffee & Snacks',
      );
      final record = OfferImportRecord(
        sourceId: 'shell-regular-only',
        productLabel: coffee.name,
        storeName: 'Lidl',
        originalPrice: 7.99,
        offerPrice: 4.99,
        validFrom: DateTime(2026, 10, 12),
        validUntil: DateTime(2026, 10, 17),
        source: 'retailerWebsite',
        sourceAdapter: 'kaufda',
        branchId: 'lidl-branch-1',
        proofRef: 'https://example.test/lidl/coffee',
        capturedAt: now,
      );
      var raw = <String>[];
      final store = PriceObservationStore(
        readRaw: () async => List<String>.of(raw),
        writeRaw: (values) async => raw = List<String>.of(values),
      );

      final result = await persistCurrentProspectRegularPrices(
        store: store,
        records: [record],
        catalogProducts: const [coffee],
        observedAt: now,
        now: now,
        refreshedStores: const ['Lidl'],
      );

      expect(result.learned, hasLength(1));
      expect(result.learned.single.kind, PriceObservationKind.regular);
      expect(result.learned.single.price, 7.99);
      expect(result.learned.single.discounted, isFalse);
      expect(result.learned.single.locationId, 'lidl-branch-1');
      expect(result.stored, hasLength(1));
      expect(result.stored.single.price, 7.99);
      expect(result.stored.single.price, isNot(4.99));
      expect(await store.load(), hasLength(1));
    },
  );

  testWidgets(
    'Prospektseite übernimmt einen geprüften Seitenartikel in Liste und Angebot',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime.now();
      final issue = ProspectIssue(
        storeName: 'Netto',
        title: 'Aktionsprospekt',
        pages: const [
          ProspectPage(
            number: 1,
            imageUrl: 'https://example.test/netto/page-1.png',
            zoomUrl: 'https://example.test/netto/page-1-large.png',
          ),
        ],
        url: 'https://example.test/netto/flyer',
        branchId: '4371',
        location: 'Thüngersheim',
        address: 'Am Strassacker 1, 97291 Thüngersheim',
        sourceStatus: 'ok',
        validFrom: now.subtract(const Duration(days: 1)),
        validUntil: now.add(const Duration(days: 2)),
      );
      final stores = _Stores(
        shoppingListStore: _InMemoryShoppingListStore(),
        offerStore: _InMemoryOfferStore(),
        productCatalogStore: _InMemoryProductCatalogStore(),
      );
      final module = _FakeProspectImportModule(
        ProspectFeedLoadResult(
          records: const <OfferImportRecord>[],
          refreshedStores: const ['Netto'],
          generatedAt: now,
          prospects: [issue],
        ),
      );

      await tester.pumpWidget(_app(stores, module));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 250)),
      );
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Prospekte'));
      // The prospect feed persists in the background; a bounded pump keeps
      // this navigation assertion deterministic while the page is mounted.
      await tester.pump(const Duration(milliseconds: 500));
      final favoriteCard =
          find.byKey(const ValueKey('prospect-open-favorite-Netto#4371'));
      expect(favoriteCard, findsOneWidget);
      await tester.ensureVisible(favoriteCard);
      final favoriteRect = tester.getRect(favoriteCard);
      await tester.tapAt(favoriteRect.topLeft + const Offset(36, 36));
      await tester.pump(const Duration(milliseconds: 500));
      final pagesHeading = find.text('Prospektseiten (1)');
      await tester.scrollUntilVisible(
        pagesHeading,
        240,
        scrollable: find.byType(Scrollable).last,
      );
      expect(pagesHeading, findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('prospect-viewer-location')),
          matching: find.text('Thüngersheim'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Artikel von Seite hinzufügen'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Artikel von Prospektseite hinzufügen'), findsOneWidget);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Käsesticks 300 g');
      await tester.enterText(fields.at(1), '2,49');
      await tester.enterText(fields.at(2), '3,99');
      await tester.tap(
        find.widgetWithText(FilledButton, 'Artikel hinzufügen'),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.runAsync(() async {
        for (var attempt = 0; attempt < 200; attempt++) {
          final items = await stores.shoppingList.load();
          final offers = await stores.offers.load();
          if (items.isNotEmpty && offers.isNotEmpty) return;
          await Future<void>.delayed(const Duration(milliseconds: 25));
        }
      });

      final savedItems = await stores.shoppingList.load();
      final savedOffers = await stores.offers.load();
      expect(
        savedOffers,
        hasLength(1),
        reason:
            savedOffers.toString(),
      );
      expect(savedItems, hasLength(1));
      expect(savedOffers.single.source, 'leaflet');
      expect(savedItems.single.product.name, 'Käsesticks 300 g');
      expect(
        savedOffers.single.proofRef,
        'https://example.test/netto/page-1-large.png',
      );
      expect(savedOffers.single.locationId, '4371');
      expect(savedOffers.single.region, 'Thüngersheim');
      expect(savedOffers.single.address, issue.address);
    },
  );
}
